import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../models/task_model.dart';
import '../services/api_service.dart';
import '../services/database_service.dart';
import '../services/connectivity_service.dart';
import '../services/sync_service.dart';

class TaskProvider extends ChangeNotifier {
  final DatabaseService _databaseService = DatabaseService();
  final ApiService _apiService = ApiService();
  final ConnectivityService _connectivityService = ConnectivityService();
  late final SyncService _syncService;
  final Uuid _uuid = const Uuid();

  List<Task> _tasks = [];
  bool _isOnline = true;
  bool _isSyncing = false;
  StreamSubscription<bool>? _connectivitySubscription;

  List<Task> get tasks => _tasks;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;

  List<Task> get pendingTasks => _tasks.where((t) => !t.isCompleted).toList();
  List<Task> get completedTasks => _tasks.where((t) => t.isCompleted).toList();

  TaskProvider() {
    _syncService = SyncService(_apiService, _databaseService);
    _init();
  }

  void setToken(String? token) {
    _apiService.setToken(token);
    if (token != null) {
      syncWithServer();
    }
  }

  Future<void> _init() async {
    _isOnline = await _connectivityService.isOnline;
    await loadTasks();

    _connectivitySubscription = _connectivityService.onConnectivityChanged.listen(
      (isOnline) async {
        final wasOffline = !_isOnline;
        _isOnline = isOnline;
        notifyListeners();

        if (isOnline && wasOffline) {
          await syncWithServer();
        }
      },
    );
  }

  Future<void> loadTasks() async {
    _tasks = await _databaseService.getTasks();
    notifyListeners();
  }

  Future<void> addTask({
    required String title,
    String description = '',
    DateTime? dueDate,
  }) async {
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      dueDate: dueDate,
      syncStatus: 'pending_create',
    );

    await _databaseService.insertTask(task);
    await loadTasks();

    if (_isOnline) {
      await _syncSingle(task);
    }
  }

  Future<void> updateTask(Task task, {
    String? title,
    String? description,
    DateTime? dueDate,
    bool? isCompleted,
  }) async {
    final updatedTask = task.copyWith(
      title: title,
      description: description,
      dueDate: dueDate,
      isCompleted: isCompleted,
      syncStatus: task.syncStatus == 'pending_create' ? 'pending_create' : 'pending_update',
    );

    await _databaseService.updateTask(updatedTask);
    await loadTasks();

    if (_isOnline) {
      await _syncSingle(updatedTask);
    }
  }

  Future<void> toggleTaskCompletion(Task task) async {
    await updateTask(task, isCompleted: !task.isCompleted);
  }

  Future<void> deleteTask(Task task) async {
    if (task.syncStatus == 'pending_create') {
      await _databaseService.deleteTask(task.id);
    } else {
      final deletedTask = task.copyWith(syncStatus: 'pending_delete');
      await _databaseService.updateTask(deletedTask);

      if (_isOnline && task.serverId != null) {
        try {
          await _apiService.deleteTask(task.serverId!);
          await _databaseService.deleteTask(task.id);
        } catch (_) {
          // Will retry on next sync
        }
      }
    }

    await loadTasks();
  }

  Future<void> syncWithServer() async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      await _syncService.syncPendingChanges();
      await _syncService.fetchAndMergeFromServer();
      await loadTasks();
    } catch (_) {
      // Sync failed, will retry on next connectivity change
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _syncSingle(Task task) async {
    try {
      switch (task.syncStatus) {
        case 'pending_create':
          final serverTask = await _apiService.createTask(task);
          await _databaseService.updateTask(
            serverTask.copyWith(syncStatus: 'synced'),
          );
          break;
        case 'pending_update':
          if (task.serverId != null) {
            final serverTask = await _apiService.updateTask(task);
            await _databaseService.updateTask(
              serverTask.copyWith(syncStatus: 'synced'),
            );
          }
          break;
        default:
          break;
      }
      await loadTasks();
    } catch (_) {
      // Will sync later when online
    }
  }

  Future<void> clearLocalData() async {
    final db = await _databaseService.database;
    await db.delete('tasks');
    _tasks = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
