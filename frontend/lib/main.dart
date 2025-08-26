import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/main_screen.dart';
import 'providers/inventory_provider.dart';

void main() {
  // Add debug logging
  debugPrint('🚀 Starting Inventory Management App...');

  runApp(const InventoryApp());
}

class InventoryApp extends StatelessWidget {
  const InventoryApp({super.key});

  @override
  Widget build(BuildContext context) {
    debugPrint('📱 Building InventoryApp...');

    return MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => InventoryProvider())],
      child: MaterialApp(
        title: 'Inventory Management',
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
