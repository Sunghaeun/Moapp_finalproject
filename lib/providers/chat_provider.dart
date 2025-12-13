// lib/providers/chat_provider.dart
import 'package:flutter/foundation.dart';
import '../models/chat_message.dart';
import '../models/gift_model.dart';
import '../services/openai_service.dart';
import '../services/naver_shopping_service.dart';

class ChatProvider extends ChangeNotifier {
  final OpenAIService _aiService = OpenAIService();
  final NaverShoppingService _naverService = NaverShoppingService();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  int _conversationStep = 0;
  Map<String, String> _userPreferences = {};
  String? _error;

  List<ChatMessage> get messages => _messages;
  bool get isTyping => _isTyping;
  int get conversationStep => _conversationStep;
  Map<String, String> get userPreferences => Map.unmodifiable(_userPreferences);
  String? get error => _error;

  // 추천 옵션
  final List<String> relationshipOptions = [
    '부모님',
    '연인',
    '친구',
    '직장 동료',
    '선생님/교수님'
  ];

  final List<String> ageOptions = [
    '10대',
    '20대',
    '30대',
    '40대',
    '50대 이상'
  ];

  final List<Map<String, dynamic>> priceOptions = [
    {'label': '2만원 이하', 'min': 0, 'max': 20000},
    {'label': '2-5만원', 'min': 20000, 'max': 50000},
    {'label': '5-10만원', 'min': 50000, 'max': 100000},
    {'label': '10만원 이상', 'min': 100000, 'max': 999999},
  ];

  final List<String> styleOptions = [
    '실용적인',
    '트렌디한',
    '고급스러운',
    '재미있는',
    '감성적인'
  ];

  String getPlaceholder() {
    switch (_conversationStep) {
      case 0:
        return '예: 20대 여자친구';
      case 1:
        return '예: 20대';
      case 2:
        return '예: 5만원 정도';
      case 3:
        return '예: 실용적인 선물';
      default:
        return '어떤 선물을 찾고 계시나요?';
    }
  }

  // 메시지 추가
  void addMessage(ChatMessage message) {
    _messages.add(message);
    _error = null;
    notifyListeners();
  }

  // 대화 시작
  void startConversation() {
    _messages.clear();
    _conversationStep = 0;
    _userPreferences.clear();
    _error = null;
    notifyListeners();

    Future.delayed(const Duration(milliseconds: 500), () {
      addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '안녕하세요!\n완벽한 크리스마스 선물을 찾도록 도와드릴게요.\n\n누구에게 선물하실 건가요?',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  // 프롬프트로 시작
  void startWithPrompt(String prompt) {
    _messages.clear();
    _conversationStep = 0;
    _userPreferences.clear();
    _error = null;
    notifyListeners();

    addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '안녕하세요! 크리스마시 AI입니다. 무엇을 도와드릴까요?',
        type: MessageType.assistant,
        timestamp: DateTime.now(),
      ),
    );

    handleTextMessage(prompt);
  }

  // 사용자 선택 처리
  Future<void> handleUserChoice(String choice, String category, {Map<String, dynamic>? priceData}) async {
    _userPreferences[category] = choice;

    if (priceData != null) {
      _userPreferences['price_min'] = priceData['min'].toString();
      _userPreferences['price_max'] = priceData['max'].toString();
    }

    addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: choice,
        type: MessageType.user,
        timestamp: DateTime.now(),
      ),
    );

    _isTyping = true;
    _conversationStep++;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    String nextQuestion = '';

    switch (_conversationStep) {
      case 1:
        nextQuestion = '받는 분의 연령대를 알려주세요';
        break;
      case 2:
        nextQuestion = '예산은 어느 정도로 생각하고 계신가요?';
        break;
      case 3:
        nextQuestion = '어떤 스타일의 선물을 원하시나요?';
        break;
      case 4:
        await generateRecommendations();
        return;
    }

    _isTyping = false;
    notifyListeners();

    addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: nextQuestion,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
      ),
    );
  }

  // 텍스트 메시지 처리
  Future<void> handleTextMessage(String text) async {
    if (text.trim().isEmpty) return;

    addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text.trim(),
        type: MessageType.user,
        timestamp: DateTime.now(),
      ),
    );

    await handleFreeTextInput(text.trim());
  }

  // 자유 텍스트 입력 처리
  Future<void> handleFreeTextInput(String text) async {
    _isTyping = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _aiService.getRecommendation(
        userInput: text,
        conversationHistory: _messages,
      );

      final List<Gift> recommendedGifts = [];
      for (final query in response.searchQueries) {
        final gifts = await _naverService.search(query, display: 1);
        if (gifts.isNotEmpty) {
          recommendedGifts.add(gifts.first);
        }
      }

      _isTyping = false;
      notifyListeners();

      addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: response.analysis,
          type: MessageType.assistant,
          timestamp: DateTime.now(),
          recommendedGifts: recommendedGifts,
        ),
      );
    } catch (e) {
      _isTyping = false;
      _error = e.toString();
      notifyListeners();

      addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '죄송해요, 이해하지 못했어요. 다시 말씀해주시겠어요?',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  // 추천 생성
  Future<void> generateRecommendations() async {
    addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '완벽한 선물을 찾고 있어요...',
        type: MessageType.assistant,
        timestamp: DateTime.now(),
      ),
    );

    _isTyping = true;
    _error = null;
    notifyListeners();

    try {
      final prompt = _buildPromptFromPreferences();
      final response = await _aiService.getRecommendation(
        userInput: prompt,
        conversationHistory: _messages,
      );

      final minPrice = int.tryParse(_userPreferences['price_min'] ?? '0') ?? 0;
      final maxPrice = int.tryParse(_userPreferences['price_max'] ?? '999999') ?? 999999;

      final List<Gift> recommendedGifts = [];
      for (final query in response.searchQueries) {
        final gifts = await _naverService.search(query, display: 10);

        final filteredGifts = gifts.where((gift) {
          return gift.price >= minPrice && gift.price <= maxPrice;
        }).toList();

        if (filteredGifts.isNotEmpty) {
          recommendedGifts.add(filteredGifts.first);
        } else if (gifts.isNotEmpty) {
          gifts.sort((a, b) {
            final aDiff = (a.price - (minPrice + maxPrice) / 2).abs();
            final bDiff = (b.price - (minPrice + maxPrice) / 2).abs();
            return aDiff.compareTo(bDiff);
          });
          recommendedGifts.add(gifts.first);
        }
      }

      _isTyping = false;
      notifyListeners();

      if (recommendedGifts.isEmpty) {
        addMessage(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: '죄송해요, 조건에 맞는 선물을 찾지 못했습니다.\n다른 조건으로 다시 시도해볼까요?',
            type: MessageType.assistant,
            timestamp: DateTime.now(),
          ),
        );
        return;
      }

      addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '${response.analysis}\n\n이런 선물들을 추천드려요',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
          recommendedGifts: recommendedGifts,
        ),
      );
    } catch (e) {
      _isTyping = false;
      _error = e.toString();
      notifyListeners();

      addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '죄송해요, 선물 추천 중 오류가 발생했습니다.\n다시 시도해주세요.',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  // 피드백 처리
  Future<void> handleFeedback(String feedback) async {
    addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: feedback,
        type: MessageType.user,
        timestamp: DateTime.now(),
      ),
    );

    if (feedback == '다시 답변요청') {
      await generateRecommendations();
    } else if (feedback == '좋아요') {
      addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '좋아해주셔서 감사합니다!\n다른 도움이 필요하시면 말씀해주세요.',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
        ),
      );
    } else if (feedback == '별로예요') {
      addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '아쉽네요. 더 나은 선물을 찾아드릴게요!',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      await generateRecommendations();
    }
  }

  // 제안 클릭 처리
  Future<void> handleSuggestionClick(String suggestion) async {
    addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: suggestion,
        type: MessageType.user,
        timestamp: DateTime.now(),
      ),
    );

    _isTyping = true;
    _error = null;
    notifyListeners();

    try {
      String modifiedPrompt = _buildPromptFromPreferences();

      if (suggestion.contains('다른 선물')) {
        modifiedPrompt += '\n\n이전과는 완전히 다른 카테고리의 새로운 선물을 추천해줘.';
      } else if (suggestion.contains('트렌디')) {
        modifiedPrompt += '\n\n최신 트렌드를 반영한 요즘 인기있는 선물을 추천해줘.';
      } else if (suggestion.contains('더 싼')) {
        modifiedPrompt += '\n\n이전 추천보다 가격이 낮은 가성비 좋은 선물을 추천해줘.';
      } else if (suggestion.contains('만족스러운')) {
        modifiedPrompt += '\n\n받는 사람뿐만 아니라 주는 사람도 뿌듯할 만한 의미있는 선물을 추천해줘.';
      } else if (suggestion.contains('3만원 이하')) {
        _userPreferences['price_min'] = '0';
        _userPreferences['price_max'] = '30000';
        modifiedPrompt = _buildPromptFromPreferences();
      }

      final response = await _aiService.getRecommendation(
        userInput: modifiedPrompt,
        conversationHistory: _messages,
      );

      final minPrice = int.tryParse(_userPreferences['price_min'] ?? '0') ?? 0;
      final maxPrice = int.tryParse(_userPreferences['price_max'] ?? '999999') ?? 999999;

      final List<Gift> recommendedGifts = [];
      for (final query in response.searchQueries) {
        final gifts = await _naverService.search(query, display: 10);

        final filteredGifts = gifts.where((gift) {
          return gift.price >= minPrice && gift.price <= maxPrice;
        }).toList();

        if (filteredGifts.isNotEmpty) {
          recommendedGifts.add(filteredGifts.first);
        } else if (gifts.isNotEmpty) {
          gifts.sort((a, b) {
            final aDiff = (a.price - (minPrice + maxPrice) / 2).abs();
            final bDiff = (b.price - (minPrice + maxPrice) / 2).abs();
            return aDiff.compareTo(bDiff);
          });
          recommendedGifts.add(gifts.first);
        }
      }

      _isTyping = false;
      notifyListeners();

      addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '${response.analysis}\n\n이런 선물들을 추천드려요',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
          recommendedGifts: recommendedGifts,
        ),
      );
    } catch (e) {
      _isTyping = false;
      _error = e.toString();
      notifyListeners();

      addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '죄송해요, 선물 추천 중 오류가 발생했습니다.',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  // 대화 초기화
  void resetConversation() {
    _conversationStep = 0;
    _userPreferences.clear();
    _messages.clear();
    _error = null;
    notifyListeners();
    startConversation();
  }

  // 프롬프트 생성
  String _buildPromptFromPreferences() {
    final minPrice = int.tryParse(_userPreferences['price_min'] ?? '0') ?? 0;
    final maxPrice = int.tryParse(_userPreferences['price_max'] ?? '999999') ?? 999999;

    return '''
다음 정보를 바탕으로 크리스마스 선물을 추천해줘:
- 받는 사람: ${_userPreferences['relationship'] ?? '지인'}
- 연령대: ${_userPreferences['age'] ?? '알 수 없음'}
- 예산: ${_formatPrice(minPrice)} ~ ${_formatPrice(maxPrice)}원 (이 가격대를 반드시 지켜줘)
- 스타일: ${_userPreferences['style'] ?? 'AI가 선택'}

중요: 추천하는 모든 선물은 반드시 ${_formatPrice(minPrice)} ~ ${_formatPrice(maxPrice)}원 사이여야 해.
검색어도 이 가격대를 고려해서 작성해줘.
''';
  }

  String _formatPrice(int price) {
    if (price >= 10000) {
      return '${(price / 10000).toStringAsFixed(0)}만';
    }
    return price.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},',
    );
  }
}
