import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/providers/project_provider.dart';
import '../components/project_card.dart';

class ProjectsScreen extends ConsumerWidget {
  const ProjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final projectsAsync = ref.watch(projectsProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Projects', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
            ]),
          ).animate().fadeIn(duration: 400.ms),
          Expanded(
            child: projectsAsync.when(
              data: (projects) => projects.isEmpty
                  ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.folder_off_rounded, size: 64, color: AppColors.textMuted),
                      const SizedBox(height: 16),
                      Text('No projects yet', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                      const SizedBox(height: 8),
                      Text('Create your first project', style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                    ]))
                  : RefreshIndicator(
                      onRefresh: () => ref.read(projectsProvider.notifier).loadProjects(),
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: 1.1,
                        ),
                        itemCount: projects.length,
                        itemBuilder: (context, index) {
                          final project = projects[index];
                          return ProjectCard(
                            project: project,
                            onEdit: () => _showEditProjectDialog(context, ref, project),
                            onDelete: () => _confirmDeleteProject(context, ref, project),
                          ).animate().fadeIn(delay: Duration(milliseconds: index * 80));
                        },
                      ),
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error loading projects', style: TextStyle(color: AppColors.error))),
            ),
          ),
        ]),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateProjectDialog(context, ref),
        child: const Icon(Icons.add),
      ).animate().scale(delay: 500.ms, duration: 300.ms),
    );
  }

  void _showCreateProjectDialog(BuildContext context, WidgetRef ref) {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    int selectedColorIdx = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.darkBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('New Project', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Project Name', hintText: 'Enter project name')),
            const SizedBox(height: 16),
            TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', hintText: 'Optional')),
            const SizedBox(height: 16),
            Text('Color', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: List.generate(AppColors.projectColors.length, (i) => GestureDetector(
              onTap: () => setModalState(() => selectedColorIdx = i),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.projectColors[i],
                  shape: BoxShape.circle,
                  border: selectedColorIdx == i ? Border.all(color: Colors.white, width: 3) : null,
                ),
              ),
            ))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty) {
                    final colorHex = '#${AppColors.projectColors[selectedColorIdx].value.toRadixString(16).substring(2)}';
                    ref.read(projectsProvider.notifier).createProject({
                      'name': nameCtrl.text,
                      'description': descCtrl.text,
                      'color': colorHex,
                    }).then((_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Project created successfully'), behavior: SnackBarBehavior.floating),
                        );
                      }
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: Text('Create Project', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }
  void _showEditProjectDialog(BuildContext context, WidgetRef ref, dynamic project) {
    final nameCtrl = TextEditingController(text: project.name);
    final descCtrl = TextEditingController(text: project.description);
    int selectedColorIdx = AppColors.projectColors.indexWhere(
      (c) => c.value.toRadixString(16).substring(2).toLowerCase() == project.color.replaceFirst('#', '').toLowerCase()
    );
    if (selectedColorIdx == -1) selectedColorIdx = 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.darkBorder, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 20),
            Text('Edit Project', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
            const SizedBox(height: 20),
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Project Name', hintText: 'Enter project name')),
            const SizedBox(height: 16),
            TextField(controller: descCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Description', hintText: 'Optional')),
            const SizedBox(height: 16),
            Text('Color', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: List.generate(AppColors.projectColors.length, (i) => GestureDetector(
              onTap: () => setModalState(() => selectedColorIdx = i),
              child: Container(
                width: 36, height: 36,
                decoration: BoxDecoration(
                  color: AppColors.projectColors[i],
                  shape: BoxShape.circle,
                  border: selectedColorIdx == i ? Border.all(color: Colors.white, width: 3) : null,
                ),
              ),
            ))),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity, height: 52,
              child: ElevatedButton(
                onPressed: () {
                  if (nameCtrl.text.isNotEmpty) {
                    final colorHex = '#${AppColors.projectColors[selectedColorIdx].value.toRadixString(16).substring(2)}';
                    ref.read(projectsProvider.notifier).updateProject(project.id, {
                      'name': nameCtrl.text,
                      'description': descCtrl.text,
                      'color': colorHex,
                    }).then((_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Project updated successfully'), behavior: SnackBarBehavior.floating),
                        );
                      }
                    });
                    Navigator.pop(ctx);
                  }
                },
                child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  void _confirmDeleteProject(BuildContext context, WidgetRef ref, dynamic project) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkSurface,
        title: const Text('Delete Project', style: TextStyle(color: AppColors.textPrimary)),
        content: Text('Are you sure you want to delete "${project.name}"? This action cannot be undone.', style: const TextStyle(color: AppColors.textSecondary)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () {
              ref.read(projectsProvider.notifier).deleteProject(project.id).then((_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Project deleted'), behavior: SnackBarBehavior.floating),
                  );
                }
              });
              Navigator.pop(ctx);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

