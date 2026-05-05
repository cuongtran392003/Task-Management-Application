import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/task_model.dart';

class TaskTile extends StatelessWidget {
  final TaskModel task;
  const TaskTile({super.key, required this.task});

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.urgent: return AppColors.priorityUrgent;
      case TaskPriority.high: return AppColors.priorityHigh;
      case TaskPriority.medium: return AppColors.priorityMedium;
      case TaskPriority.low: return AppColors.priorityLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(children: [
        Container(width: 4, height: 40, decoration: BoxDecoration(color: _priorityColor, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task.title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary,
                decoration: task.status == TaskStatus.done ? TextDecoration.lineThrough : null)),
            const SizedBox(height: 4),
            Text(task.project?.name ?? '', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ]),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: task.status == TaskStatus.done
                ? AppColors.success.withValues(alpha: 0.15)
                : task.status == TaskStatus.inProgress
                    ? AppColors.info.withValues(alpha: 0.15)
                    : AppColors.textMuted.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(task.status.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              color: task.status == TaskStatus.done ? AppColors.success : task.status == TaskStatus.inProgress ? AppColors.info : AppColors.textMuted)),
        ),
      ]),
    );
  }
}
