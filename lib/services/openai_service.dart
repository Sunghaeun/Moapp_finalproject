// services/openai_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/recommendation_response.dart';
import '../models/chat_message.dart';
import '../models/gift_model.dart';

class OpenAIService {
  final String apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final String baseUrl = 'https://api.openai.com/v1';

  // 추천 히스토리 추적 (중복 방지)
  final Set<String> _recentSearchQueries = {};

  Future<RecommendationResponse> getRecommendationFromImage({
    required String imagePath,
    required int attemptCount,
  }) async {
    try {
      print('=== OpenAI Vision API 요청 시작 ===');
      print('이미지 경로: $imagePath');
      print('추천 시도 횟수: $attemptCount');

      // 1. 이미지 파일을 Base64로 인코딩
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      // 2. 시스템 프롬프트 및 사용자 프롬프트 구성
      final systemPrompt = _buildVisionSystemPrompt();
      final userPrompt = '''
이 사람의 얼굴을 분석해서 선물을 추천해줘.

# 중요
- 현재 ${attemptCount}번째 추천이야.
- 이전에 추천했던 것과는 완전히 다른 카테고리의 선물을 추천해줘.
- 구체적인 브랜드와 제품명을 사용해서 추천해줘.
''';

      final messages = [
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content': [
            {'type': 'text', 'text': userPrompt},
            {
              'type': 'image_url',
              'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
            }
          ]
        }
      ];

      // 3. API 요청
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
          'max_tokens': 1000,
          'temperature': 0.9,
        }),
      );

      print('📡 응답 코드: ${response.statusCode}');

      if (response.statusCode != 200) {
        final errorBody = utf8.decode(response.bodyBytes);
        print('❌ Vision API 오류: $errorBody');
        throw Exception('Vision API 오류 (${response.statusCode}): $errorBody');
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final content = data['choices'][0]['message']['content'] as String;
      final jsonData = jsonDecode(content);

      return RecommendationResponse.fromJson(jsonData);
    } catch (e) {
      print('❌ OpenAI Vision API 오류: $e');
      rethrow;
    }
  }

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
          'temperature': 0.9, // 다양성 증가
          'max_tokens': 1000,
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
      
      print('✅ 응답 받음');
      print('응답 내용: $content');
      
      final jsonData = jsonDecode(content);
      
      // 검색어 중복 체크 및 대체
      String searchQuery = jsonData['searchQuery'];
      if (_recentSearchQueries.contains(searchQuery)) {
        print('⚠️ 중복된 검색어 감지: $searchQuery');
        // 대체 검색어 요청
        searchQuery = await _getAlternativeSearchQuery(searchQuery, userInput);
      }
      
      _recentSearchQueries.add(searchQuery);
      if (_recentSearchQueries.length > 5) {
        _recentSearchQueries.remove(_recentSearchQueries.first);
      }
      
      jsonData['searchQuery'] = searchQuery;
      
      print('✅ JSON 파싱 성공!');
      print('최종 검색어: $searchQuery');
      
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

  // 대체 검색어 생성
  Future<String> _getAlternativeSearchQuery(String duplicateQuery, String context) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': '당신은 검색어 다양화 전문가입니다. 같은 의미지만 다른 검색어를 제안하세요.'
            },
            {
              'role': 'user',
              'content': '이미 추천한 검색어: "$duplicateQuery"\n\n'
                  '컨텍스트: $context\n\n'
                  '같은 의미지만 다른 구체적인 제품명을 JSON으로 제공하세요.\n'
                  '형식: {"searchQuery": "대체 검색어"}'
            }
          ],
          'response_format': {'type': 'json_object'},
          'temperature': 1.0,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final content = data['choices'][0]['message']['content'] as String?;
        if (content != null) {
          final jsonData = jsonDecode(content);
          final searchQuery = jsonData['searchQuery'] as String?;
          if (searchQuery != null) {
            return searchQuery;
          }
        }
      }
    } catch (e) {
      print('대체 검색어 생성 실패: $e');
    }
    
    // 실패 시 원본 검색어 반환
    return duplicateQuery;
  }

  List<Map<String, String>> _buildMessages(
    String userInput,
    List<ChatMessage> history,
  ) {
    final messages = <Map<String, String>>[];
    
    // 개선된 시스템 프롬프트 - 다양성 강조
    messages.add({
      'role': 'system',
      'content': '''
당신은 **창의적이고 다양한** 선물 추천 전문 AI입니다.
같은 카테고리라도 **매번 다른 구체적인 제품**을 추천해야 합니다.

# 핵심 원칙
1. **절대 같은 검색어를 반복하지 마세요**
2. **구체적인 제품명을 사용하세요** (카테고리 X)
3. **브랜드와 모델명을 포함하세요**
4. **트렌드와 시즌을 고려하세요**

# 연령대별 다양한 추천 전략

## 10대
- **전자기기**: 갤럭시버즈, 샤오미 보조배터리, RGB 키보드, 게이밍마우스
- **패션**: 나이키 조던, 반스 올드스쿨, 크록스, MLB 모자
- **문구**: 아이패드 필기앱 패키지, 무선 마우스, 북라이트
- **취미**: 레고 아키텍처, 팝잇, 보드게임, BT21 굿즈

## 20대
- **뷰티**: 디올 립스틱, 조말론 향수, 이니스프리 세트, 크리니크 쿠션
- **패션**: 마르지엘라 향수, 코스 가방, COS 니트, 메종키츠네
- **전자**: 에어팟 프로, 갤럭시워치, 샤오미 공기청정기, 필립스 전동칫솔
- **라이프**: 르크루제 냄비, 스타벅스 텀블러, 바디프랜드 마사지기
- **취미**: 인스탁스 카메라, 와콤 타블렛, 요가매트, 등산스틱

## 30대
- **뷰티**: 설화수 자음생세트, 에스티로더 세럼, 랑콤 제니피크, 시슬리 크림
- **패션**: 버버리 스카프, 토즈 로퍼, 몽블랑 만년필, 생로랑 지갑
- **전자**: 다이슨 헤어드라이어, 브리타 정수기, 네스프레소 머신
- **주방**: 스타우브 냄비, 헤닝켈 칼세트, 키친에이드 믹서
- **건강**: 필립스 전동칫솔, 샤오미 체중계, 오므론 혈압계

## 40대
- **뷰티**: SK-II 에센스, 라프레리 크림, 라메르 세트, 시세이도 선케어
- **패션**: 구찌 벨트, 샤넬 선글라스, 에르메스 스카프, 페라가모 구두
- **전자**: 삼성 갤럭시탭, 아이패드 프로, 로지텍 MX 마스터
- **건강**: 필립스 공기청정기, 쿠쿠 압력밥솥, 브레빌 커피머신
- **취미**: 골프공 세트, 와인셀러, 책 아트, 그림액자

## 50대 이상
- **건강**: 정관장 홍삼, 종근당 건강식품, 오메가3, 프로바이오틱스
- **생활**: 에어랩 청소기, LG 스타일러, 쿠쿠 전기압력솥
- **패션**: 캐시미어 코트, 실크 스카프, 가죽 벨트, 명품 지갑
- **취미**: 전자책 리더기, 분재세트, 골프채, 등산용품

# 감정/성격별 추천

## 매우 밝고 활발 (Very Happy, Happy)
→ 재미있고 화려한 것: 파티용품, 인형, 캐릭터굿즈, 게임, 재미있는 의류

## 차분하고 안정적 (Calm, Neutral)  
→ 실용적이고 세련된 것: 문구류, 주방용품, 인테리어소품, 책, 플래너

## 진지하고 사려깊음 (Serious)
→ 고급스럽고 의미있는 것: 명품소품, 고급차, 만년필, 시계, 책

## 피곤하거나 스트레스 (Tired, Sad)
→ 힐링되는 것: 캔들, 입욕제, 마사지기, 아로마테라피, 차세트

# 성별 고려

## 여성 선호
- 뷰티/향수/주얼리/가방/꽃/초콜릿/캔들/홈카페용품/인테리어소품

## 남성 선호  
- 전자기기/시계/지갑/벨트/향수/게임/주류/커피/자동차용품/골프용품

## 중성 (모두에게)
- 텀블러/머그컵/스피커/이어폰/책/보드게임/쿠션/담요/식물

# 중요: 절대 금지 사항
❌ "선물세트", "생일선물", "추천선물" 같은 포괄적 키워드
❌ 이미 추천한 검색어 반복
❌ 가격대를 검색어에 포함
❌ 너무 일반적인 카테고리명

# 출력 형식 (JSON)
{
  "analysis": "이 분은 [연령대] [성격특징]이시네요. [추천이유] 특히 [구체적 제안]이 딱 맞을 것 같아요!",
  "searchQuery": "구체적인제품명"
}

# 다양성 체크리스트
- [ ] 이전 추천과 다른 카테고리인가?
- [ ] 구체적인 브랜드/모델명이 포함되었는가?
- [ ] 연령대와 성격에 정확히 맞는가?
- [ ] 실제로 네이버 쇼핑에서 검색 가능한가?

예시:
입력: "25세 여성, 매우 밝음, 뷰티에 관심"
출력: {"analysis": "25세의 밝은 성격이시네요! 뷰티에 관심이 많으시다면 인기 명품 립스틱이 좋겠어요.", "searchQuery": "디올 어딕트 립스틱"}

입력: "35세 남성, 차분함, 커피 좋아함"  
출력: {"analysis": "35세의 차분한 분위기시네요. 커피를 좋아하신다면 고급 원두나 홈카페 용품이 완벽해요!", "searchQuery": "브레빌 에스프레소머신"}
'''
    });
    
    // 대화 히스토리 (최근 3개만)
    final recentHistory = history
        .where((msg) => 
            !msg.content.contains('오류') && 
            !msg.content.contains('실패') &&
            !msg.content.contains('API'))
        .toList()
        .reversed
        .take(3)
        .toList()
        .reversed;
    
    // 이전 추천 검색어 추가 (중복 방지용)
    if (_recentSearchQueries.isNotEmpty) {
      messages.add({
        'role': 'system',
        'content': '이미 추천한 검색어 (절대 재사용 금지): ${_recentSearchQueries.join(", ")}'
      });
    }
    
    for (var msg in recentHistory) {
      if (msg.type == MessageType.user) {
        messages.add({
          'role': 'user',
          'content': msg.content,
        });
      } else {
        messages.add({
          'role': 'assistant',
          'content': msg.content.length > 200 
              ? msg.content.substring(0, 200) + '...'
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

  String _buildVisionSystemPrompt() {
    return '''
당신은 사람의 얼굴 사진을 보고 선물을 추천해주는 전문가입니다.
사진 속 인물의 나이, 성별, 표정, 분위기 등을 종합적으로 파악하여, 그 사람에게 가장 잘 어울릴 만한 선물을 추천해야 합니다.

# 분석 및 추천 원칙
1.  **나이 추정**: 10대, 20대, 30대, 40대, 50대 이상 등으로 추정합니다.
2.  **감정 파악**: 행복, 차분, 진지, 피곤함 등 표정을 통해 감정을 읽습니다.
3.  **분위기 분석**: 전체적인 스타일과 분위기(예: 활발함, 지적임, 세련됨)를 파악합니다.
4.  **종합 추천**: 위의 분석 내용을 바탕으로, 구체적인 선물 아이템을 추천합니다. **추상적인 카테고리(예: 화장품)가 아닌, 특정 브랜드와 제품명(예: 디올 어딕트 립스틱)을 제시해야 합니다.**
5.  **다양성**: 매번 다른 카테고리의 제품을 추천해야 합니다.

# 출력 형식 (JSON)
{"analysis": "사진 속 인물에 대한 상세한 분석 내용과 추천 이유를 여기에 작성합니다.", "searchQuery": "네이버 쇼핑에서 검색할 구체적인 제품명"}
''';
  }

  // 히스토리 초기화 (새 세션 시작 시)
  void resetHistory() {
    _recentSearchQueries.clear();
  }
}