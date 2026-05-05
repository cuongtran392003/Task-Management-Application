import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/project_model.dart';
import '../services/project_service.dart';

class ProjectsNotifier extends AsyncNotifier<List<ProjectModel>> {
  @override
  Future<List<ProjectModel>> build() async {
    return ref.read(projectRepositoryProvider).getProjects();
  }

  Future<void> loadProjects() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(projectRepositoryProvider).getProjects(),
    );
  }

  Future<void> createProject(Map<String, dynamic> data) async {
    final newProject = await ref
        .read(projectRepositoryProvider)
        .createProject(data);
    if (state.hasValue) {
      final projects = state.value!;
      state = AsyncData([newProject, ...projects]);
    }
  }

  Future<void> updateProject(String id, Map<String, dynamic> data) async {
    final updateProject = await ref.read(projectRepositoryProvider).updateProject(id, data);
    if(state.hasValue){
      final projects = state.value!;
      final updatedProjects = projects.map((project) {
        if (project.id == id) {
          return updateProject;
        }
        return project;
      }).toList();
      state = AsyncData(updatedProjects);
    }
  }

  Future<void> deleteProject(String id) async {
    await ref.read(projectRepositoryProvider).deleteProject(id);
    if(state.hasValue){
      state = AsyncValue.data(
        state.value!.where((project) => project.id != id).toList(),
      );
    }
  }
}

final projectsProvider =
    AsyncNotifierProvider<ProjectsNotifier, List<ProjectModel>>(
      ProjectsNotifier.new,
    );
