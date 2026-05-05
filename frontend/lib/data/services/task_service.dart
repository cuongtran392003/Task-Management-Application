import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/task_model.dart';

final taskRepositoryProvider = Provider<TaskRepository>((ref) {
  return TaskRepository(ref.read(dioProvider));
});

class TaskRepository {
  final Dio _dio;

  TaskRepository(this._dio);

  Future<Map<String, dynamic>> getTasks({
    String? status,
    String? priority,
    String? project,
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (status != null) queryParams['status'] = status;
    if (priority != null) queryParams['priority'] = priority;
    if (project != null) queryParams['project'] = project;
    if (search != null && search.isNotEmpty) queryParams['search'] = search;

    final response = await _dio.get(
      ApiConstants.tasks,
      queryParameters: queryParams,
    );

    return {
      'tasks': (response.data['tasks'] as List)
          .map((json) => TaskModel.fromJson(json))
          .toList(),
      'total': response.data['total'],
      'page': response.data['page'],
      'totalPages': response.data['totalPages'],
    };
  }

  Future<TaskModel> getTask(String id) async {
    final response = await _dio.get('${ApiConstants.tasks}/$id');
    return TaskModel.fromJson(response.data);
  }

  Future<TaskModel> createTask(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.tasks, data: data);
    return TaskModel.fromJson(response.data);
  }

  Future<TaskModel> updateTask(String id, Map<String, dynamic> data) async {
    final response =
        await _dio.patch('${ApiConstants.tasks}/$id', data: data);
    return TaskModel.fromJson(response.data);
  }

  Future<TaskModel> updateTaskStatus(String id, String status) async {
    final response = await _dio.patch(
      '${ApiConstants.tasks}/$id/status',
      data: {'status': status},
    );
    return TaskModel.fromJson(response.data);
  }

  Future<void> deleteTask(String id) async {
    await _dio.delete('${ApiConstants.tasks}/$id');
  }
}
