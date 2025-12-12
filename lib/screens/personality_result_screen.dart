import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import 'package:share_plus/share_plus.dart';
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

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
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
      backgroundColor: const Color(0xFF012D5C),
      appBar: AppBar(
        title: const Text(
          '🧐 나의 크리스마스 유형 결과', // 제목 변경
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        // 눈 내리는 타입일 때 AppBar 배경을 투명하게 만들어 자연스럽게 연결
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Stack(
        children: [
          const SnowfallWidget(),

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
                  _buildMatchingTypes(widget.personalityType),
                  const SizedBox(height: 32),
                  _buildRecommendations(widget.christmasTips),
                  const SizedBox(height: 24),
                  _buildShareButton(context),
                  const SizedBox(height: 16),
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
        color: Colors.white.withOpacity(0.9),
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

  // '찰떡궁합' 유형을 보여주는 위젯
  Widget _buildMatchingTypes(String currentType) {
    // 각 유형에 대한 정보 (아이콘, 이름)
    const typeDetails = {
      '집콕파': {'icon': '❄️', 'name': '눈처럼 포근한 집콕파'},
      '모임파': {'icon': '🔥', 'name': '모닥불처럼 따뜻한 모임파'},
      '산타파': {'icon': '🎁', 'name': '선물에 진심인 산타파'},
      '로맨틱파': {'icon': '💖', 'name': '낭만을 즐기는 로맨틱파'},
    };

    // 유형별 궁합 정보
    const matchingPairs = {
      '집콕파': '로맨틱파',
      '모임파': '산타파',
      '산타파': '모임파',
      '로맨틱파': '집콕파',
    };

    String? matchingTypeName;
    for (var key in matchingPairs.keys) {
      if (currentType.contains(key)) {
        matchingTypeName = matchingPairs[key];
        break;
      }
    }

    if (matchingTypeName == null || !typeDetails.containsKey(matchingTypeName)) {
      return const SizedBox.shrink(); // 매칭되는 타입이 없으면 아무것도 표시하지 않음
    }

    final matchingType = typeDetails[matchingTypeName]!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🤝 찰떡궁합 크리스마스 유형',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(matchingType['icon']!, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 12),
              Text(matchingType['name']!,
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecommendations(List<String> gifts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🎄 이런 크리스마스를 보내보세요!', // 텍스트 변경
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
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

  Widget _buildShareButton(BuildContext context) {
    return SizedBox(
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () {
          // share_plus를 사용하여 텍스트만 공유. 'text:' 파라미터를 제거합니다.
          Share.share('나의 크리스마스 유형은 "${widget.personalityTitle}"! 🎄\n당신의 유형도 알아보세요!');
        },
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.white, width: 2),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        icon: const Icon(Icons.share_outlined),
        label: const Text('결과 공유하기', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
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