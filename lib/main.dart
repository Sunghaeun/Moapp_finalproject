// main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

// 날짜 포맷 로케일 초기화를 위한 import
import 'package:intl/date_symbol_data_local.dart';

import 'screens/login_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'providers/cart_provider.dart';
import 'providers/chat_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // 환경 변수 로드
  await dotenv.load(fileName: ".env");

  // 날짜 locale 초기화 (❗한국어 날짜 사용 위해 필수)
  await initializeDateFormatting('ko_KR', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: '선물의 정석',
        debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF3A4E7A), // Sophisticated Blue
          primary: const Color(0xFF3A4E7A),
          secondary: const Color(0xFF6A7B76), // Calm Green-Gray
          tertiary: const Color(0xFFC0A06E), // Elegant Gold
          surface: const Color(0xFFFDFDFD),
          background: const Color(0xFFF7F7F7),
          onPrimary: Colors.white,
          onSecondary: Colors.black87,
          onTertiary: Colors.white,
          onBackground: const Color(0xFF1C1B1F),
          onSurface: const Color(0xFF1C1B1F),
          error: const Color(0xFFB00020),
          brightness: Brightness.light,
        ),
        fontFamily: 'Pretendard',
        scaffoldBackgroundColor: const Color(0xFFF7F7F7),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF7F7F7),
          foregroundColor: Color(0xFF1C1B1F),
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF1C1B1F),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF3A4E7A), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFF3A4E7A).withOpacity(0.1),
          selectedColor: const Color(0xFF3A4E7A),
          labelStyle: const TextStyle(
            color: Color(0xFF3A4E7A),
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      home: const LoginScreen(), // 로그인 화면을 첫 화면으로
      ),
    );
  }
}