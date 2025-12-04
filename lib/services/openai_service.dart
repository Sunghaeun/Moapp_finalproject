// services/openai_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/recommendation_response.dart';
import '../models/chat_message.dart';
import '../models/gift_model.dart';

class OpenAIService {
  final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final String baseUrl = 'https://api.openai.com/v1';

  Future<RecommendationResponse> getRecommendation({
    required String userInput,
    required List<ChatMessage> conversationHistory,
    List<Gift>? relevantGifts,
  }) async {
    try {
      final messages = _buildMessages(userInput, conversationHistory);
      
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': messages,
          'response_format': {'type': 'json_object'},
          'temperature': 0.7,
          'max_tokens': 1000,
        }),
      );

      if (response.statusCode == 429) {
        throw Exception('API 요청 한도 초과. 잠시 후 다시 시도해주세요.');
      }

      if (response.statusCode == 401) {
        throw Exception('API 키가 올바르지 않습니다. .env 파일을 확인해주세요.');
      }

      if (response.statusCode != 200) {
        final errorBody = utf8.decode(response.bodyBytes);
        print('❌ API 오류: $errorBody');
        throw Exception('API 오류 (${response.statusCode}): $errorBody');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      
      if (data['choices'] == null || (data['choices'] as List).isEmpty) {
        throw Exception('응답이 비어있습니다.');
      }
      
      final content = data['choices'][0]['message']['content'] as String;
      final jsonData = jsonDecode(content);
      
      return RecommendationResponse.fromJson(jsonData);
      
    } catch (e, stackTrace) {
      print('❌ OpenAI API 오류: $e');
      print('스택 트레이스: $stackTrace');
      
      if (e.toString().contains('401') || e.toString().contains('API 키')) {
        throw Exception('API 키 오류\n\n.env 파일에 OPENAI_API_KEY가 올바르게 설정되어 있는지 확인해주세요.');
      } else if (e.toString().contains('429')) {
        throw Exception('요청 한도 초과\n\n무료 크레딧을 모두 사용했거나, 요청이 너무 많습니다.\n잠시 후 다시 시도해주세요.');
      } else if (e.toString().contains('insufficient_quota')) {
        throw Exception('크레딧 부족\n\nOpenAI 계정에 크레딧을 충전해주세요.');
      }
      
      rethrow;
    }
  }

  List<Map<String, String>> _buildMessages(
    String userInput,
    List<ChatMessage> history,
  ) {
    final messages = <Map<String, String>>[];
    
    // 개선된 시스템 프롬프트
    messages.add({
      'role': 'system',
      'content': '''
당신은 한국 온라인 쇼핑몰 전문 검색어 생성 AI입니다.
사용자의 선물 요구사항을 분석하여 **네이버 쇼핑에서 실제로 검색 가능한** 키워드를 생성합니다.

# 검색어 생성 규칙 (매우 중요!)

1. **구체적인 제품명 사용**
   - ❌ "20대 여자친구 생일선물 5만원대" (너무 포괄적)
   - ✅ "향수", "립스틱", "텀블러", "에어팟", "손목시계"

2. **브랜드명 활용**: "디올 립스틱", "조말론 향수", "스타벅스 텀블러"
3. **가격대는 검색어에 포함하지 않음**: "향수" (가격은 결과에서 필터링)
4. **단순하고 명확한 키워드**:
   - 2-4단어 이내
   - 한국어로만 작성
   - 쇼핑몰에서 실제로 팔리는 제품명

# 추천 카테고리별 검색어 예시

**뷰티/화장품**: 향수, 립스틱, 스킨케어세트, 네일케어
**패션/잡화**: 지갑, 시계, 가방, 목도리, 장갑
**전자기기**: 무선이어폰, 블루투스스피커, 보조배터리, 스마트워치
**생활용품**: 텀블러, 머그컵, 캔들, 디퓨저, 쿠션
**취미/레저**: 보드게임, 퍼즐, 독서등, 운동용품
**식품**: 초콜릿세트, 와인, 커피세트, 견과류세트

# 출력 형식

**반드시 다음 JSON 형식으로만 응답하세요:**

{
  "analysis": "사용자가 찾는 선물에 대한 친절한 분석 (2-3문장, 한글)",
  "searchQuery": "네이버 쇼핑에서 검색할 구체적인 제품명 (2-4단어, 한글)"
}

# 예시

입력: "20대 여성, 로맨틱한 선물"
출력:
{
  "analysis": "20대 여성분들께 인기 있는 뷰티 아이템이나 패션 소품이 좋을 것 같아요. 일상에서 자주 사용할 수 있는 실용적인 선물을 추천드릴게요.",
  "searchQuery": "디올 립스틱"
}

입력: "30대 남성, 취미는 커피"
출력:
{
  "analysis": "커피를 좋아하시는 분이라면 홈카페 용품이나 고급 원두 세트가 좋겠네요. 직장 동료 선물로 적절한 실용적인 아이템을 찾아드릴게요.",
  "searchQuery": "커피 드리퍼 세트"
}

입력: "50대 이상 여성, 건강한 선물"
출력:
{
  "analysis": "건강에 관심이 많으신 분이라면 건강기능식품이나 건강관리 용품이 좋을 것 같아요. 정성이 담긴 건강 선물을 추천드릴게요.",
  "searchQuery": "홍삼세트"
}

# 중요 사항
- searchQuery는 반드시 **네이버 쇼핑에 존재하는 실제 제품명**이어야 합니다
- 너무 포괄적이거나 추상적인 검색어는 피하세요
- 나이, 관계 등은 analysis에만 포함하고 searchQuery에는 넣지 마세요
'''
    });
    
    // 대화 히스토리 (최근 4개만)
    final recentHistory = history
        .where((msg) => 
            !msg.content.contains('오류') && 
            !msg.content.contains('실패') &&
            !msg.content.contains('API'))
        .toList()
        .reversed
        .take(4)
        .toList()
        .reversed;
    
    for (var msg in recentHistory) {
      if (msg.type == MessageType.user) {
        messages.add({
          'role': 'user',
          'content': msg.content,
        });
      } else {
        messages.add({
          'role': 'assistant',
          'content': msg.content.length > 300 
              ? msg.content.substring(0, 300) + '...'
              : msg.content,
        });
      }
    }
    
    // 현재 사용자 입력
    messages.add({
      'role': 'user',
      'content': userInput,
    });
    
    print('메시지 수: ${messages.length}');
    return messages;
  }
}