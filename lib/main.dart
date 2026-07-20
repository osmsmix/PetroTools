import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'screens/home_screen.dart';

void main() {
  final binding = WidgetsFlutterBinding.ensureInitialized();
  // Keep the native splash up briefly; the app itself starts instantly.
  FlutterNativeSplash.preserve(widgetsBinding: binding);
  runApp(const PetroToolsApp());
  Future.delayed(const Duration(milliseconds: 1500), FlutterNativeSplash.remove);
}

class PetroToolsApp extends StatelessWidget {
  const PetroToolsApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4FC3F7);
    return MaterialApp(
      title: 'PetroTools',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: seed,
          brightness: Brightness.dark,
          surface: const Color(0xFF10161D),
        ),
        scaffoldBackgroundColor: const Color(0xFF0B1016),
        cardTheme: CardThemeData(
          color: const Color(0xFF161E27),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFF161E27),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: seed, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          centerTitle: false,
        ),
      ),
      home: const HomeScreen(),
    );
  }
}
