import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🟢 初始化 Google AdMob 廣告 (不 await，避免卡在啟動)
  MobileAds.instance.initialize();
  
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
        scaffoldBackgroundColor: const Color(0xFF12141A), // 🟢 穩健暗灰色底色
        primaryColor: const Color(0xFF1A1D24),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFFD700), // 金黃色
          secondary: Color(0xFF10B981), // 翠綠色
          surface: Color(0xFF1A1D24), // 卡片灰
          onSurface: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF12141A),
          elevation: 0,
        ),
        useMaterial3: true,
      ),
      home: FutureBuilder(
        future: Supabase.initialize(
          url: 'https://yfetqtvzfcoftggdezjz.supabase.co',
          anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InlmZXRxdHZ6ZmNvZnRnZ2Rlemp6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzMxMzI0ODEsImV4cCI6MjA4ODcwODQ4MX0.gk2k1Ibfdf__aFpdPtzd6B79K3GIrK2g-uNopXr4_kk',
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return const HomeScreen(); // 連線打通後，推入首頁
          }
          // 在 Supabase 初始化背景跑動時，使用 Flutter 定製的動態載入頁面 (防原生卡屏)
          return const Scaffold(
            backgroundColor: Color(0xFF12141A),
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFFFFD700), // 炸開亮麗金黃色加載圈
              ),
            ),
          );
        },
      ),
    );
  }
}
