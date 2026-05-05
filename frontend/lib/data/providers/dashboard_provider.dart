import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/dashboard_stats.dart';
import '../models/task_model.dart';
import '../services/dashboard_service.dart';

final dashboardStatsProvider = FutureProvider<DashboardStats>((ref) async {
  final repo = ref.read(dashboardRepositoryProvider);
  return repo.getStats();
});

final recentTasksProvider = FutureProvider<List<TaskModel>>((ref) async {
  final repo = ref.read(dashboardRepositoryProvider);
  return repo.getRecentTasks();
});
