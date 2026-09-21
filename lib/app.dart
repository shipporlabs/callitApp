import 'package:flutter/material.dart';
import 'screens/splash/splash_screen.dart';
import 'theme/app_theme.dart';

class CallitApp extends StatelessWidget {
  const CallitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Callit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
    );
  }
}
