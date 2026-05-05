import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme.dart';
import '../../../data/providers/auth_provider.dart';
import '../../../data/providers/dashboard_provider.dart';
import '../../../data/models/task_model.dart';
import '../components/stat_card.dart';
import '../components/task_tile.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final statsAsync = ref.watch(dashboardStatsProvider);
    final recentAsync = ref.watch(recentTasksProvider);
    final userName = authState.user?.fullName ?? 'User';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(dashboardStatsProvider);
            ref.invalidate(recentTasksProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Hello,', style: TextStyle(fontSize: 14, color: AppColors.textSecondary)),
                      Text(userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                    ]),
                    GestureDetector(
                      onTap: () => ref.read(authProvider.notifier).logout(),
                      child: CircleAvatar(
                        radius: 24,
                        backgroundColor: AppColors.primary.withOpacity(0.2),
                        child: Text(userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.primary)),
                      ),
                    ),
                  ],
                ).animate().fadeIn(duration: 400.ms),
                const SizedBox(height: 28),

                // Stats cards
                statsAsync.when(
                  data: (stats) => Column(children: [
                    Row(children: [
                      Expanded(child: StatCard(title: 'Total Tasks', value: '${stats.totalTasks}', icon: Icons.assignment, color: AppColors.primary)),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(title: 'Completed', value: '${stats.doneTasks}', icon: Icons.check_circle, color: AppColors.success)),
                    ]).animate().fadeIn(delay: 200.ms, duration: 500.ms),
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(child: StatCard(title: 'In Progress', value: '${stats.inProgressTasks}', icon: Icons.pending, color: AppColors.info)),
                      const SizedBox(width: 12),
                      Expanded(child: StatCard(title: 'Projects', value: '${stats.totalProjects}', icon: Icons.folder, color: AppColors.accent)),
                    ]).animate().fadeIn(delay: 300.ms, duration: 500.ms),
                    const SizedBox(height: 16),
                    // Completion rate
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [AppColors.primary.withValues(alpha: 0.15), AppColors.accent.withValues(alpha: 0.1)]),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Row(children: [
                        Expanded(
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Text('Completion Rate', style: TextStyle(color: AppColors.textSecondary, fontSize: 14)),
                            const SizedBox(height: 8),
                            Text('${stats.completionRate}%', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
                          ]),
                        ),
                        SizedBox(
                          width: 80, height: 80,
                          child: Stack(alignment: Alignment.center, children: [
                            CircularProgressIndicator(
                              value: stats.completionRate / 100,
                              strokeWidth: 8,
                              backgroundColor: AppColors.darkBorder,
                              color: AppColors.accent,
                            ),
                            const Text('🔥', style: TextStyle(fontSize: 24)),
                          ]),
                        ),
                      ]),
                    ).animate().fadeIn(delay: 400.ms, duration: 500.ms),
                  ]),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const Center(child: Text('Failed to load stats', style: TextStyle(color: AppColors.error))),
                ),
                const SizedBox(height: 28),

                // Recent tasks
                const Text('Recent Tasks', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary))
                    .animate().fadeIn(delay: 500.ms),
                const SizedBox(height: 12),
                recentAsync.when(
                  data: (tasks) => tasks.isEmpty
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(40),
                          child: Column(children: [
                            Icon(Icons.inbox_rounded, size: 64, color: AppColors.textMuted),
                            SizedBox(height: 16),
                            Text('No tasks yet', style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                          ]),
                        ))
                      : ListView.separated(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: tasks.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (context, index) => TaskTile(task: tasks[index])
                              .animate().fadeIn(delay: Duration(milliseconds: 600 + index * 80)),
                        ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => const Center(child: Text('Failed to load tasks', style: TextStyle(color: AppColors.error))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
