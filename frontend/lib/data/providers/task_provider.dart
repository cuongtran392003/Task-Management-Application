import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/task_model.dart';
import '../services/task_service.dart';

class TasksNotifier extends AsyncNotifier<List<TaskModel>> {
  @override
  Future<List<TaskModel>> build() async {
    final result = await ref.read(taskRepositoryProvider).getTasks();
    return result['tasks'] as List<TaskModel>;
  }

  Future<void> loadTasks({
    String? status,
    String? priority,
    String? project,
    String? search,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final result = await ref
          .read(taskRepositoryProvider)
          .getTasks(
            status: status,
            priority: priority,
            project: project,
            search: search,
          );
      return result['tasks'] as List<TaskModel>;
    });
  }

  Future<void> createTask(Map<String, dynamic> data) async {
    final newTask = await ref.read(taskRepositoryProvider).createTask(data);
    if (state.hasValue) {
      final currentTasks = state.value!;
      state = AsyncValue.data([newTask, ...currentTasks]);
    }
  }

  Future<void> updateTask(String id, Map<String, dynamic> data) async {
    try {
      final updateTask = await ref
          .read(taskRepositoryProvider)
          .updateTask(id, data);
      if (state.hasValue) {
        final currentTasks = state.value!;
        final newList = currentTasks.map((task) {
          if (task.id == id) {
            return updateTask;
          } else {
            return task;
          }
        }).toList();
        debugPrint('updated tasks: $newList');
        state = AsyncValue.data(newList);
      }
    } catch (e, stack) {
      debugPrint(e.toString());
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> updateTaskStatus(String id, String status) async {
    final updateTaskStatus = await ref
        .read(taskRepositoryProvider)
        .updateTaskStatus(id, status);
    if (state.hasValue) {
      final currentTasks = state.value!;
      final newList = currentTasks.map((task) {
        if (task.id == id) {
          return updateTaskStatus;
        } else {
          return task;
        }
      }).toList();
      state = AsyncValue.data(newList);
    }
  }

  Future<void> deleteTask(String id) async {
    await ref.read(taskRepositoryProvider).deleteTask(id);
    if (state.hasValue) {
      state = AsyncValue.data(
        state.value!.where((task) => task.id != id).toList(),
      );
    }
  }
}

final tasksProvider = AsyncNotifierProvider<TasksNotifier, List<TaskModel>>(
  TasksNotifier.new,
);
