// lib/data/personality_test_data.dart

import '../models/personality_test_models.dart';

/// 테스트 질문 목록
const List<PersonalityQuestion> personalityQuestions = [
  PersonalityQuestion(
    text: '크리스마스 이브, 당신의 완벽한 저녁은?',
    options: [
      PersonalityOption(text: '따뜻한 담요 속에서 크리스마스 영화 정주행', score: 1),
      PersonalityOption(text: '북적이는 친구들과 함께하는 연말 파티', score: 2),
      PersonalityOption(text: '선물 교환식을 위한 마지막 포장 점검', score: 3),
      PersonalityOption(text: '반짝이는 야경이 보이는 레스토랑에서 저녁 식사', score: 4),
    ],
  ),
  PersonalityQuestion(
    text: '크리스마스 선물을 고를 때 당신은?',
    options: [
      PersonalityOption(text: '실용적이고 오래 쓸 수 있는 아이템을 선택', score: 1),
      PersonalityOption(text: '받는 사람이 좋아할 만한 유머러스한 아이템', score: 2),
      PersonalityOption(text: '몇 주 전부터 고민하고 준비한 서프라이즈 선물', score: 3),
      PersonalityOption(text: '선물보다는 함께 보내는 시간이 더 중요해', score: 4),
    ],
  ),
  PersonalityQuestion(
    text: '크리스마스에 듣고 싶은 캐롤은?',
    options: [
      PersonalityOption(text: '마음을 편안하게 해주는 잔잔한 연주곡', score: 1),
      PersonalityOption(text: '모두가 따라 부를 수 있는 신나는 캐롤', score: 2),
      PersonalityOption(text: '최신 음원 차트 1위 캐롤', score: 3),
      PersonalityOption(text: '오래된 LP판에서 흘러나오는 클래식 캐롤', score: 4),
    ],
  ),
  PersonalityQuestion(
    text: '크리스마스 트리를 꾸민다면?',
    options: [
      PersonalityOption(text: '심플하고 미니멀한 장식으로 은은하게', score: 1),
      PersonalityOption(text: '모두의 눈길을 사로잡는 화려하고 큰 트리', score: 2),
      PersonalityOption(text: '직접 만든 오너먼트로 가득 채운 트리', score: 3),
      PersonalityOption(text: '추억이 담긴 사진들로 꾸민 트리', score: 4),
    ],
  ),
];

/// 결과 데이터 맵
const Map<XmasStyle, Map<String, dynamic>> personalityResultData = {
  XmasStyle.snow: {
    'type': '❄️ 포근한 집콕파',
    'title': '아늑함이 최고야!',
    'description': '당신은 화려한 파티보다 따뜻한 집에서 보내는 크리스마스를 선호하는군요. 조용하고 편안한 분위기 속에서 소소한 행복을 찾는 당신은 진정한 힐링 마스터!',
    'tips': [
      '크리스마스 영화 몰아보기',
      '따뜻한 코코아 마시기',
      '수면 양말 신고 뒹굴기',
      '좋아하는 책 읽기',
    ],
  },
  XmasStyle.campfire: {
    'type': '🔥 따뜻한 모임파',
    'title': '함께라서 즐거워!',
    'description': '당신은 혼자보다는 여럿이 함께할 때 에너지가 넘치는 사람이군요! 소중한 사람들과 맛있는 음식을 나누고 웃고 떠들며 보내는 크리스마스를 가장 좋아합니다.',
    'tips': [
      '친구들과 포트럭 파티',
      '보드게임하며 밤새기',
      '쓸모없는 선물 교환식',
      '함께 캐롤 부르기',
    ],
  },
  XmasStyle.giftLover: {
    'type': '🎁 선물에 진심인 산타파',
    'title': '주는 기쁨이 더 커!',
    'description': '당신에게 크리스마스는 사랑하는 사람들을 위한 선물을 준비하는 설렘의 시간! 선물을 고르고 포장하며 행복해하는 당신은 모두를 위한 현대판 산타클로스예요.',
    'tips': [
      '정성 가득한 선물 포장',
      '손편지로 마음 전하기',
      '상대방 취향 저격 선물 찾기',
      '나를 위한 선물도 잊지 않기',
    ],
  },
  XmasStyle.romantic: {
    'type': '✨ 낭만을 즐기는 로맨틱파',
    'title': '분위기에 취해봐!',
    'description': '당신은 크리스마스 특유의 반짝이는 분위기를 사랑하는 로맨티스트! 아름다운 야경, 감미로운 음악과 함께라면 어디든 당신만의 특별한 크리스마스가 됩니다.',
    'tips': [
      '반짝이는 트리 명소 방문',
      '분위기 좋은 레스토랑 예약',
      '연인과 함께 와인 한 잔',
      '크리스마스 마켓 구경하기',
    ],
  },
};