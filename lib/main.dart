import 'package:flutter/material.dart';
import 'views/splash_screen_ui.dart';

void main() {
  runApp(const TaxiFareApp());
}

class TaxiFareApp extends StatelessWidget {
  const TaxiFareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Taxi Fare Calculator',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFFFFC107),
      ),
      home: const SplashScreenUi(),
    );
  }
}