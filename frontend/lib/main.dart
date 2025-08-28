import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

import 'providers/inventory_provider.dart';
import 'screens/main_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
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
