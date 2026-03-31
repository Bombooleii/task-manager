import 'api_service.dart';
import 'database_service.dart';

class SyncService {
  final ApiService _apiService;
  final DatabaseService _databaseService;

  SyncService(this._apiService, this._databaseService);

  /// Sync all pending local changes to the server
  Future<SyncResult> syncPendingChanges() async {
    final pendingTasks = await _databaseService.getPendingTasks();
    int synced = 0;
    int failed = 0;

    for (final task in pendingTasks) {
      try {
        switch (task.syncStatus) {
          case 'pending_create':
            final serverTask = await _apiService.createTask(task);
            await _databaseService.updateTask(serverTask.copyWith(syncStatus: 'synced'));
            synced++;
            break;

          case 'pending_update':
            if (task.serverId != null) {
              final serverTask = await _apiService.updateTask(task);
              await _databaseService.updateTask(serverTask.copyWith(syncStatus: 'synced'));
              synced++;
            }
            break;

          case 'pending_delete':
            if (task.serverId != null) {
              await _apiService.deleteTask(task.serverId!);
            }
            await _databaseService.deleteTask(task.id);
            synced++;
            break;
        }
      } catch (e) {
        failed++;
      }
    }

    return SyncResult(synced: synced, failed: failed);
  }

  /// Fetch all tasks from the server and merge with local data
  Future<void> fetchAndMergeFromServer() async {
    try {
      final serverTasks = await _apiService.fetchTasks();
      final pendingTasks = await _databaseService.getPendingTasks();
      final pendingIds = pendingTasks.map((t) => t.serverId).toSet();

      // Only insert server tasks that don't have pending local changes
      final tasksToInsert = serverTasks.where((t) => !pendingIds.contains(t.serverId)).toList();
      await _databaseService.deleteAllAndInsert(tasksToInsert);
    } catch (_) {
      // If fetch fails, keep local data as-is
    }
  }
}

class SyncResult {
  final int synced;
  final int failed;

  SyncResult({required this.synced, required this.failed});

  bool get hasFailures => failed > 0;
}
