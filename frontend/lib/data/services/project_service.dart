import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/project_model.dart';

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return ProjectRepository(ref.read(dioProvider));
});

class ProjectRepository {
  final Dio _dio;

  ProjectRepository(this._dio);

  Future<List<ProjectModel>> getProjects() async {
    final response = await _dio.get(ApiConstants.projects);
    return (response.data as List)
        .map((json) => ProjectModel.fromJson(json))
        .toList();
  }

  Future<ProjectModel> getProject(String id) async {
    final response = await _dio.get('${ApiConstants.projects}/$id');
    return ProjectModel.fromJson(response.data);
  }

  Future<ProjectModel> createProject(Map<String, dynamic> data) async {
    final response = await _dio.post(ApiConstants.projects, data: data);
    return ProjectModel.fromJson(response.data);
  }

  Future<ProjectModel> updateProject(
      String id, Map<String, dynamic> data) async {
    final response =
        await _dio.patch('${ApiConstants.projects}/$id', data: data);
    return ProjectModel.fromJson(response.data);
  }

  Future<void> deleteProject(String id) async {
    await _dio.delete('${ApiConstants.projects}/$id');
  }

  Future<ProjectModel> addMember(String projectId, String userId) async {
    final response = await _dio.post(
      '${ApiConstants.projects}/$projectId/members',
      data: {'userId': userId},
    );
    return ProjectModel.fromJson(response.data);
  }
}
