import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/login_screen.dart';
import 'services/firebase_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase (wrapped in try-catch so app runs even before credentials are added)
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
  // Simple boolean to track dark mode state (Lecturer style)
  bool isDarkMode = false;

  @override
  void initState() {
    super.initState();
    // Check device system theme on startup (lecturer style)
    final systemBrightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
    isDarkMode = (systemBrightness == Brightness.dark);
  }

  // Simple function to toggle theme
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
