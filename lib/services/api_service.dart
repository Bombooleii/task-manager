import 'package:dio/dio.dart';
import '../models/task_model.dart';

class ApiService {
  // TODO: Replace with your deployed Render URL
  // Example: 'https://task-manager-server-xxxx.onrender.com'
  static const String baseUrl = 'http://localhost:3000';

  final Dio _dio;

  ApiService()
      : _dio = Dio(BaseOptions(
          baseUrl: baseUrl,
          connectTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {'Content-Type': 'application/json'},
        ));

  Future<List<Task>> fetchTasks() async {
    final response = await _dio.get('/tasks');
    final List<dynamic> data = response.data;
    return data.map((json) => Task.fromJson(json as Map<String, dynamic>)).toList();
  }

  Future<Task> createTask(Task task) async {
    final response = await _dio.post('/tasks', data: task.toJson());
    return Task.fromJson(response.data as Map<String, dynamic>, localId: task.id);
  }

  Future<Task> updateTask(Task task) async {
    final response = await _dio.put('/tasks/${task.serverId}', data: task.toJson());
    return Task.fromJson(response.data as Map<String, dynamic>, localId: task.id);
  }

  Future<void> deleteTask(String serverId) async {
    await _dio.delete('/tasks/$serverId');
  }
}
