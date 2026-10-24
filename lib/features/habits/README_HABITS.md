# Habits module (Muhammad Saim)

Screens: `screens/habits_screen.dart` (daywise Screen 3) and
`screens/add_habit_screen.dart` (daywise Screen 14).
Data: `habits_db_helper.dart` (tables `habits`, `habit_logs`, read of `profiles.full_name`).

## Notes for integration (Asim)

1. `pubspec.yaml` needs `supabase_flutter` and `main.dart` must call
   `DBHelper.init()` before `runApp` – the habits module uses
   `Supabase.instance.client`.
2. Optional columns. The "Build a habit" design has Reminder, Goal and Cue,
   which are not in the `habits` table. The app saves them when these columns
   exist and silently saves only title/frequency when they do not:

   ```sql
   alter table public.habits
     add column if not exists reminder_time text,
     add column if not exists goal_days int,
     add column if not exists cue text;
   ```
3. `HabitsScreen` accepts optional `onNotificationsTap` / `onProfileTap`
   callbacks for the header bell and avatar, so no cross-feature imports are
   needed: `HabitsScreen(onNotificationsTap: ..., onProfileTap: ...)`.

## Behaviour

- One `habit_logs` row per habit per day (`COMPLETED` / `SKIPPED`).
- Streak (`habits.streak_count`) = consecutive days (daily) or weeks, Monday
  start (weekly), with at least one COMPLETED check-in. A skipped or missed
  period breaks it; an unchecked current period does not.
- Tap the check icon to complete / undo. Tap a card for Skip, Clear, Edit, Delete.