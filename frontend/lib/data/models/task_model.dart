import 'user_model.dart';
import 'project_model.dart';

enum TaskStatus { todo, inProgress, done }

enum TaskPriority { low, medium, high, urgent }

extension TaskStatusExtension on TaskStatus {
  String get value {
    switch (this) {
      case TaskStatus.todo:
        return 'todo';
      case TaskStatus.inProgress:
        return 'in_progress';
      case TaskStatus.done:
        return 'done';
    }
  }

  String get label {
    switch (this) {
      case TaskStatus.todo:
        return 'To Do';
      case TaskStatus.inProgress:
        return 'In Progress';
      case TaskStatus.done:
        return 'Done';
    }
  }

  static TaskStatus fromString(String value) {
    switch (value) {
      case 'in_progress':
        return TaskStatus.inProgress;
      case 'done':
        return TaskStatus.done;
      default:
        return TaskStatus.todo;
    }
  }
}

extension TaskPriorityExtension on TaskPriority {
  String get value {
    switch (this) {
      case TaskPriority.low:
        return 'low';
      case TaskPriority.medium:
        return 'medium';
      case TaskPriority.high:
        return 'high';
      case TaskPriority.urgent:
        return 'urgent';
    }
  }

  String get label {
    switch (this) {
      case TaskPriority.low:
        return 'Low';
      case TaskPriority.medium:
        return 'Medium';
      case TaskPriority.high:
        return 'High';
      case TaskPriority.urgent:
        return 'Urgent';
    }
  }

  static TaskPriority fromString(String value) {
    switch (value) {
      case 'medium':
        return TaskPriority.medium;
      case 'high':
        return TaskPriority.high;
      case 'urgent':
        return TaskPriority.urgent;
      default:
        return TaskPriority.low;
    }
  }
}

class TaskModel {
  final String id;
  final String title;
  final String description;
  final TaskStatus status;
  final TaskPriority priority;
  final ProjectModel? project;
  final UserModel? assignee;
  final UserModel? createdBy;
  final DateTime? scheduledAt;
  final List<String> tags;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TaskModel({
    required this.id,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = TaskPriority.medium,
    this.project,
    this.assignee,
    this.createdBy,
    this.scheduledAt,
    this.tags = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    return TaskModel(
      id: json['_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      status: TaskStatusExtension.fromString(json['status'] ?? 'todo'),
      priority: TaskPriorityExtension.fromString(json['priority'] ?? 'medium'),
      project: json['project'] != null && json['project'] is Map
          ? ProjectModel.fromJson(json['project'])
          : null,
      assignee: json['assignee'] != null && json['assignee'] is Map
          ? UserModel.fromJson(json['assignee'])
          : null,
      createdBy: json['createdBy'] != null && json['createdBy'] is Map
          ? UserModel.fromJson(json['createdBy'])
          : null,
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'])
          : json['dueDate'] != null
          ? DateTime.parse(json['dueDate'])
          : null,
      tags: json['tags'] != null ? List<String>.from(json['tags']) : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'title': title,
    'description': description,
    'status': status.value,
    'priority': priority.value,
    if (project != null) 'project': project!.id,
    if (assignee != null) 'assignee': assignee!.id,
    if (scheduledAt != null) 'scheduledAt': scheduledAt!.toIso8601String(),
    'tags': tags,
  };

  TaskModel copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    TaskPriority? priority,
    ProjectModel? project,
    UserModel? assignee,
    UserModel? createdBy,
    DateTime? scheduledAt,
    List<String>? tags,
  }) {
    return TaskModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      project: project ?? this.project,
      assignee: assignee ?? this.assignee,
      createdBy: createdBy ?? this.createdBy,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      tags: tags ?? this.tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
