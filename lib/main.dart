import 'package:flutter/material.dart';

import 'screens/home_shell.dart';

void main() {
  runApp(const CheckMeApp());
}

class CheckMeApp extends StatelessWidget {
  const CheckMeApp({super.key});

  @override
  Widget build(BuildContext context) {
    const seedColor = Color(0xFF2FBF71);

    return MaterialApp(
      title: 'CheckMe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: seedColor),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F8FA),
          foregroundColor: Colors.black87,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Colors.black87,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          height: 68,
          backgroundColor: Colors.white,
          indicatorColor: seedColor.withValues(alpha: 0.15),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: seedColor,
            foregroundColor: Colors.white,
          ),
        ),
        fontFamily: 'Roboto',
      ),
      home: const HomeShell(),
    );
  }
}
