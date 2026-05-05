import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/dashboard_stats.dart';
import '../models/task_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(ref.read(dioProvider));
});

class DashboardRepository {
  final Dio _dio;

  DashboardRepository(this._dio);

  Future<DashboardStats> getStats() async {
    final response = await _dio.get(ApiConstants.dashboardStats);
    return DashboardStats.fromJson(response.data);
  }

  Future<List<TaskModel>> getRecentTasks() async {
    final response = await _dio.get(ApiConstants.dashboardRecent);
    return (response.data as List)
        .map((json) => TaskModel.fromJson(json))
        .toList();
  }
}
