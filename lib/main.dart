import 'package:flutter/material.dart';

import 'screens/welcome_screen.dart';
import 'services/notification_service.dart';
import 'services/supabase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase Client
  await SupabaseService.instance.initialize();

  // Initialize Local & Push Notifications
  await NotificationService.instance.initialize();

  runApp(const HayaEventManagementApp());
}

class HayaEventManagementApp extends StatelessWidget {
  const HayaEventManagementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Haya Event Management',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const WelcomeScreen(),
    );
  }
}
