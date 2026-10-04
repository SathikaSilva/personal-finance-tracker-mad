import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase services
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    AppFirebaseService.isFirebaseInitialized = true;
  } catch (e) {
    debugPrint("Firebase init notice: $e");
    AppFirebaseService.isFirebaseInitialized = false;
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // Theme state: true for dark mode, false for light mode
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    // Detect system theme setting on startup
    final systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    isDarkMode = (systemBrightness == Brightness.dark);
  }

  // Toggle theme between light and dark
  void toggleTheme() {
    setState(() {
      isDarkMode = !isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Personal Finance Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: LoginScreen(
        toggleTheme: toggleTheme,
        isDarkMode: isDarkMode,
      ),
    );
  }
}
