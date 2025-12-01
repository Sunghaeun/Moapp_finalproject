import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'screens/home_screen.dart';
import 'providers/chat_provider.dart';
import 'services/gift_database_service.dart';
import 'models/gift_model.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// 로그인 페이지 import
import 'login.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // .env 로드
  await dotenv.load(fileName: ".env");

  // Hive 초기화
  await Hive.initFlutter();
  Hive.registerAdapter(GiftAdapter());

  // Gift 초기 데이터 로드
  final giftService = GiftDatabaseService();
  await giftService.loadInitialData();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatProvider()),
      ],
      child: MaterialApp(
        title: '크리스마스 선물 AI',
        debugShowCheckedModeBanner: false,

        // 앱 첫 화면 = 로그인
        initialRoute: '/login',

        // 라우트 등록
        routes: {
          '/login': (context) => const LoginPage(),
          '/home': (context) => HomeScreen(),
        },

        // 전체 테마
        theme: ThemeData(
          primarySwatch: Colors.red,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.red,
            brightness: Brightness.light,
          ),
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
