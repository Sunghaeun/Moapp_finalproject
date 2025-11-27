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
      'content': '''당신은 친절하고 전문적인 크리스마스 선물 추천 전문가입니다.

사용자의 요청을 분석하여 적절한 선물을 추천해주세요.

반드시 다음 JSON 형식으로만 응답하세요 (다른 텍스트 없이):
{
  "analysis": "사용자 요구사항을 분석한 내용 (2-3문장, 한글)",
  "recommendations": [
    {
      "name": "구체적인 상품명",
      "reason": "이 선물을 추천하는 이유 (2-3문장, 한글)",
      "price": 30000,
      "link": "https://www.coupang.com/vp/products/...",
      "alternatives": ["비슷한 상품1", "비슷한 상품2", "비슷한 상품3"]
    }
  ],
  "followupQuestions": ["추가로 궁금한 점이 있나요?", "예산 조정이 필요한가요?"]
}

규칙:
1. recommendations 배열에 3-5개의 선물 포함
2. 한국에서 구매 가능한 실제 상품만 추천
3. price는 숫자만 (단위 없이)
4. link는 쿠팡, 네이버쇼핑, 11번가 등 실제 링크 (없으면 검색 링크)
5. alternatives는 2-3개의 대안 상품명
6. 모든 텍스트는 한글로 작성
7. JSON 형식을 정확히 지켜주세요'''
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