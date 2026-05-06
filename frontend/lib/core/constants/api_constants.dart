class ApiConstants {
  static const String baseUrl = 'http://192.168.1.58:3000/api'; // Physical device over Wi-Fi
  // static const String baseUrl = 'http://10.0.2.2:3000/api'; // Android emulator
  // static const String baseUrl = 'http://localhost:3000/api'; // iOS/Web

  // Auth
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String refreshToken = '/auth/refresh';
  static const String profile = '/auth/profile';

  // Projects
  static const String projects = '/projects';

  // Tasks
  static const String tasks = '/tasks';

  // Comments
  static String taskComments(String taskId) => '/tasks/$taskId/comments';
  static String comment(String id) => '/comments/$id';

  // Dashboard
  static const String dashboardStats = '/dashboard/stats';
  static const String dashboardRecent = '/dashboard/recent';
}
