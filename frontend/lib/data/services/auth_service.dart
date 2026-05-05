import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../../main.dart' show sharedPrefs;
import '../models/user_model.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});

class AuthRepository {
  final Dio _dio;

  AuthRepository(this._dio);

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    await _saveTokens(response.data);
    return response.data;
  }

  Future<Map<String, dynamic>> register(
    String fullName,
    String email,
    String password,
  ) async {
    final response = await _dio.post(
      ApiConstants.register,
      data: {
        'fullName': fullName,
        'email': email,
        'password': password,
      },
    );
    await _saveTokens(response.data);
    return response.data;
  }

  Future<UserModel> getProfile() async {
    final response = await _dio.get(ApiConstants.profile);
    return UserModel.fromJson(response.data);
  }

  Future<void> logout() async {
    await sharedPrefs.remove('access_token');
    await sharedPrefs.remove('refresh_token');
  }

  bool isLoggedIn() {
    final token = sharedPrefs.getString('access_token');
    return token != null && token.isNotEmpty;
  }

  Future<void> _saveTokens(Map<String, dynamic> data) async {
    if (data['accessToken'] != null) {
      await sharedPrefs.setString('access_token', data['accessToken']);
    }
    if (data['refreshToken'] != null) {
      await sharedPrefs.setString('refresh_token', data['refreshToken']);
    }
  }
}
