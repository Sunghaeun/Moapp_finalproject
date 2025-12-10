// lib/screens/improved_chat_screen.dart
import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../models/gift_model.dart';
import '../services/openai_service.dart';
import '../services/naver_shopping_service.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../widgets/gift_card.dart';

class ImprovedChatScreen extends StatefulWidget {
  const ImprovedChatScreen({super.key});

  @override
  State<ImprovedChatScreen> createState() => _ImprovedChatScreenState();
}

class _ImprovedChatScreenState extends State<ImprovedChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final OpenAIService _aiService = OpenAIService();
  final NaverShoppingService _naverService = NaverShoppingService();
  
  final List<ChatMessage> _messages = [];
  bool _isTyping = false;
  
  // 대화 단계
  int _conversationStep = 0;
  final Map<String, String> _userPreferences = {};
  
  // 추천 옵션 (이모티콘 제거, 깔끔하게)
  final List<String> _relationshipOptions = [
    '부모님',
    '연인',
    '친구',
    '직장 동료',
    '선생님/교수님'
  ];
  
  final List<String> _ageOptions = [
    '10대',
    '20대',
    '30대',
    '40대',
    '50대 이상'
  ];
  
  final List<Map<String, dynamic>> _priceOptions = [
    {'label': '2만원 이하', 'min': 0, 'max': 20000},
    {'label': '2-5만원', 'min': 20000, 'max': 50000},
    {'label': '5-10만원', 'min': 50000, 'max': 100000},
    {'label': '10만원 이상', 'min': 100000, 'max': 999999},
  ];
  
  final List<String> _styleOptions = [
    '실용적인',
    '트렌디한',
    '고급스러운',
    '재미있는',
    '감성적인'
  ];

  String _getPlaceholder() {
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

  @override
  void initState() {
    super.initState();
    _startConversation();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _startConversation() {
    Future.delayed(const Duration(milliseconds: 500), () {
      _addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '안녕하세요!\n완벽한 크리스마스 선물을 찾도록 도와드릴게요.\n\n누구에게 선물하실 건가요?',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
        ),
      );
    });
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _handleUserChoice(String choice, String category, {Map<String, dynamic>? priceData}) async {
    // 사용자 선택 저장
    _userPreferences[category] = choice;
    
    // 가격대 정보 저장
    if (priceData != null) {
      _userPreferences['price_min'] = priceData['min'].toString();
      _userPreferences['price_max'] = priceData['max'].toString();
    }
    
    // 사용자 메시지 추가
    _addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: choice,
        type: MessageType.user,
        timestamp: DateTime.now(),
      ),
    );

    setState(() {
      _isTyping = true;
      _conversationStep++;
    });

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
        await _generateRecommendations();
        return;
    }

    setState(() {
      _isTyping = false;
    });

    _addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: nextQuestion,
        type: MessageType.assistant,
        timestamp: DateTime.now(),
      ),
    );
  }

  Future<void> _generateRecommendations() async {
    _addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: '완벽한 선물을 찾고 있어요...',
        type: MessageType.assistant,
        timestamp: DateTime.now(),
      ),
    );

    try {
      final prompt = _buildPromptFromPreferences();
      final response = await _aiService.getRecommendation(
        userInput: prompt,
        conversationHistory: _messages,
      );

      // 가격대 필터링을 위한 정보 가져오기
      final minPrice = int.tryParse(_userPreferences['price_min'] ?? '0') ?? 0;
      final maxPrice = int.tryParse(_userPreferences['price_max'] ?? '999999') ?? 999999;

      final List<Gift> recommendedGifts = [];
      for (final query in response.searchQueries) {
        final gifts = await _naverService.search(query, display: 10);
        
        // 가격대에 맞는 상품 필터링
        final filteredGifts = gifts.where((gift) {
          return gift.price >= minPrice && gift.price <= maxPrice;
        }).toList();
        
        if (filteredGifts.isNotEmpty) {
          recommendedGifts.add(filteredGifts.first);
        } else if (gifts.isNotEmpty) {
          // 필터링 결과가 없으면 가장 가까운 가격의 상품 선택
          gifts.sort((a, b) {
            final aDiff = (a.price - (minPrice + maxPrice) / 2).abs();
            final bDiff = (b.price - (minPrice + maxPrice) / 2).abs();
            return aDiff.compareTo(bDiff);
          });
          recommendedGifts.add(gifts.first);
        }
      }

      setState(() {
        _isTyping = false;
      });

      if (recommendedGifts.isEmpty) {
        _addMessage(
          ChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: '죄송해요, 조건에 맞는 선물을 찾지 못했습니다.\n다른 조건으로 다시 시도해볼까요?',
            type: MessageType.assistant,
            timestamp: DateTime.now(),
          ),
        );
        return;
      }

      _addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '${response.analysis}\n\n이런 선물들을 추천드려요',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
          recommendedGifts: recommendedGifts,
        ),
      );

    } catch (e) {
      setState(() {
        _isTyping = false;
      });
      
      _addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '죄송해요, 선물 추천 중 오류가 발생했습니다.\n다시 시도해주세요.',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

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

  void _handleTextMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: text,
        type: MessageType.user,
        timestamp: DateTime.now(),
      ),
    );

    _messageController.clear();
    _handleFreeTextInput(text);
  }

  Future<void> _handleFreeTextInput(String text) async {
    setState(() {
      _isTyping = true;
    });

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

      setState(() {
        _isTyping = false;
      });

      _addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: response.analysis,
          type: MessageType.assistant,
          timestamp: DateTime.now(),
          recommendedGifts: recommendedGifts,
        ),
      );

    } catch (e) {
      setState(() {
        _isTyping = false;
      });
      
      _addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '죄송해요, 이해하지 못했어요. 다시 말씀해주시겠어요?',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  Widget _buildQuickReplyButtons() {
    List<dynamic> options = [];
    
    switch (_conversationStep) {
      case 0:
        options = _relationshipOptions;
        break;
      case 1:
        options = _ageOptions;
        break;
      case 2:
        options = _priceOptions;
        break;
      case 3:
        options = _styleOptions;
        break;
      default:
        return const SizedBox.shrink();
    }

    String category = '';
    switch (_conversationStep) {
      case 0:
        category = 'relationship';
        break;
      case 1:
        category = 'age';
        break;
      case 2:
        category = 'price';
        break;
      case 3:
        category = 'style';
        break;
    }

    // 세로 그리드 레이아웃으로 변경 (가로 스크롤 제거)
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: options.map((option) {
          if (option is Map<String, dynamic>) {
            // 가격대 옵션
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => _handleUserChoice(
                  option['label'] as String, 
                  category,
                  priceData: option,
                ),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  option['label'] as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          } else {
            // 일반 옵션
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: OutlinedButton(
                onPressed: () => _handleUserChoice(option as String, category),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  option as String,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }
        }).toList(),
      ),
    );
  }

  Widget _buildFeedbackButtons() {
    if (_conversationStep <= 3 || _messages.isEmpty) return const SizedBox.shrink();
    
    final hasRecommendations = _messages.any((msg) => 
      msg.type == MessageType.assistant && 
      msg.recommendedGifts != null && 
      msg.recommendedGifts!.isNotEmpty
    );
    
    if (!hasRecommendations) {
      return const SizedBox.shrink();
    }
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border(
          top: BorderSide(color: Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '답변이 마음에 드시나요?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleFeedback('좋아요'),
                  icon: const Icon(Icons.thumb_up_outlined, size: 18),
                  label: const Text('좋아요'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleFeedback('별로예요'),
                  icon: const Icon(Icons.thumb_down_outlined, size: 18),
                  label: const Text('별로예요'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleFeedback('다시 답변요청'),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('다시'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: BorderSide(color: Colors.grey[300]!),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            '다음 대화로 이런건 어떠세요?',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          // 세로 레이아웃으로 변경
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSuggestionButton('다른 선물 추천 받기'),
              const SizedBox(height: 8),
              _buildSuggestionButton('요즘 트렌디한 선물'),
              const SizedBox(height: 8),
              _buildSuggestionButton('지금거보다 가격이 더 싼 선물'),
              const SizedBox(height: 8),
              _buildSuggestionButton('주는 사람도 만족스러운 선물'),
              const SizedBox(height: 8),
              _buildSuggestionButton('비슷하지만 3만원 이하 선물'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionButton(String label) {
    return OutlinedButton(
      onPressed: () => _handleSuggestionClick(label),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 14),
        side: BorderSide(color: Colors.grey[300]!),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Future<void> _handleFeedback(String feedback) async {
    _addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: feedback,
        type: MessageType.user,
        timestamp: DateTime.now(),
      ),
    );

    if (feedback == '다시 답변요청') {
      await _generateRecommendations();
    } else if (feedback == '좋아요') {
      _addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '좋아해주셔서 감사합니다!\n다른 도움이 필요하시면 말씀해주세요.',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
        ),
      );
    } else if (feedback == '별로예요') {
      _addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '아쉽네요. 더 나은 선물을 찾아드릴게요!',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 500));
      await _generateRecommendations();
    }
  }

  Future<void> _handleSuggestionClick(String suggestion) async {
    _addMessage(
      ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        content: suggestion,
        type: MessageType.user,
        timestamp: DateTime.now(),
      ),
    );

    setState(() {
      _isTyping = true;
    });

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
        // 3만원 이하로 가격대 재설정
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

      setState(() {
        _isTyping = false;
      });

      _addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '${response.analysis}\n\n이런 선물들을 추천드려요',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
          recommendedGifts: recommendedGifts,
        ),
      );

    } catch (e) {
      setState(() {
        _isTyping = false;
      });
      
      _addMessage(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: '죄송해요, 선물 추천 중 오류가 발생했습니다.',
          type: MessageType.assistant,
          timestamp: DateTime.now(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 선물 추천'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.restart_alt),
            onPressed: () {
              setState(() {
                _conversationStep = 0;
                _userPreferences.clear();
                _messages.clear();
              });
              _startConversation();
            },
            tooltip: '처음부터 다시',
          ),
        ],
      ),
      body: Column(
        children: [
          if (_conversationStep > 0 && _conversationStep <= 4)
            LinearProgressIndicator(
              value: _conversationStep / 4,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          
          Expanded(
              child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + 1, // 추가 항목(버튼 또는 타이핑)을 위한 공간
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return ChatBubble(message: _messages[index]);
                }

                // 마지막 항목
                if (_isTyping) {
                  return Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.centerLeft,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const TypingIndicator(),
                    ),
                  );
                }
                if (_conversationStep <= 3) {
                  return _buildQuickReplyButtons();
                }
                return _buildFeedbackButtons();
              },
            
            
            ),
      ),
          
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: _getPlaceholder(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                    textInputAction: TextInputAction.send,
                    onSubmitted: (_) => _handleTextMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _handleTextMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}