// lib/screens/personality_test_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart'; // flutter_swiper_view 패키지 사용
import 'package:percent_indicator/percent_indicator.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../models/personality_test_models.dart'; // 새로 생성한 모델 파일
import '../data/personality_test_data.dart'; // 새로 생성한 데이터 파일
import 'personality_result_screen.dart';

class PersonalityTestScreen extends StatefulWidget {
  const PersonalityTestScreen({super.key});

  @override
  State<PersonalityTestScreen> createState() => _PersonalityTestScreenState();
}

class _PersonalityTestScreenState extends State<PersonalityTestScreen> {
  final SwiperController _swiperController = SwiperController();
  final List<int> _answers = [];
  int _currentIndex = 0;

  void _onOptionSelected(int score) {
    setState(() {
      _answers.add(score);
      _currentIndex++;
    });

    if (_currentIndex < personalityQuestions.length) {
      _swiperController.next();
    } else {
      _calculateResult();
    }
  }

  void _calculateResult() {
    Map<int, int> scoreCounts = {1: 0, 2: 0, 3: 0, 4: 0};
    for (var answer in _answers) {
      scoreCounts[answer] = (scoreCounts[answer] ?? 0) + 1;
    }

    // 가장 많이 선택된 점수를 찾습니다.
    int maxCount = 0;
    int finalScore = 1;
    scoreCounts.forEach((score, count) {
      if (count > maxCount) {
        maxCount = count;
        finalScore = score;
      }
    });

    XmasStyle resultStyle;
    switch (finalScore) {
      case 1:
        resultStyle = XmasStyle.snow;
        break;
      case 2:
        resultStyle = XmasStyle.campfire;
        break;
      case 3:
        resultStyle = XmasStyle.giftLover;
        break;
      case 4:
        resultStyle = XmasStyle.romantic;
        break;
      default:
        resultStyle = XmasStyle.snow;
    }

    // 결과 화면으로 이동
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        // PersonalityResultScreen의 생성자에 맞게 데이터 전달
        builder: (context) => PersonalityResultScreen(
          personalityType: personalityResultData[resultStyle]!['type'],
          personalityTitle: personalityResultData[resultStyle]!['title'],
          personalityDescription: personalityResultData[resultStyle]!['description'],
          christmasTips: List<String>.from(personalityResultData[resultStyle]!['tips']),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    double progress = (_currentIndex / personalityQuestions.length).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🎄 크리스마스 성향 테스트'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: LinearPercentIndicator(
              percent: progress,
              lineHeight: 12.0,
              barRadius: const Radius.circular(6),
              backgroundColor: Colors.grey[200],
              progressColor: Theme.of(context).colorScheme.primary,
              animateFromLastPercent: true,
              animation: true,
            ),
          ),
          Expanded(
            child: Swiper(
              itemCount: personalityQuestions.length,
              controller: _swiperController,
              physics: const NeverScrollableScrollPhysics(), // 스와이프로 못넘기게
              itemBuilder: (context, index) {
                final question = personalityQuestions[index];
                return _buildQuestionCard(question);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(PersonalityQuestion question) {
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          )
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Q${_currentIndex + 1}.',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            question.text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600, height: 1.4),
          ),
          const SizedBox(height: 40),
          ...question.options.asMap().entries.map((entry) {
            final option = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _onOptionSelected(option.score),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: BorderSide(color: Colors.grey[300]!),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    option.text,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ).animate().fade(delay: (200 * (entry.key + 1)).ms).slideY(begin: 0.5);
          }),
        ],
      ),
    );
  }
}
