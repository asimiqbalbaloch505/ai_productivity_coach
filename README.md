# Sajid Ali — Task Management Module

This module is written for the existing Flutter + Supabase project described in the team instruction manual. It only contains files for `lib/features/tasks/` and does not replace or modify `lib/main.dart`, `lib/db_helper.dart`, or another member's feature.

## Included files

- `lib/features/tasks/task_models.dart`
- `lib/features/tasks/tasks_db_helper.dart`
- `lib/features/tasks/screens/tasks_list_screen.dart`
- `lib/features/tasks/screens/add_task_screen.dart`
- `lib/features/tasks/screens/task_detail_screen.dart`

## Before running

1. Copy the included `lib/features/tasks/` folder into the existing project, merging the folder if it already exists. Do not replace the project-wide `main.dart` or `db_helper.dart`.
2. Ensure `pubspec.yaml` already includes `supabase_flutter` and run `flutter pub get`.
3. The team lead must initialize Supabase in `main.dart` before opening these screens. The current signed-in Supabase user must be available.
4. The code uses the existing `public.tasks` columns from the manual: `id`, `user_id`, `title`, `description`, `priority`, `deadline`, `is_completed`, `is_recurring`, and `created_at`.
5. The database manual shows `priority` values `LOW`, `MEDIUM`, `HIGH`. The code writes those uppercase values.
6. For secure access, ensure Supabase Row Level Security policies restrict task reads/writes to `auth.uid() = user_id`. The app additionally filters queries by the current user's ID.

## Open the screens while testing

For temporary local testing only, the team manual allows temporarily pointing `lib/main.dart` to `TasksListScreen`. Do not commit a change to `main.dart`, because it belongs to the team lead. Restore it before creating your pull request.

Example temporary body widget (adapt only locally):

```dart
import 'package:flutter/material.dart';
import 'features/tasks/screens/tasks_list_screen.dart';

// Use TasksListScreen() as the home widget only for local feature testing.
```

## Git workflow from the team manual

```bash
git checkout -b feature/tasks
git add lib/features/tasks/
git commit -m "Complete assigned task management module"
git push origin feature/tasks
```

Then open a Pull Request on GitHub. Only stage `lib/features/tasks/` for this feature branch.

## Scope notes

- Search, Today/Upcoming/Completed filters, create, edit, delete, priority, deadline, recurring flag, and mark complete are implemented.
- The provided database schema does not include a separate reminder time or repeat schedule field, so this module does not write unsupported columns. Deadline reminders need the notification module/schema integration later.
- The Flutter SDK is not available in this generation environment, so `flutter analyze` could not be run here. Run it in your local Flutter project before pushing.
