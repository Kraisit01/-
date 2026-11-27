import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'views/splash_screen_ui.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://slazlbxmolwexeufvjta.supabase.co',
    anonKey: 'sb_publishable_HjC_4TMLCN5TSk622OZXEQ_qM2nnBmt',
  );
  runApp(const RunTrackerApp());
}

class RunTrackerApp extends StatelessWidget {
  const RunTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Run Tracker',
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF0A144A),
        useMaterial3: true,
      ),
      home: SplashScreenUi(),
    );
  }
}