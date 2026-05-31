import 'package:flutter/material.dart';
import 'core/theme/app_theme.dart';
import 'features/home/home_screen.dart';

class PbprApp extends StatelessWidget {
  const PbprApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PBPR',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
    );
  }
}
