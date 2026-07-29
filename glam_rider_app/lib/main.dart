import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/constants.dart';
import 'services/fcm_service.dart';
import 'screens/splash_screen.dart';
import 'screens/language_selection_screen.dart';
import 'screens/register_screen.dart';
import 'screens/login_screen.dart';
import 'screens/client_select_screen.dart';
import 'screens/document_center_screen.dart';
import 'screens/selfie_bgv_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Force portrait mode only — rider app is portrait
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // Status bar transparent so our dark header looks native
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize Firebase Cloud Messaging
  await FcmService().init();

  runApp(const GlamRiderApp());
}

class GlamRiderApp extends StatelessWidget {
  const GlamRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GLAM Rider',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        textTheme: GoogleFonts.interTextTheme(),
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          brightness: Brightness.dark,
        ),
      ),
      // Splash screen is the entry point — auto-navigates based on saved onboarding state
      home: const SplashScreen(),
      routes: {
        '/language': (context) => const LanguageSelectionScreen(),
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => const LoginScreen(),
        '/select-client': (context) => const ClientSelectScreen(),
        '/documents': (context) => const DocumentCenterScreen(),
        '/selfie-bgv': (context) => const SelfieBgvScreen(),
      },
    );
  }
}
