// providers/chat_provider.dart
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/gift_model.dart';
import '../services/openai_service.dart';
import '../services/naver_shopping_service.dart';

enum ChatState { asking, loading, finished }

enum QuestionType { text, selection }

class QuestionData {
  final String question;
  final QuestionType type;
  final List<SelectionChoice>? choices;

  QuestionData({
    required this.question,
    required this.type,
    this.choices,
  });
}

class SelectionChoice {
  final String label;
  final String value;
  final String? emoji;

  SelectionChoice({
    required this.label,
    required this.value,
    this.emoji,
  });
}

class ChatProvider extends ChangeNotifier {
  final OpenAIService _aiService = OpenAIService();
  final NaverShoppingService _naverService = NaverShoppingService();

  ChatState _state = ChatState.asking;
  String _currentQuestion = '안녕하세요! 특별한 선물을 찾고 계신가요?\n\n어떤 선물을 찾고 있나요?';
  QuestionType _currentQuestionType = QuestionType.selection;
  final List<Map<String, String>> _answers = [];
  List<Gift> _recommendations = [];
  List<ChatMessage> _conversationHistory = [];
  int _currentStep = 0;

  final List<QuestionData> _questions = [
    QuestionData(
      question: '어떤 성별에 어울리는 선물을 찾고 있나요?',
      type: QuestionType.selection,
      choices: [
        SelectionChoice(label: '누구에게나', value: '누구에게나', emoji: '👥'),
        SelectionChoice(label: '여성', value: '여성', emoji: '👩'),
        SelectionChoice(label: '남성', value: '남성', emoji: '👨'),
        SelectionChoice(label: '강아지', value: '강아지', emoji: '🐕'),
        SelectionChoice(label: '고양이', value: '고양이', emoji: '🐈'),
      ],
    ),
    QuestionData(
      question: '특정 연령대에 어울리는 선물이 필요한가요?',
      type: QuestionType.selection,
      choices: [
        SelectionChoice(label: '아니요', value: '상관없음'),
        SelectionChoice(label: '10대', value: '10대'),
        SelectionChoice(label: '20대', value: '20대'),
        SelectionChoice(label: '30대', value: '30대'),
        SelectionChoice(label: '40대', value: '40대'),
        SelectionChoice(label: '50대 이상', value: '50대 이상'),
        SelectionChoice(label: '유아동', value: '유아동'),
      ],
    ),
    QuestionData(
      question: '어떤 선물을 선호하나요?',
      type: QuestionType.selection,
      choices: [
        SelectionChoice(label: '취향 저격', value: '취향 저격', emoji: '🎯'),
        SelectionChoice(label: '베스트셀러', value: '베스트셀러', emoji: '🏆'),
        SelectionChoice(label: '럭셔리한', value: '럭셔리한', emoji: '💎'),
        SelectionChoice(label: '맛있는', value: '맛있는', emoji: '🍰'),
        SelectionChoice(label: '로맨틱한', value: '로맨틱한', emoji: '💕'),
        SelectionChoice(label: '건강한', value: '건강한', emoji: '💊'),
        SelectionChoice(label: '힐링/위로', value: '힐링', emoji: '🌿'),
      ],
    ),
    QuestionData(
      question: '선물 가격대는 어느 정도로 생각하세요?',
      type: QuestionType.text,
    ),
  ];

  ChatState get state => _state;
  String get currentQuestion => _currentQuestion;
  QuestionType get currentQuestionType => _currentQuestionType;
  QuestionData get currentQuestionData => _questions[_currentStep];
  List<Gift> get recommendations => _recommendations;
  List<ChatMessage> get conversationHistory => _conversationHistory;

  ChatProvider() {
    _startConversation();
  }

  void _startConversation() {
    _state = ChatState.asking;
    _currentStep = 0;
    _currentQuestion = _questions[_currentStep].question;
    _currentQuestionType = _questions[_currentStep].type;
    _answers.clear();
    _recommendations.clear();
    _conversationHistory.clear();
    _conversationHistory.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: _currentQuestion,
      type: MessageType.assistant,
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }

  Future<void> sendAnswer(String answer) async {
    _answers.add({'question': _questions[_currentStep].question, 'answer': answer});
    _conversationHistory.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: answer,
      type: MessageType.user,
      timestamp: DateTime.now(),
    ));

    _currentStep++;

    if (_currentStep >= _questions.length) {
      _state = ChatState.loading;
      notifyListeners();

      try {
        final fullContext = _answers.map((qa) => "${qa['question']}\n답변: ${qa['answer']}").join('\n\n');
        
        print('=== 전체 컨텍스트 ===');
        print(fullContext);
        
        final response = await _aiService.getRecommendation(
          userInput: fullContext,
          conversationHistory: _conversationHistory,
        );

        print('=== AI 분석 결과 ===');
        print('분석: ${response.analysis}');
        print('검색어: ${response.searchQuery}');

        _recommendations = await _naverService.search(response.searchQuery);

        _conversationHistory.add(ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: response.analysis,
          type: MessageType.assistant,
          timestamp: DateTime.now(),
          recommendedGifts: _recommendations.isNotEmpty ? _recommendations : null,
        ));
        
        if (_recommendations.isEmpty) {
          _currentQuestion = '${response.analysis}\n\n'
              '😅 죄송해요, "${response.searchQuery}" 검색 결과가 없네요.\n\n'
              '다른 키워드로 다시 검색해볼까요? 아래 버튼으로 처음부터 다시 시작하실 수 있어요.';
          _state = ChatState.finished;
        } else {
          _currentQuestion = response.analysis;
          _state = ChatState.finished;
        }
      } catch (e) {
        print('❌ 오류 발생: $e');
        _currentQuestion = '😢 죄송합니다. 추천 과정에서 오류가 발생했어요.\n\n'
            '오류 내용: ${e.toString()}\n\n'
            '다시 시도해주시거나, 질문을 조금 다르게 해주시면 도움이 될 것 같아요.';
        _state = ChatState.asking;
      } finally {
        notifyListeners();
      }
    } else {
      _currentQuestion = _questions[_currentStep].question;
      _currentQuestionType = _questions[_currentStep].type;
      _conversationHistory.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: _currentQuestion,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
      ));
      _state = ChatState.asking;
      notifyListeners();
    }
  }

  Future<void> refineRecommendations(bool isLiked) async {
    if (_recommendations.isEmpty) return;
    
    _state = ChatState.loading;
    notifyListeners();

    final firstGift = _recommendations.first;
    final feedback = isLiked
        ? '이 선물("${firstGift.name}")이 마음에 듭니다. 이것과 비슷하거나 관련된 다른 선물을 추천해주세요.'
        : '이 선물("${firstGift.name}")은 별로입니다. 완전히 다른 스타일의 선물을 추천해주세요.';

    _conversationHistory.add(ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: feedback,
      type: MessageType.user,
      timestamp: DateTime.now(),
    ));

    try {
      final response = await _aiService.getRecommendation(
        userInput: feedback,
        conversationHistory: _conversationHistory,
      );

      print('=== AI 재분석 결과 ===');
      print('분석: ${response.analysis}');
      print('검색어: ${response.searchQuery}');

      _recommendations = await _naverService.search(response.searchQuery);

      _conversationHistory.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response.analysis,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
        recommendedGifts: _recommendations.isNotEmpty ? _recommendations : null,
      ));

      if (_recommendations.isEmpty) {
        _currentQuestion = '${response.analysis}\n\n'
            '😅 아쉽게도 "${response.searchQuery}"에 대한 다른 상품을 찾지 못했어요.';
      } else {
        _currentQuestion = response.analysis;
      }
    } catch (e) {
      print('❌ 추천 구체화 중 오류 발생: $e');
      _currentQuestion = '😢 추천을 구체화하는 중 오류가 발생했어요.\n\n'
          '오류: ${e.toString()}';
    } finally {
      _state = ChatState.finished;
      notifyListeners();
    }
  }

  void restartConversation() {
    _startConversation();
  }
}