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
      print('=== OpenAI API 요청 시작 ===');
      print('사용자 입력: $userInput');
      
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
          'temperature': 0.8,
          'max_tokens': 2000,
        }),
      );

      print('📡 응답 코드: ${response.statusCode}');

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
      
      print('✅ 응답 받음 (${content.length}자)');
      print('응답 내용: ${content.substring(0, content.length > 200 ? 200 : content.length)}...');
      
      final jsonData = jsonDecode(content);
      
      print('✅ JSON 파싱 성공!');
      print('추천 수: ${jsonData['recommendations']?.length ?? 0}');
      
      return RecommendationResponse.fromJson(jsonData);
      
    } catch (e, stackTrace) {
      print('❌ OpenAI API 오류: $e');
      print('스택 트레이스: $stackTrace');
      
      // 사용자 친화적 에러 메시지
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
    
    // 시스템 프롬프트
    messages.add({
      'role': 'system',
      'content': '''
# 페르소나 및 가이드라인
당신은 20년 경력의 선물 큐레이션 전문가이자 트렌드 애널리스트입니다.
진정성, 실용성, 특별함을 모두 고려하여 따뜻하지만 객관적인 조언을 제공합니다.

## 추천 프로세스
1. **프로파일링**: 받는 사람의 나이, 성별, 관계, 취향을 파악합니다.
2. **상황 분석**: 선물의 의미, 예산, 긴급도를 고려합니다.
3. **카테고리 선정**: 실용, 감성, 경험, 트렌드 중 최적의 카테고리를 정합니다.
4. **큐레이션**: 3-5개의 다양한 선물을 추천합니다.
5. **스토리텔링**: 각 선물이 "왜 이 사람에게 특별한지"에 대한 이야기를 전달합니다.

## 답변 스타일
- **공감**: 1-2 문장으로 사용자의 상황에 공감하며 시작합니다.
- **구체적 추천**: 각 선물마다 "왜 이 사람에게 이 선물인가"를 명확히 설명합니다. (예: "20대 여자친구라면 자기관리와 일상의 소소한 행복을 중요하게 여기는 시기죠. 디올 립스틱은 매일 아침 메이크업하며 당신을 떠올릴 수 있는 선물이에요...")
- **팁 제공**: 포장, 메시지 카드, 전달 타이밍 등 추가 팁을 제공합니다.

# 출력 형식
**반드시 다음 JSON 형식으로만 응답하세요. 다른 텍스트는 절대 포함하지 마세요.**
{
  "analysis": "사용자의 답변을 종합하여 선물 추천 방향을 요약하고 공감하는 내용 (2-3문장, 한글)",
  "searchQuery": "네이버 쇼핑 검색에 사용할 가장 효과적인 검색어 (예: 20대 여자친구 생일선물 5만원대)"
}

## 출력 규칙
1. `analysis`는 사용자의 답변을 기반으로 친절하게 작성하세요.
2. `searchQuery`는 네이버 쇼핑에서 최적의 결과를 얻을 수 있도록 핵심 키워드를 조합하여 만드세요.
3. 모든 텍스트는 한글로 작성하세요.
4. **JSON 형식과 규칙을 반드시 준수하세요.**
'''
    });
    
    // 대화 히스토리 (최근 8개, 에러 메시지 제외)
    final recentHistory = history
        .where((msg) => 
            !msg.content.contains('오류') && 
            !msg.content.contains('실패') &&
            !msg.content.contains('API'))
        .toList()
        .reversed
        .take(8)
        .toList()
        .reversed;
    
    for (var msg in recentHistory) {
      if (msg.type == MessageType.user) {
        messages.add({
          'role': 'user',
          'content': msg.content,
        });
      } else {
        // AI 응답은 간략하게 (토큰 절약)
        final content = msg.content.length > 500 
            ? msg.content.substring(0, 500) + '...'
            : msg.content;
        messages.add({
          'role': 'assistant',
          'content': content,
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