
import 'package:flutter/material.dart';
import 'screens/add_food_screen.dart';
import 'screens/daily_summary_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Calorie Tracker',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
      ),
      home: const DailySummaryScreen(),
    );
  }
}
