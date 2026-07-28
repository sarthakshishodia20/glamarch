import 'package:flutter/material.dart';

class AppColors {
  // Brand colors — matches Admin Dashboard exactly
  static const Color primary = Color(0xFF1E1B4B);       // Deep indigo background
  static const Color accent = Color(0xFF3B35C3);         // Primary button / selection
  static const Color accentLight = Color(0xFF6366F1);    // Hover / lighter accent
  static const Color surface = Color(0xFF2D2A5E);        // Card background on dark
  static const Color surfaceLight = Color(0xFFF5F6FA);  // Light page background
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textMuted = Color(0xFF9CA3AF);
  static const Color success = Color(0xFF059669);
  static const Color error = Color(0xFFDC2626);
  static const Color warning = Color(0xFFF59E0B);
}

class AppConstants {
  // Production backend — Render URL
  static const String apiBaseUrl =
      'https://glam-backend-a2pc.onrender.com/api';

  // Local dev — Android Emulator (10.0.2.2 = localhost from emulator)
  // static const String apiBaseUrl = 'http://10.0.2.2:5000/api';

  // Local dev — Real device on same WiFi (replace with your laptop IP)
  // static const String apiBaseUrl = 'http://192.168.1.100:5000/api';
}
