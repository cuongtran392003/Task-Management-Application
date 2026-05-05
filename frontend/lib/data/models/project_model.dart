import 'user_model.dart';

class ProjectModel {
  final String id;
  final String name;
  final String description;
  final String color;
  final UserModel? owner;
  final List<UserModel> members;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ProjectModel({
    required this.id,
    required this.name,
    this.description = '',
    this.color = '#6C63FF',
    this.owner,
    this.members = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory ProjectModel.fromJson(Map<String, dynamic> json) {
    return ProjectModel(
      id: json['_id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      color: json['color'] ?? '#6C63FF',
      owner: json['owner'] != null && json['owner'] is Map
          ? UserModel.fromJson(json['owner'])
          : null,
      members: json['members'] != null
          ? (json['members'] as List)
              .where((m) => m is Map)
              .map((m) => UserModel.fromJson(m))
              .toList()
          : [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'description': description,
        'color': color,
      };
}
