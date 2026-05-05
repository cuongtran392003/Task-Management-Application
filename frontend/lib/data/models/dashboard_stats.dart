class DashboardStats {
  final int totalTasks;
  final int todoTasks;
  final int inProgressTasks;
  final int doneTasks;
  final int urgentTasks;
  final int completionRate;
  final int totalProjects;

  DashboardStats({
    this.totalTasks = 0,
    this.todoTasks = 0,
    this.inProgressTasks = 0,
    this.doneTasks = 0,
    this.urgentTasks = 0,
    this.completionRate = 0,
    this.totalProjects = 0,
  });

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalTasks: json['totalTasks'] ?? 0,
      todoTasks: json['todoTasks'] ?? 0,
      inProgressTasks: json['inProgressTasks'] ?? 0,
      doneTasks: json['doneTasks'] ?? 0,
      urgentTasks: json['urgentTasks'] ?? 0,
      completionRate: json['completionRate'] ?? 0,
      totalProjects: json['totalProjects'] ?? 0,
    );
  }
}
