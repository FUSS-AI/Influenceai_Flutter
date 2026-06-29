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
/// Sets up the premium dark theme with Outfit typography and
/// a midnight indigo color scheme.
class InfluenceAIApp extends StatelessWidget {
  const InfluenceAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'InfluenceAI Voice Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF060B18),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF7C5CFC),     // Electric indigo
          secondary: Color(0xFF00D4AA),   // Neon mint
          tertiary: Color(0xFFFF6B9D),    // Soft rose
          surface: Color(0xFF0D1527),
          error: Color(0xFFFF6B6B),
        ),
        textTheme: GoogleFonts.outfitTextTheme(
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
