import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'config/constants.dart';
import 'screens/language_selection_screen.dart';

void main() {
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
      // Screen 1 — Language Selection is the entry point
      home: const LanguageSelectionScreen(),
      // Named routes — will add more screens here as we build them
      routes: {
        '/language': (context) => const LanguageSelectionScreen(),
        // '/register': (context) => const RegisterScreen(),  // Screen 2 coming next
      },
    );
  }
}
