// main.dart

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';

// 날짜 포맷 로케일 초기화를 위한 import
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_screen.dart';
import 'services/gift_database_service.dart';
import 'models/gift_model.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

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
    return MaterialApp(
      title: '선물의 정석',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEF463F), // Primary Red
          primary: const Color(0xFFEF463F),
          secondary: const Color(0xFF51934C),
          tertiary: const Color(0xFF012D5C),
          surface: const Color(0xFFFFFEFA),
          background: const Color(0xFFFFFEFA),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onTertiary: Colors.white,
          onBackground: const Color(0xFF012D5C),
          onSurface: const Color(0xFF012D5C),
          error: const Color(0xFFBF3832),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFFFFEFA),

        cardTheme: CardThemeData(
          color: Colors.white,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFFFFEFA),
          foregroundColor: Color(0xFF012D5C),
          centerTitle: true,
          elevation: 0,
          titleTextStyle: TextStyle(
            color: Color(0xFF012D5C),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            elevation: 4,
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
            borderSide:
                BorderSide(color: const Color(0xFF012D5C).withOpacity(0.2)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide:
                BorderSide(color: const Color(0xFF012D5C).withOpacity(0.2)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFEF463F), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),

        chipTheme: ChipThemeData(
          backgroundColor: const Color(0xFFFDEDEC),
          selectedColor: const Color(0xFFEF463F),
          labelStyle: const TextStyle(
            color: Color(0xFF012D5C),
            fontWeight: FontWeight.w500,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),

      home: const HomeScreen(),
    );
  }
}