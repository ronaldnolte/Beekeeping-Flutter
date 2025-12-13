import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/apiary.dart';
import '../models/task_model.dart';
import '../models/hive.dart';
import '../services/storage_service.dart';
import '../utils/theme.dart';

class TasksScreen extends StatefulWidget {
  const TasksScreen({super.key});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen> {
  final StorageService _storage = StorageService();
  bool _loading = true;
  List<Map<String, dynamic>> _flatTasks = []; // {task, hiveName, hive}
  Apiary? _apiary;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Apiary) {
      _apiary = args;
    }
    _loadTasks();
  }

  Future<void> _loadTasks() async {
    setState(() => _loading = true);
    final hives = await _storage.getHives();
    
    List<Map<String, dynamic>> temp = [];
    for (var hive in hives) {
       if (_apiary != null && (hive.location != _apiary!.id && hive.location != _apiary!.name)) {
        continue;
      }
      for (var task in hive.tasks) {
        temp.add({
          'task': task,
          'hiveName': hive.name,
          'hive': hive,
        });
      }
    }

    // Sort: Incomplete first, then by creation date desc
    temp.sort((a, b) {
      final tA = a['task'] as TaskModel;
      final tB = b['task'] as TaskModel;
      if (tA.completed != tB.completed) {
        return tA.completed ? 1 : -1; // Incomplete first
      }
      return tB.createdAt.compareTo(tA.createdAt);
    });

    if (mounted) {
      setState(() {
        _flatTasks = temp;
        _loading = false;
      });
    }
  }

  void _toggleTask(Map<String, dynamic> item) async {
    final task = item['task'] as TaskModel;
    final hive = item['hive'] as Hive;
    
    // Toggle
    task.completed = !task.completed;
    
    // Update Hive
    // We need to find the task in the hive object and update it (passed by ref technically but safer to re-find)
    // Actually since we have memory refs, modifying `task` here modifies it in `hive.tasks`?
    // Let's ensure we save the hive.
    await _storage.updateHive(hive);
    _loadTasks();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_apiary != null ? "Tasks - ${_apiary!.name}" : "All Tasks"),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _flatTasks.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.checkSquare, size: 64, color: Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        "No tasks found",
                        style: TextStyle(color: Colors.grey[600], fontSize: 18),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _flatTasks.length,
                  itemBuilder: (context, index) {
                    final item = _flatTasks[index];
                    final task = item['task'] as TaskModel;
                    final hiveName = item['hiveName'] as String;

                    return Card(
                      child: ListTile(
                        leading: Checkbox(
                          value: task.completed,
                          onChanged: (_) => _toggleTask(item),
                        ),
                        title: Text(task.title, style: TextStyle(
                          decoration: task.completed ? TextDecoration.lineThrough : null,
                          fontWeight: FontWeight.bold
                        )),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(hiveName, style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.primary)),
                            if (task.description.isNotEmpty) Text(task.description),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(LucideIcons.chevronRight),
                          onPressed: () {
                             Navigator.pushNamed(
                                context, 
                                '/hive_details', 
                                arguments: item['hive']
                              ).then((_) => _loadTasks());
                          },
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
