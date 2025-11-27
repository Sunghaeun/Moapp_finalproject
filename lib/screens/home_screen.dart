// screens/home_screen.dart
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'chat_screen.dart';
import 'api_test_screen.dart'; // 추가

class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red[700]!,
              Colors.red[900]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // 크리스마스 애니메이션 (Lottie)
                    Container(
                      height: 200,
                      child: Icon(
                        Icons.card_giftcard,
                        size: 120,
                        color: Colors.white,
                      ),
                      // Lottie.asset('assets/animations/christmas.json')를 사용하려면
                      // assets 폴더에 애니메이션 파일 추가 필요
                    ),
                    SizedBox(height: 24),
                    Text(
                      '🎄 크리스마스 선물 AI 🎁',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 12),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        '선물 고민을 말씀해주세요\nAI가 완벽한 선물을 찾아드립니다',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.all(24),
                child: Column(
                  children: [
                    _buildFeatureChip('💬 자연어 대화'),
                    SizedBox(height: 8),
                    _buildFeatureChip('🎯 맞춤형 추천'),
                    SizedBox(height: 8),
                    _buildFeatureChip('💰 예산별 제안'),
                    SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ChatScreen()),
                          );
                        },
                        child: Text(
                          '선물 찾기 시작',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.red[700],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(28),
                          ),
                          elevation: 8,
                        ),
                      ),
                    ),
                    SizedBox(height: 12),
                    // API 테스트 버튼 추가
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: OutlinedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => ApiTestScreen()),
                          );
                        },
                        icon: Icon(Icons.bug_report),
                        label: Text(
                          'API 키 테스트 (개발용)',
                          style: TextStyle(fontSize: 14),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(color: Colors.white.withOpacity(0.5)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
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
    );
  }

  Widget _buildFeatureChip(String text) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}