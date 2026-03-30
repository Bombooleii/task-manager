import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/task_provider.dart';
import '../widgets/connectivity_banner.dart';
import '../widgets/task_tile.dart';
import 'auth_screen.dart';
import 'task_form_screen.dart';

class TaskListScreen extends StatelessWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Ажлын жагсаалт',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          Consumer<TaskProvider>(
            builder: (context, provider, _) {
              return IconButton(
                icon: const Icon(Icons.sync),
                onPressed: provider.isOnline ? () => provider.syncWithServer() : null,
                tooltip: 'Синк хийх',
              );
            },
          ),
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              return PopupMenuButton<String>(
                icon: const Icon(Icons.account_circle_outlined),
                onSelected: (value) async {
                  if (value == 'logout') {
                    await context.read<TaskProvider>().clearLocalData();
                    await auth.logout();
                    if (context.mounted) {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const AuthScreen()),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    enabled: false,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.userName ?? '',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        Text(
                          auth.userEmail ?? '',
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'logout',
                    child: Row(
                      children: [
                        Icon(Icons.logout, size: 20, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Гарах', style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const ConnectivityBanner(),
          Expanded(
            child: Consumer<TaskProvider>(
              builder: (context, provider, child) {
                if (provider.tasks.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 80, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text(
                          'Ажил байхгүй байна',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Шинэ ажил нэмэхийн тулд + товч дарна уу',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade400,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final pending = provider.pendingTasks;
                final completed = provider.completedTasks;

                return RefreshIndicator(
                  onRefresh: () => provider.syncWithServer(),
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 80),
                    children: [
                      if (pending.isNotEmpty) ...[
                        _buildSectionHeader('Хийх ажлууд', pending.length, Colors.blue),
                        ...pending.map((task) => TaskTile(
                              task: task,
                              onToggle: () => provider.toggleTaskCompletion(task),
                              onEdit: () => _navigateToForm(context, task: task),
                              onDelete: () => provider.deleteTask(task),
                            )),
                      ],
                      if (completed.isNotEmpty) ...[
                        _buildSectionHeader('Дууссан', completed.length, Colors.green),
                        ...completed.map((task) => TaskTile(
                              task: task,
                              onToggle: () => provider.toggleTaskCompletion(task),
                              onEdit: () => _navigateToForm(context, task: task),
                              onDelete: () => provider.deleteTask(task),
                            )),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Шинэ ажил'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: color.withAlpha(25),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToForm(BuildContext context, {task}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TaskFormScreen(task: task),
      ),
    );
  }
}
