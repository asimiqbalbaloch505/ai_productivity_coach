# Daywise Notifications — Screen 10 and Screen 15

These files implement the two provided Flowstep design screens, inside the team's permitted `lib/features/notifications/` directory.

## Preview (does not need Supabase)

```bash
flutter pub add supabase_flutter
flutter run -d chrome -t lib/features/notifications/notifications_preview.dart
```

Preview mode supplies four sample notifications and stores four preference switches in memory. It does not edit production data.

## Live integration

Initialize Supabase in the application's main entrypoint, authenticate the user, then open `const NotificationScreen()` from the main navigation. Its helper uses the authenticated user's ID and these existing tables:

- `notifications`: id, user_id, title, message, type, is_read, created_at
- `notification_settings`: user_id, task_reminders, habit_reminders, daily_planning_notif, weekly_summary_notif

Make sure the team lead configures row-level security for user-specific reads and writes. No service-role key belongs in client code.

## Known integration limitations

- Master notification and overdue task toggles are UI-only until the lead approves schema additions; their state does not persist after leaving the screen.
- Reminder times are presentation labels only, matching the supplied screenshot. Scheduling/notifications delivery and OS settings deep links are not implemented.
- The bottom tab bar visually matches the design. Global navigation should be hooked up during integration by the team lead.
- `Done` returns to the preceding route when one exists.
