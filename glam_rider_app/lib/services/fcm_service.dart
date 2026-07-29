import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/constants.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('[FCM_BG_MSG] Received message: ${message.messageId} | Title: ${message.notification?.title}');
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    try {
      await Firebase.initializeApp();
      _initialized = true;
      debugPrint('[FCM] Firebase initialized successfully');

      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

      // Request Notification Permission
      FirebaseMessaging messaging = FirebaseMessaging.instance;
      NotificationSettings settings = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      debugPrint('[FCM] Permission status: ${settings.authorizationStatus}');

      // Get FCM Token
      String? token = await messaging.getToken();
      if (token != null) {
        debugPrint('[FCM] Device Token: $token');
        await sendTokenToBackend(token);
      }

      // Token Refresh listener
      messaging.onTokenRefresh.listen((newToken) {
        debugPrint('[FCM] Token Refreshed: $newToken');
        sendTokenToBackend(newToken);
      });

      // Foreground Notification Handler
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        debugPrint('[FCM_FG_MSG] ${message.notification?.title}: ${message.notification?.body}');
      });

    } catch (e) {
      debugPrint('[FCM_INIT_WARNING] Firebase not configured yet or google-services.json missing: $e');
    }
  }

  Future<void> sendTokenToBackend(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jwtToken = prefs.getString('token');
      if (jwtToken == null || jwtToken.isEmpty) return;

      final response = await http.post(
        Uri.parse('${AppConstants.apiBaseUrl}/riders/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $jwtToken',
        },
        body: jsonEncode({'fcm_token': token}),
      );

      if (response.statusCode == 200) {
        debugPrint('[FCM_SYNC] FCM token synced with GLAM Backend');
      }
    } catch (e) {
      debugPrint('[FCM_SYNC_ERROR] Failed to send token to backend: $e');
    }
  }
}
