import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import '../services/user_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _auth = AuthService();
  final _userService = UserService();
  bool _loading = false;

  Future<void> _google() async {
    setState(() => _loading = true);

    try {
      final cred = await _auth.signInWithGoogle();

      if (cred != null && mounted) {
        // Firestore에 사용자 정보 저장
        await _userService.saveUser(cred.user!);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showError('Google 로그인 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _guest() async {
    setState(() => _loading = true);

    try {
      final cred = await _auth.signInAnonymously();

      if (cred != null && mounted) {
        // Firestore에 익명 사용자 정보 저장
        await _userService.saveUser(cred.user!);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      }
    } catch (e) {
      _showError('게스트 로그인 실패: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFEFA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                // 로고
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.card_giftcard,
                    size: 80,
                    color: Color(0xFFEF463F),
                  ),
                ),
                const SizedBox(height: 32),

                // 앱 이름
                const Text(
                  '크리스마시',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF012D5C),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '특별한 선물을 찾아보세요',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 64),

                // 구글 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _loading ? null : _google,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black87,
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    icon: Image.asset(
                      'assets/google_logo.png',
                      height: 24,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.login, color: Colors.red);
                      },
                    ),
                    label: const Text(
                      'Google로 로그인',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 게스트 로그인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _loading ? null : _guest,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF51934C),
                      side: const BorderSide(color: Color(0xFF51934C), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.person_outline),
                    label: const Text(
                      '게스트로 둘러보기',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                if (_loading) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(
                    color: Color(0xFFEF463F),
                  ),
                ],

                const SizedBox(height: 32),

                // 안내 문구
                Text(
                  '게스트로 로그인 시 일부 기능이 제한될 수 있습니다',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}