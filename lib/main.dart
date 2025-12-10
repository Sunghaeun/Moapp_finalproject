// main.dart
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'screens/home_screen.dart';
import 'services/gift_database_service.dart';
import 'models/gift_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 환경 변수 로드
  await dotenv.load(fileName: ".env");
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: '크리스마시',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFEF463F), // Primary Red
            primary: const Color(0xFFEF463F),
            secondary: const Color(0xFF51934C), // Accent Green
            background: const Color(0xFFFFFefa), // Light Yellow/Cream
            surface: const Color(0xFFFFFefa),
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onBackground: const Color(0xFF012D5C), // Dark Blue for text
            onSurface: const Color(0xFF012D5C),
            error: Colors.red.shade900,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            foregroundColor: Color(0xFF012D5C),
            centerTitle: true,
            elevation: 0,
          ),
        ),
        home: const HomeScreen(),
      );
  }
}