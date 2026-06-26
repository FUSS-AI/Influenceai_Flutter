import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/setup_screen.dart';
import 'screens/session_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const InfluenceAIApp());
}

/// Root application widget.
///
/// Sets up the dark theme, Google Fonts, and navigation routes.
class InfluenceAIApp extends StatelessWidget {
  const InfluenceAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InfluenceAI Voice Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0A0F),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF8B5CF6),    // Purple — matches Vue `--primary`
          secondary: Color(0xFF06B6D4),  // Cyan — matches Vue `--secondary`
          surface: Color(0xFF0A0A0F),
          error: Color(0xFFF87171),
        ),
        textTheme: GoogleFonts.interTextTheme(
          ThemeData.dark().textTheme,
        ),
        useMaterial3: true,
      ),

      // ── Routes ──────────────────────────────────────────────────────
      initialRoute: '/',
      routes: {
        '/':        (_) => const SetupScreen(),
        '/session': (_) => const SessionScreen(),
      },
    );
  }
}
