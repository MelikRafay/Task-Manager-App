
# Task-Manager-App
Task Manager is a cross-platform productivity application built with Flutter and Dart. It helps users organize daily responsibilities, schedule reminders, track progress, and manage recurring tasks from one simple interface.

# Task Manager (Flutter + SQLite)

A task management app built with Flutter/Dart. Tasks are stored in a local SQLite database.
Runs in the browser (`flutter run -d web-server`) and on Android/iOS.

## Features

| Area | What it does |
|---|---|
| Views | **Today** (overdue + due today, with daily progress bar), **Completed**, **Repeated** |
| Task management | Add, edit, delete, mark completed (moves to *Completed*; un-tick to restore) |
| Categories | General, Work, Personal, Study, Health, Shopping – filter chips on every view |
| Repeat | Never / Daily / Selected days of the week. Completing a repeating task logs a completed copy and automatically resets the task (subtasks un-ticked) to its next occurrence |
| Progress tracking | Subtasks per task, progress bar and percentage |
| Export | CSV file, PDF report, or email (opens your mail app with the task list) |
| Customisation | Light / Dark / System theme, choice of notification sound |
| Notifications | Android/iOS: scheduled local notifications at the due time. Web: in-app reminder + browser notification while the tab is open |
| UI | Material 3, responsive (bottom bar on phones, side rail on wide screens) |

## 1. Setup (web)

Prerequisite: [Flutter SDK](https://docs.flutter.dev/get-started/install) (3.22 or newer) and Chrome.

```bash
# 1. unzip and enter the project
unzip task_manager.zip
cd task_manager

# 2. generate the platform folders (web + android) – keeps the existing lib/ and pubspec.yaml
flutter create . --project-name task_manager --platforms=web,android

# 3. install packages
flutter pub get

# 4. copy the SQLite WebAssembly files into web/ (needed for SQLite in the browser, run once)
dart run sqflite_common_ffi_web:setup

# 5. run
flutter run -d web-server --web-port 8080
```

Then open **http://localhost:8080** in Chrome.
(Hot reload: press `r` in the terminal. Data is kept in the browser's IndexedDB, so it survives restarts as long as you use the same port/origin – always use the same `--web-port`.)

### Troubleshooting
- **"Could not start the app" / sqlite3.wasm 404** – step 4 was skipped. Run `dart run sqflite_common_ffi_web:setup`, then restart `flutter run`.
- **`flutter pub get` version conflict** – run `flutter pub upgrade`, or loosen the version of the package named in the error in `pubspec.yaml`.
- **No sound in browser** – browsers block audio until you click somewhere on the page once.
- **Browser notifications** – allow them when Chrome asks (Settings → *Send test notification* to try).

## 2. Android / APK (for submission)

After step 2 above, make these edits once so scheduled notifications work:

**`android/app/src/main/AndroidManifest.xml`** – inside `<manifest>` (before `<application>`):
```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
<uses-permission android:name="android.permission.VIBRATE"/>
```
and inside `<application>`:
```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver"/>
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED"/>
    <action android:name="android.intent.action.MY_PACKAGE_REPLACED"/>
    <action android:name="android.intent.action.QUICKBOOT_POWERON"/>
    <action android:name="com.htc.intent.action.QUICKBOOT_POWERON"/>
  </intent-filter>
</receiver>
```
Also add `<queries><intent><action android:name="android.intent.action.SENDTO"/><data android:scheme="mailto"/></intent></queries>` inside `<manifest>` so the email option works.

**`android/app/build.gradle(.kts)`** – enable desugaring:
```kotlin
// build.gradle.kts
android { compileOptions { isCoreLibraryDesugaringEnabled = true } }
dependencies { coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4") }
```
```groovy
// build.gradle (Groovy)
android { compileOptions { coreLibraryDesugaringEnabled true } }
dependencies { coreLibraryDesugaring 'com.android.tools:desugar_jdk_libs:2.1.4' }
```
Build: `flutter build apk --release` → `build/app/outputs/flutter-apk/app-release.apk`

## 3. User manual

1. **Add a task** – tap **Add task**, enter a title (required), optional description, due date and time, category, repeat rule and subtasks, then **Save**.
2. **Complete a task** – tick the circle. It moves to **Completed**. Un-tick it there to restore it.
3. **Edit** – tap a task (or ⋮ → Edit). **Delete** – ⋮ → Delete (asks for confirmation).
4. **Repeat** – choose *Daily* or *Selected days* in the task form. Ticking the task off records it in *Completed* and the task jumps to its next date automatically. All repeating tasks are listed in **Repeated**.
5. **Progress** – add subtasks in the form; the task card shows a progress bar and percentage. The Today screen shows how many of today's tasks are done.
6. **Filter** – use the category chips at the top of each view.
7. **Export / email** – ⋮ menu (top right) → *Export CSV*, *Export PDF* or *Send by email*.
8. **Settings** – ⋮ → Settings: theme and notification sound, plus a test button.

## 4. Project structure

```
lib/
  main.dart                      app entry, theme, reminder snackbar
  models/task.dart               Task + SubTask models
  db/database_helper.dart        SQLite schema + CRUD (tasks, subtasks)
  state/app_state.dart           app state, queries, complete/repeat logic, settings
  services/notification_service.dart   local notifications (mobile) / browser alerts (web)
  services/export_service.dart         CSV, PDF, email
  screens/home_screen.dart             Today / Completed / Repeated
  screens/task_form_screen.dart        add + edit task, subtasks
  screens/settings_screen.dart         theme + sound
  widgets/task_tile.dart               task card
  utils/                         constants, repeat rules, CSV builder, web/mobile file helpers
test/widget_test.dart            unit tests (repeat logic, progress, model mapping, CSV)
```

### Database schema
```
tasks    (id PK, title, description, due_date, is_completed, completed_at,
          repeat_type, repeat_days, category, created_at)
subtasks (id PK, task_id FK -> tasks.id ON DELETE CASCADE, title, is_done)
```

## 5. Testing

```bash
flutter test          # unit tests
flutter analyze       # static analysis
```
Manual checklist: add / edit / delete / complete / restore a task · daily + weekly repeat resets after completing ·
subtask progress bar updates · category filters · CSV + PDF download · email opens · theme switch persists after reload ·
reminder appears when a task's due time arrives (set one 1–2 minutes ahead).

## 6. Submission checklist
- [ ] Push source to GitHub (`git init`, commit, push)
- [ ] Add `app-release.apk` (e.g. GitHub Release or `/release` folder)
- [ ] Record a short demo video of the features above and add the link/file

