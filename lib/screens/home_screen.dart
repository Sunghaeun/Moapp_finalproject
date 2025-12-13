import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';

import 'chat_screen.dart';
import 'face_analysis_screen.dart';
import 'map_screen.dart';
import 'personality_test_screen.dart';
import 'cart_screen.dart';
import 'advent_calendar_screen.dart';

import '../providers/cart_provider.dart';
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
  final AdventService _adventService = AdventService();

  int _adventProgress = 0;

  @override
  void initState() {
    super.initState();
    _updateCounts();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _updateCounts() async {
    final adventProgress = await _adventService.getCompletedMissionCount();

    if (!mounted) return;

    setState(() {
      _adventProgress = adventProgress;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  // ================= AppBar =================
  PreferredSizeWidget _buildAppBar() {
    final user = _authService.currentUser;
    final isGuest = user?.isAnonymous ?? false;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.logout),
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
      centerTitle: true,
      title: Text(
        'Chrismassy!',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.onBackground,
        ),
      ),
      actions: [
        if (isGuest)
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: Chip(
              label: const Text('게스트', style: TextStyle(fontSize: 12)),
              backgroundColor: Colors.grey.shade200,
              padding: EdgeInsets.zero,
            ),
          ),
        Consumer<CartProvider>(
          builder: (context, cartProvider, child) {
            return Stack(
              alignment: Alignment.center,
              children: [
                IconButton(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CartScreen()),
                    );
                    _updateCounts();
                  },
                  icon: const Icon(Icons.shopping_cart_outlined),
                ),
                if (cartProvider.itemCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Center(
                        child: Text(
                          '${cartProvider.itemCount}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  // ================= Body =================
  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAiCard(),
          const SizedBox(height: 24),
          const Text(
            '다양한 기능 둘러보기',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildAdventCard()),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _buildActionCard(
                      icon: Icons.face_retouching_natural,
                      title: '얼굴로 추천',
                      subtitle: '사진으로 취향 분석',
                      badge: 'NEW',
                      color: Theme.of(context).colorScheme.secondary,
                      onTap: () async {
                        await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const FaceAnalysisScreen()));
                        _updateCounts();
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildActionCard(
                      icon: Icons.psychology_outlined,
                      title: '성향 테스트',
                      subtitle: '나의 크리스마스 유형',
                      color: Theme.of(context).colorScheme.secondary,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PersonalityTestScreen()),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildActionCard(
            icon: Icons.map_outlined,
            title: '선물 지도',
            subtitle: '주변 선물가게 찾기',
            color: Theme.of(context).colorScheme.secondary,
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const MapScreen())),
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAiCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      shadowColor: Colors.black.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Lottie.asset(
              'assets/animations/christmas.json',
              height: 120,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.auto_awesome, size: 60),
            ),
            const SizedBox(height: 16),
            const Text(
              'AI에게 무엇이든 물어보세요',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '선물 받을 사람, 예산, 스타일을 알려주시면\nAI가 완벽한 선물을 찾아드릴게요!',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () async {
                await Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ImprovedChatScreen()));
                _updateCounts();
              },
              icon: const Icon(Icons.auto_awesome),
              label: const Text('AI와 대화 시작하기'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                textStyle:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAdventCard() {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AdventCalendarScreen()),
        );
        _updateCounts();
      },
      child: Container(
        height: 240, // 고정 높이
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF4A5C8A), Color(0xFF3A4E7A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF3A4E7A).withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '어드벤트 캘린더',
              style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 4),
            const Text(
              'D-25',
              style: TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const Spacer(),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      value: (_adventProgress / 24).clamp(0.0, 1.0),
                      strokeWidth: 8,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  Text(
                    '${(_adventProgress / 24 * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                ],
              ),
            ),
            const Spacer(),
            const Center(
              child: Text(
                '미션 확인하기',
                style: TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    String? badge,
    required VoidCallback onTap,
    bool isFullWidth = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: isFullWidth ? null : 112, // 고정 높이
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[200]!),
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: isFullWidth
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            if (isFullWidth)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: color, size: 24),
                  const SizedBox(width: 8),
                  Text(title,
                      style: const TextStyle(
                          fontSize: 17, fontWeight: FontWeight.bold)),
                ],
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: color, size: 28),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                            fontSize: 10,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                ],
              ),
              const Spacer(),
              Text(
                title,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ],
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black.withOpacity(0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
