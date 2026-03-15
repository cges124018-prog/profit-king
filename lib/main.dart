import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Supabase.initialize(
    url: 'https://yfetqtvzfcoftggdezjz.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZXRxdHZ6ZmNvZnRnZ2Rlemp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMxMzI0ODEsImV4cCI6MjA4ODcwODQ4MX0.gk2k1Ibfdf__aFpdPtzd6B79K3GIrK2g-uNopXr4_kk',
  );

  runApp(const ProfitKingApp());
}

class ProfitKingApp extends StatelessWidget {
  const ProfitKingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '獲利王',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F121C),
        primaryColor: const Color(0xFF1E2233),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700),
          secondary: Color(0xFF1E2233),
          surface: Color(0xFF0F121C),
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0F121C),
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
