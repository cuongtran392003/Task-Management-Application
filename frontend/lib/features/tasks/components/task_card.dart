import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../data/models/task_model.dart';

class TaskCard extends StatelessWidget {
  final TaskModel task;
  final Function(String) onStatusChanged;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const TaskCard({
    super.key,
    required this.task,
    required this.onStatusChanged,
    required this.onDelete,
    required this.onEdit,
  });

  Color get _priorityColor {
    switch (task.priority) {
      case TaskPriority.urgent:
        return AppColors.priorityUrgent;
      case TaskPriority.high:
        return AppColors.priorityHigh;
      case TaskPriority.medium:
        return AppColors.priorityMedium;
      case TaskPriority.low:
        return AppColors.priorityLow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: Key(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: AppColors.error.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.delete, color: AppColors.error),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onEdit,
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.darkCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.darkBorder),
          ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(width: 4, height: 32, decoration: BoxDecoration(color: _priorityColor, borderRadius: BorderRadius.circular(2))),
            const SizedBox(width: 12),
            Expanded(child: Text(task.title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary))),
            PopupMenuButton<String>(
              onSelected: onStatusChanged,
              icon: const Icon(Icons.more_vert, color: AppColors.textMuted, size: 20),
              color: AppColors.darkCard,
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'todo', child: Text('To Do')),
                const PopupMenuItem(value: 'in_progress', child: Text('In Progress')),
                const PopupMenuItem(value: 'done', child: Text('Done')),
              ],
            ),
          ]),
          if (task.description.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4),
              child: Text(task.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
            ),
          const SizedBox(height: 8),
          Row(children: [
            const SizedBox(width: 16),
            Chip(label: Text(task.priority.label), backgroundColor: _priorityColor.withValues(alpha: 0.15),
                labelStyle: TextStyle(color: _priorityColor, fontSize: 11, fontWeight: FontWeight.w600)),
            const SizedBox(width: 8),
            Chip(label: Text(task.status.label),
                backgroundColor: task.status == TaskStatus.done ? AppColors.success.withValues(alpha: 0.15) : AppColors.info.withValues(alpha: 0.15),
                labelStyle: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
                    color: task.status == TaskStatus.done ? AppColors.success : AppColors.info)),
            const Spacer(),
            if (task.dueDate != null) ...[
              const Icon(Icons.calendar_today, size: 12, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Text('${task.dueDate!.day}/${task.dueDate!.month}/${task.dueDate!.year}', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(width: 8),
            ],
            if (task.project != null)
              Text(task.project!.name, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ]),
        ]),
      ),
      ),
    );
  }
}
