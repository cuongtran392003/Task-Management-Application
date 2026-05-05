import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/providers/task_provider.dart';
import '../../../data/providers/project_provider.dart';
import '../../../data/models/task_model.dart';
import '../components/task_card.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});
  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _filterByStatus(int index) {
    String? status;
    switch (index) {
      case 1:
        status = 'todo';
        break;
      case 2:
        status = 'in_progress';
        break;
      case 3:
        status = 'done';
        break;
    }
    ref.read(tasksProvider.notifier).loadTasks(status: status);
  }

  @override
  Widget build(BuildContext context) {
    final tasksAsync = ref.watch(tasksProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tasks',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                  const SizedBox(height: 16),
                  // Search
                  TextField(
                    controller: _searchCtrl,
                    onSubmitted: (v) =>
                        ref.read(tasksProvider.notifier).loadTasks(search: v),
                    decoration: InputDecoration(
                      hintText: 'Search tasks...',
                      prefixIcon: const Icon(
                        Icons.search,
                        color: AppColors.textMuted,
                      ),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchCtrl.clear();
                                ref.read(tasksProvider.notifier).loadTasks();
                              },
                            )
                          : null,
                    ),
                  ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
                  const SizedBox(height: 16),
                  // Tabs
                  TabBar(
                    controller: _tabController,
                    onTap: _filterByStatus,
                    isScrollable: true,
                    labelColor: AppColors.primary,
                    unselectedLabelColor: AppColors.textMuted,
                    indicatorColor: AppColors.primary,
                    labelStyle: TextStyle(fontWeight: FontWeight.w600),
                    tabAlignment: TabAlignment.start,
                    tabs: const [
                      Tab(text: 'All'),
                      Tab(text: 'To Do'),
                      Tab(text: 'In Progress'),
                      Tab(text: 'Done'),
                    ],
                  ).animate().fadeIn(delay: 200.ms, duration: 400.ms),
                ],
              ),
            ),
            Expanded(
              child: tasksAsync.when(
                data: (tasks) => tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.task_outlined,
                              size: 64,
                              color: AppColors.textMuted,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No tasks found',
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () =>
                            ref.read(tasksProvider.notifier).loadTasks(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(20),
                          itemCount: tasks.length,
                          itemBuilder: (context, index) =>
                              TaskCard(
                                task: tasks[index],
                                onStatusChanged: (s) {
                                  ref
                                      .read(tasksProvider.notifier)
                                      .updateTaskStatus(tasks[index].id, s)
                                      .then((_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Task status updated'), behavior: SnackBarBehavior.floating),
                                          );
                                        }
                                      });
                                },
                                onDelete: () {
                                  ref
                                      .read(tasksProvider.notifier)
                                      .deleteTask(tasks[index].id)
                                      .then((_) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Task deleted'), behavior: SnackBarBehavior.floating),
                                          );
                                        }
                                      });
                                },
                                onEdit: () {
                                  _showEditTaskDialog(
                                    context,
                                    ref,
                                    tasks[index],
                                  );
                                },
                              ).animate().fadeIn(
                                delay: Duration(milliseconds: index * 60),
                              ),
                        ),
                      ),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Error loading tasks',
                        style: TextStyle(color: AppColors.error),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () =>
                            ref.read(tasksProvider.notifier).loadTasks(),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateTaskDialog(context, ref),
        child: const Icon(Icons.add),
      ).animate().scale(delay: 500.ms, duration: 300.ms),
    );
  }

  void _showCreateTaskDialog(BuildContext context, WidgetRef ref) {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    String? selectedProject;
    String selectedPriority = 'medium';
    DateTime? selectedDate;

    final projects = ref.read(projectsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.darkBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'New Task',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Task title',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional description',
                ),
              ),
              const SizedBox(height: 16),
              // Project dropdown
              projects.when(
                data: (projs) => DropdownButtonFormField<String>(
                  value: selectedProject,
                  decoration: const InputDecoration(labelText: 'Project'),
                  dropdownColor: AppColors.darkCard,
                  items: projs
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedProject = v),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('No projects'),
              ),
              const SizedBox(height: 16),
              // Priority
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                dropdownColor: AppColors.darkCard,
                items: ['low', 'medium', 'high', 'urgent']
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p[0].toUpperCase() + p.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setModalState(() => selectedPriority = v ?? 'medium'),
              ),
              const SizedBox(height: 16),
              // Due Date
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        selectedDate != null
                            ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                            : 'Select Due Date',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isNotEmpty && selectedProject != null) {
                      ref.read(tasksProvider.notifier).createTask({
                        'title': titleCtrl.text,
                        'description': descCtrl.text,
                        'project': selectedProject,
                        'priority': selectedPriority,
                        if (selectedDate != null) 'dueDate': selectedDate!.toIso8601String(),
                      }).then((_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Task created successfully'), behavior: SnackBarBehavior.floating),
                          );
                        }
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text(
                    'Create Task',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditTaskDialog(
    BuildContext context,
    WidgetRef ref,
    TaskModel task,
  ) {
    final titleCtrl = TextEditingController(text: task.title);
    final descCtrl = TextEditingController(text: task.description);
    String? selectedProject = task.project?.id;
    String selectedPriority = task.priority.name;
    DateTime? selectedDate = task.dueDate;

    final projects = ref.read(projectsProvider);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.darkSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
            24,
            24,
            24,
            MediaQuery.of(ctx).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.darkBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Edit Task',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'Task title',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'Optional description',
                ),
              ),
              const SizedBox(height: 16),
              // Project dropdown
              projects.when(
                data: (projs) => DropdownButtonFormField<String>(
                  value: selectedProject,
                  decoration: const InputDecoration(labelText: 'Project'),
                  dropdownColor: AppColors.darkCard,
                  items: projs
                      .map(
                        (p) =>
                            DropdownMenuItem(value: p.id, child: Text(p.name)),
                      )
                      .toList(),
                  onChanged: (v) => setModalState(() => selectedProject = v),
                ),
                loading: () => const CircularProgressIndicator(),
                error: (_, __) => const Text('No projects'),
              ),
              const SizedBox(height: 16),
              // Priority
              DropdownButtonFormField<String>(
                value: selectedPriority,
                decoration: const InputDecoration(labelText: 'Priority'),
                dropdownColor: AppColors.darkCard,
                items: ['low', 'medium', 'high', 'urgent']
                    .map(
                      (p) => DropdownMenuItem(
                        value: p,
                        child: Text(p[0].toUpperCase() + p.substring(1)),
                      ),
                    )
                    .toList(),
                onChanged: (v) =>
                    setModalState(() => selectedPriority = v ?? 'medium'),
              ),
              const SizedBox(height: 16),
              // Due Date
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    setModalState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today, color: AppColors.textMuted, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        selectedDate != null
                            ? '${selectedDate!.year}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}'
                            : 'Select Due Date',
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    if (titleCtrl.text.isNotEmpty && selectedProject != null) {
                      ref.read(tasksProvider.notifier).updateTask(task.id, {
                        'title': titleCtrl.text,
                        'description': descCtrl.text,
                        'project': selectedProject,
                        'priority': selectedPriority,
                        if (selectedDate != null) 'dueDate': selectedDate!.toIso8601String(),
                      }).then((_) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Task updated successfully'), behavior: SnackBarBehavior.floating),
                          );
                        }
                      });
                      Navigator.pop(ctx);
                    }
                  },
                  child: const Text(
                    'Save Changes',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
