import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dio/dio.dart';
import '../constants/api_constants.dart';

class NotificationService {
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final Dio _dio;

  NotificationService(this._dio);

  Future<void> initialize() async {
    // Request permission
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      debugPrint('User granted permission');
      
      // Get the token
      String? token = await _fcm.getToken();
      if (token != null) {
        await _sendTokenToServer(token);
      }

      // Listen to token changes
      _fcm.onTokenRefresh.listen(_sendTokenToServer);

      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('Received foreground message: ${message.notification?.title}');
        // You can show a local notification or update UI here
      });
    }
  }

  Future<void> _sendTokenToServer(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('access_token');
      if (accessToken != null) {
        await _dio.post(
          '${ApiConstants.baseUrl}/users/fcm-token',
          data: {'token': token},
        );
        debugPrint('FCM Token sent to server successfully');
      }
    } catch (e) {
      debugPrint('Error sending FCM token to server: $e');
    }
  }
}
