// lib/models/personality_test_models.dart

/// 크리스마스 성향 테스트 결과 유형
enum XmasStyle {
  snow, // 눈처럼 포근한 집콕파
  campfire, // 모닥불처럼 따뜻한 모임파
  giftLover, // 선물에 진심인 산타파
  romantic, // 낭만을 즐기는 로맨틱파
}

/// 질문 선택지 모델
class PersonalityOption {
  final String text;
  final int score; // 1: snow, 2: campfire, 3: giftLover, 4: romantic

  const PersonalityOption({required this.text, required this.score});
}

/// 질문 모델
class PersonalityQuestion {
  final String text;
  final List<PersonalityOption> options;

  const PersonalityQuestion({required this.text, required this.options});
}