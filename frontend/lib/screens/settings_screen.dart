import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Text(
          'Settings Screen - Coming Soon!',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
