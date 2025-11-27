// providers/chat_provider.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/gift_model.dart';
import '../services/openai_service.dart'; // 변경!
import '../services/storage_service.dart';

class ChatProvider extends ChangeNotifier {
  final OpenAIService _aiService = OpenAIService(); // 변경!
  final StorageService _storageService = StorageService();
  
  List<ChatMessage> _messages = [];
  bool _isLoading = false;
  List<String> _followupQuestions = [];

  List<ChatMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  List<String> get followupQuestions => _followupQuestions;

  ChatProvider() {
    _loadConversation();
  }

  Future<void> _loadConversation() async {
    try {
      _messages = await _storageService.loadConversation();
      notifyListeners();
    } catch (e) {
      print('대화 로드 실패: $e');
    }
  }

  Future<void> sendMessage(String content) async {
    final userMessage = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      content: content,
      type: MessageType.user,
      timestamp: DateTime.now(),
    );

    _messages.add(userMessage);
    _isLoading = true;
    _followupQuestions.clear();
    notifyListeners();

    try {
      print('=== 메시지 전송: $content ===');
      
      final response = await _aiService.getRecommendation(
        userInput: content,
        conversationHistory: _messages,
      );

      print('✅ 추천 받음: ${response.recommendations.length}개');

      final List<Gift> recommendedGifts = response.recommendations.map((rec) {
        return Gift(
          id: DateTime.now().millisecondsSinceEpoch.toString() + rec.name.hashCode.toString(),
          name: rec.name,
          description: rec.reason,
          price: rec.price,
          imageUrl: 'https://via.placeholder.com/150?text=${Uri.encodeComponent(rec.name)}',
          category: '추천',
          tags: rec.alternatives.isEmpty ? ['추천'] : rec.alternatives.take(3).toList(),
          purchaseLink: rec.link ?? 'https://www.google.com/search?q=${Uri.encodeComponent(rec.name + " 구매")}',
        );
      }).toList();

      final assistantMessage = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: response.analysis,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
        recommendedGifts: recommendedGifts.isEmpty ? null : recommendedGifts,
      );

      _messages.add(assistantMessage);
      _followupQuestions = response.followupQuestions;

      await _storageService.saveConversation(_messages);
      print('✅ 완료!');

    } catch (e, stackTrace) {
      print('❌ 오류: $e');
      print('스택: $stackTrace');
      
      // 에러 유형별 친절한 메시지
      String errorMessage;
      
      if (e.toString().contains('API 키')) {
        errorMessage = '''
⚠️ **API 키 오류**

OpenAI API 키가 올바르게 설정되지 않았습니다.

**해결 방법:**
1. .env 파일을 열어주세요
2. OPENAI_API_KEY=sk-proj-... 형식으로 키를 입력하세요
3. 앱을 재시작해주세요

API 키는 https://platform.openai.com/api-keys 에서 발급받을 수 있습니다.
''';
      } else if (e.toString().contains('크레딧')) {
        errorMessage = '''
⚠️ **크레딧 부족**

OpenAI 계정의 크레딧이 부족합니다.

**해결 방법:**
1. https://platform.openai.com/account/billing 접속
2. 크레딧 충전 (부터 가능)

💡 신규 가입 시  무료 크레딧이 제공됩니다!
''';
      } else if (e.toString().contains('429') || e.toString().contains('한도')) {
        errorMessage = '''
⚠️ **요청 한도 초과**

잠시 너무 많은 요청을 보냈습니다.

1분 후에 다시 시도해주세요! ☕
''';
      } else {
        errorMessage = '죄송합니다. 오류가 발생했습니다.\n\n${e.toString()}\n\n다시 시도해주세요.';
      }
      
      _messages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: errorMessage,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> clearChat() async {
    _messages.clear();
    _followupQuestions.clear();
    await _storageService.clearConversation();
    notifyListeners();
  }
}