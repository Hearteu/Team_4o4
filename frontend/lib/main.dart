import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'providers/inventory_provider.dart';

void main() {
  // Add debug logging
  debugPrint('🚀 Starting Inventory Management App...');

  runApp(const MedEasyApp());
}

class MedEasyApp extends StatelessWidget {
  const MedEasyApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('📱 Building MedEasyApp...');

    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => InventoryProvider())],
      child: MaterialApp(
        title: 'MedEasy - Pharmacy Management',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const MainScreen(),
        builder: (context, child) {
          debugPrint('🎨 App theme applied successfully');
          return child!;
        },
      ),
    );
  }
}
