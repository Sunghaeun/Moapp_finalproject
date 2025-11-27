// providers/chat_provider.dart
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/gift_model.dart';
import '../services/openai_service.dart';
import '../services/naver_shopping_service.dart';

enum ChatState { asking, loading, finished }

class ChatProvider extends ChangeNotifier {
  final OpenAIService _aiService = OpenAIService();
  final NaverShoppingService _naverService = NaverShoppingService();

  ChatState _state = ChatState.asking;
  String _currentQuestion = '안녕하세요! 특별한 선물을 찾고 계신가요?\n\n누구에게 선물하실 건지 알려주세요.';
  final List<Map<String, String>> _answers = [];
  List<Gift> _recommendations = [];
  int _currentStep = 0;

  final List<String> _questions = [
    '누구에게 선물하실 건지 알려주세요. (예: 20대 여자친구)',
    '선물 가격대는 어느 정도로 생각하세요? (예: 5만원 이하)',
    '어떤 특별한 날을 위한 선물인가요? (예: 생일, 1주년, 크리스마스)',
    '선물 받으실 분의 취미나 요즘 관심사는 무엇인가요? (예: 운동, 독서, 게임)',
  ];

  ChatState get state => _state;
  String get currentQuestion => _currentQuestion;
  List<Gift> get recommendations => _recommendations;

  ChatProvider() {
    _startConversation();
  }

  void _startConversation() {
    _state = ChatState.asking;
    _currentStep = 0;
    _currentQuestion = _questions[_currentStep];
    _answers.clear();
    _recommendations.clear();
    notifyListeners();
  }

  Future<void> sendAnswer(String answer) async {
    // 현재 단계의 질문과 답변을 저장
    _answers.add({'question': _questions[_currentStep], 'answer': answer});
    _currentStep++;

    // 모든 질문이 끝났는지 확인
    if (_currentStep >= _questions.length) {
      // 모든 정보가 모였으므로 AI에게 추천 요청
      _state = ChatState.loading;
      notifyListeners();

      try {
        // 수집된 답변들을 하나의 문자열로 합쳐서 AI에게 전달
        final fullContext = _answers.map((qa) => "${qa['question']}\n답변: ${qa['answer']}").join('\n\n');
        
        final response = await _aiService.getRecommendation(
          userInput: fullContext,
          conversationHistory: [], // 단계별 질문에서는 이전 히스토리가 필요 없음
        );

        // 2. AI가 만든 검색어로 네이버 쇼핑 API 검색
        _recommendations = await _naverService.search(response.searchQuery);
        
        _currentQuestion = response.analysis;
        _state = ChatState.finished;
      } catch (e) {
        _currentQuestion = '죄송합니다. 추천 과정에서 오류가 발생했어요.\n\n$e';
        _state = ChatState.asking; // 오류 후 다시 시작할 수 있도록 _startConversation() 호출도 가능
      } finally {
        notifyListeners();
      }
    } else {
      // 다음 질문으로 이동
      _currentQuestion = _questions[_currentStep];
      _state = ChatState.asking; // 오류 후 다시 질문할 수 있도록
      notifyListeners();
    }
  }

  // 대화 다시 시작
  void restartConversation() {
    _startConversation();
  }
}