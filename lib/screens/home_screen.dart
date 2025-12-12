// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'chat_screen.dart';
import 'face_analysis_screen.dart';
import 'map_screen.dart';
import 'personality_test_screen.dart';
import 'cart_screen.dart';
import 'advent_calendar_screen.dart';
import '../services/cart_service.dart';
import '../services/advent_service.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final CartService _cartService = CartService();
  final AdventService _adventService = AdventService();
  int _cartCount = 0;
  int _adventProgress = 0;

  @override
  void initState() {
    super.initState();
    _updateCounts();
  }

  Future<void> _updateCounts() async {
    // 두 비동기 작업을 동시에 실행하여 시간 절약
    final results = await Future.wait([
      _cartService.getCartCount(),
      _adventService.getCompletedMissionCount(),
    ]);
    
    final cartCount = results[0];
    final adventProgress = results[1];
    setState(() {
      _cartCount = cartCount;
      _adventProgress = adventProgress;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final isGuest = user?.isAnonymous ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '크리스마시',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF012D5C),
          ),
        ),
        backgroundColor: const Color(0xFFFFFEFA),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.logout, color: Color(0xFF012D5C)),
          onPressed: () async {
            final confirm = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('로그아웃'),
                content: const Text('로그아웃 하시겠습니까?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('취소'),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('로그아웃'),
                  ),
                ],
              ),
            );

            if (confirm == true) {
              await _authService.signOut();
              if (mounted) {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            }
          },
        ),
        actions: [
          if (isGuest)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Chip(
                label: const Text('게스트', style: TextStyle(fontSize: 12)),
                backgroundColor: Colors.grey.shade300,
              ),
            ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_cart_outlined,
                  color: Color(0xFF012D5C),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const CartScreen()),
                  );
                  _updateCounts(); // 화면에서 돌아오면 카운트 업데이트
                },
              ),
              if (_cartCount > 0)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF463F),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _cartCount > 99 ? '99+' : '$_cartCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Container(
        color: Theme.of(context).colorScheme.background,
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // 크리스마스 애니메이션 (Lottie)
                      SizedBox(
                        height: 200,
                        child: Lottie.asset(
                          'assets/animations/christmas.json',
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.card_giftcard,
                              size: 120,
                              color: Color(0xFFEF463F),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        '크리스마시',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF012D5C),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          '어떤 선물을 찾고 계신가요?\nAI가 완벽한 크리스마스 선물을 찾아드립니다',
                          style: TextStyle(
                            fontSize: 16,
                            color: const Color(0xFF012D5C).withOpacity(0.8),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    children: [
                      // 어드벤트 캘린더 진행률
                      GestureDetector(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const AdventCalendarScreen()),
                          );
                          _updateCounts(); // 화면에서 돌아오면 카운트 업데이트
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF012D5C),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Column(
                            children: [
                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('🎄 크리스마스 완성도', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                  SizedBox(width: 8),
                                  Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Stack(
                                children: [
                                  Container(
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  FractionallySizedBox(
                                    widthFactor: _adventProgress / 24,
                                    child: Container(
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEF463F),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                  Align(
                                    child: Text('$_adventProgress / 24', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // 기본 선물 찾기 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ImprovedChatScreen(),
                              ),
                            );
                            _updateCounts(); // 돌아올 때 카운트 업데이트
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFEF463F), // Primary Red
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            elevation: 8,
                          ),
                          child: const Text(
                            '💬 대화로 선물 찾기',
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // NEW! 얼굴 분석 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const FaceAnalysisScreen(),
                              ),
                            );
                            _updateCounts(); // 돌아올 때 카운트 업데이트
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFF51934C), // Accent Green
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                              side: const BorderSide(color: Color(0xFF51934C), width: 2),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF51934C),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                '👤 얼굴로 선물 찾기',
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // NEW! 성향 테스트 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const PersonalityTestScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            foregroundColor: const Color(0xFF012D5C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                              side: const BorderSide(color: Color(0xFF012D5C), width: 2),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            elevation: 0,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '🎄',
                                style: TextStyle(fontSize: 20),
                              ),
                              SizedBox(width: 12),
                              Text(
                                '나의 크리스마스 유형은?',
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // 지도로 매장 찾기 버튼
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const MapScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF51934C), // Accent Green
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                            textStyle: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            elevation: 8,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.map_outlined,
                                size: 24,
                              ),
                              SizedBox(width: 12),
                              Text(
                                '🗺️ 지도에서 매장 찾기',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}