import 'package:flutter/material.dart';
// Import the Splash Screen
import 'features/onboarding/presentation/splash_screen.dart'; 

class MyKhataApp extends StatelessWidget {
  const MyKhataApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MyKhata',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        // CHANGED TO BLUE
        primarySwatch: Colors.blue,
        primaryColor: Colors.blue,
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.blue, // Blue App Bar
          foregroundColor: Colors.white,
          centerTitle: true,
          elevation: 0,
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
      // Start with the Animated Splash Screen
      home: const SplashScreen(),
    );
  }
}