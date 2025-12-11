import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../widgets/snowfall_widget.dart'; // 새로 만든 위젯 import

class PersonalityResultScreen extends StatefulWidget {
  final String personalityType;
  final String personalityTitle;
  final String personalityDescription;
  final List<String> christmasTips; // 'recommendedGifts' 대신 'christmasTips'로 변경

  const PersonalityResultScreen({
    Key? key,
    required this.personalityType,
    required this.personalityTitle,
    required this.personalityDescription,
    required this.christmasTips,
  }) : super(key: key);

  @override
  State<PersonalityResultScreen> createState() => _PersonalityResultScreenState();
}

class _PersonalityResultScreenState extends State<PersonalityResultScreen> {
  late ConfettiController _confettiController;
  bool _isSnowyType = false;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _isSnowyType = widget.personalityType.contains('❄️');

    // 눈 내리는 타입이 아니면, 화면이 빌드된 후 confetti 효과를 재생합니다.
    if (!_isSnowyType) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _confettiController.play();
      });
    }
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 눈 내리는 타입일 때 배경을 어둡게 변경
      backgroundColor:
          _isSnowyType ? const Color(0xFF012D5C) : Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          '🧐 나의 크리스마스 유형 결과', // 제목 변경
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: _isSnowyType ? Colors.white : const Color(0xFF012D5C),
          ),
        ),
        // 눈 내리는 타입일 때 AppBar 배경을 투명하게 만들어 자연스럽게 연결
        backgroundColor: _isSnowyType ? Colors.transparent : Colors.white,
        foregroundColor: _isSnowyType ? Colors.white : const Color(0xFF012D5C),
        elevation: _isSnowyType ? 0 : 2,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // 조건부 배경 효과
          if (_isSnowyType) const SnowfallWidget(),

          // 메인 콘텐츠
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildResultCard(
                    personalityType: widget.personalityType,
                    personalityTitle: widget.personalityTitle,
                    personalityDescription: widget.personalityDescription,
                  ),
                  const SizedBox(height: 32),
                  _buildRecommendations(widget.christmasTips),
                  const SizedBox(height: 32),
                  _buildActionButton(context),
                ],
              ),
            ),
          ),

          // 조건부 전경 효과 (Confetti)
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              shouldLoop: false,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard({
    required String personalityType,
    required String personalityTitle,
    required String personalityDescription,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // 눈 내리는 타입일 때 반투명 배경으로 변경
        color: _isSnowyType ? Colors.white.withOpacity(0.9) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF012D5C).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              personalityType,
              style: const TextStyle(
                color: Color(0xFF012D5C),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            personalityTitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF012D5C),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            personalityDescription,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              color: const Color(0xFF012D5C).withOpacity(0.7),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendations(List<String> gifts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '🎄 이런 크리스마스를 보내보세요!', // 텍스트 변경
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: _isSnowyType ? Colors.white : const Color(0xFF012D5C),
          ),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: gifts
              .map((gift) => Chip(
                    label: Text(
                      gift,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    backgroundColor: const Color(0xFFEF463F),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () {
          // 홈 화면이나 선물 목록 화면으로 이동하는 로직
          Navigator.of(context).pop();
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF51934C),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        icon: const Icon(Icons.home_outlined),
        label: const Text(
          '홈으로 돌아가기',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}