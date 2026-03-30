# Task Manager App

Offline-first Task Manager Flutter application with server synchronization.

## Features

- **Task CRUD**: Create, read, update, delete tasks with title, description, due date, and completion status
- **Offline Mode**: Full functionality without internet — data stored in local SQLite database
- **Auto Sync**: Automatically syncs pending changes when internet connection is restored
- **Network Awareness**: Displays online/offline status and syncing progress in the UI
- **Pull to Refresh**: Manual sync by pulling down the task list

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Framework | Flutter |
| State Management | Provider |
| Local Database | sqflite (SQLite) |
| HTTP Client | Dio |
| Network Monitoring | connectivity_plus |
| Mock Server | json-server |

## Architecture

```
lib/
├── main.dart                          # App entry point
├── models/
│   └── task_model.dart                # Task data model
├── services/
│   ├── database_service.dart          # SQLite CRUD operations
│   ├── api_service.dart               # REST API client
│   ├── sync_service.dart              # Sync logic (push/pull)
│   └── connectivity_service.dart      # Network state monitoring
├── providers/
│   └── task_provider.dart             # State management
├── screens/
│   ├── task_list_screen.dart          # Main task list
│   └── task_form_screen.dart          # Add/Edit task form
└── widgets/
    ├── connectivity_banner.dart       # Online/Offline/Syncing banner
    └── task_tile.dart                 # Task list item
```

## Sync Strategy

Each task has a `syncStatus` field:
- `synced` — Up to date with the server
- `pending_create` — Created offline, waiting to be pushed
- `pending_update` — Modified offline, waiting to sync
- `pending_delete` — Deleted offline, waiting to be removed from server

When connectivity is restored:
1. All pending local changes are pushed to the server
2. Server data is fetched and merged (preserving pending local changes)

## Getting Started

### Prerequisites

- Flutter SDK (>=3.11.0)
- Node.js (for json-server)

### 1. Install json-server (mock backend)

```bash
npm install -g json-server
```

### 2. Start the mock server

```bash
cd server
json-server --watch db.json --port 3000
```

This provides the following endpoints:
- `GET    /tasks`      — Fetch all tasks
- `POST   /tasks`      — Create a task
- `PUT    /tasks/:id`  — Update a task
- `DELETE /tasks/:id`  — Delete a task

### 3. Configure API URL (if needed)

If running on a physical device, update the `baseUrl` in `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://<YOUR_IP>:3000';
```

For Android emulator, use `http://10.0.2.2:3000`.

### 4. Run the Flutter app

```bash
flutter pub get
flutter run
```

## Usage

1. **Add a task**: Tap the "Шинэ ажил" button
2. **Complete a task**: Tap the circle icon on the left
3. **Edit a task**: Tap the edit icon on the right
4. **Delete a task**: Swipe left on a task
5. **Manual sync**: Pull down to refresh or tap the sync icon
6. **Offline mode**: The app works fully offline — changes sync automatically when back online
