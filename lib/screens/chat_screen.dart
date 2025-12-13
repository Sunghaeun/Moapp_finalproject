// lib/screens/chat_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/chat_message.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';

class ImprovedChatScreen extends StatefulWidget {
  final String? initialPrompt;

  const ImprovedChatScreen({super.key, this.initialPrompt});

  @override
  State<ImprovedChatScreen> createState() => _ImprovedChatScreenState();
}

class _ImprovedChatScreenState extends State<ImprovedChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      if (widget.initialPrompt != null && widget.initialPrompt!.isNotEmpty) {
        chatProvider.startWithPrompt(widget.initialPrompt!);
      } else {
        chatProvider.startConversation();
      }
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
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

  void _handleTextMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    chatProvider.handleTextMessage(text);
    _messageController.clear();
    _scrollToBottom();
  }

  Widget _buildQuickReplyButtons(ChatProvider chatProvider) {
    List<dynamic> options = [];
    
    switch (chatProvider.conversationStep) {
      case 0:
        options = chatProvider.relationshipOptions;
        break;
      case 1:
        options = chatProvider.ageOptions;
        break;
      case 2:
        options = chatProvider.priceOptions;
        break;
      case 3:
        options = chatProvider.styleOptions;
        break;
      default:
        return const SizedBox.shrink();
    }

    String category = '';
    switch (chatProvider.conversationStep) {
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
                onPressed: () {
                  chatProvider.handleUserChoice(
                    option['label'] as String, 
                    category,
                    priceData: option,
                  );
                  _scrollToBottom();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  option['label'],
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
                onPressed: () {
                  chatProvider.handleUserChoice(option, category);
                  _scrollToBottom();
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey[300]!),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  option,
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

  Widget _buildFeedbackButtons(ChatProvider chatProvider) {
    if (chatProvider.conversationStep <= 3 || chatProvider.messages.isEmpty) {
      return const SizedBox.shrink();
    }
    
    final hasRecommendations = chatProvider.messages.any((msg) => 
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
                  onPressed: () {
                    chatProvider.handleFeedback('좋아요');
                    _scrollToBottom();
                  },
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
                  onPressed: () {
                    chatProvider.handleFeedback('별로예요');
                    _scrollToBottom();
                  },
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
                  onPressed: () {
                    chatProvider.handleFeedback('다시 답변요청');
                    _scrollToBottom();
                  },
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
              _buildSuggestionButton('다른 선물 추천 받기', chatProvider),
              const SizedBox(height: 8),
              _buildSuggestionButton('요즘 트렌디한 선물', chatProvider),
              const SizedBox(height: 8),
              _buildSuggestionButton('지금거보다 가격이 더 싼 선물', chatProvider),
              const SizedBox(height: 8),
              _buildSuggestionButton('주는 사람도 만족스러운 선물', chatProvider),
              const SizedBox(height: 8),
              _buildSuggestionButton('비슷하지만 3만원 이하 선물', chatProvider),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionButton(String label, ChatProvider chatProvider) {
    return OutlinedButton(
      onPressed: () {
        chatProvider.handleSuggestionClick(label);
        _scrollToBottom();
      },
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


  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        // 메시지가 추가될 때마다 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom();
        });

        return Scaffold(
          appBar: AppBar(
            title: const Text('AI 선물 추천'),
            backgroundColor: Colors.transparent,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.restart_alt),
                onPressed: () {
                  chatProvider.resetConversation();
                },
                tooltip: '처음부터 다시',
              ),
            ],
          ),
          body: Column(
            children: [
              if (chatProvider.conversationStep > 0 && chatProvider.conversationStep <= 4)
                LinearProgressIndicator(
                  value: chatProvider.conversationStep / 4,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Theme.of(context).colorScheme.primary,
                  ),
                ),
              
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: chatProvider.messages.length + 1,
                  itemBuilder: (context, index) {
                    if (index < chatProvider.messages.length) {
                      return ChatBubble(message: chatProvider.messages[index]);
                    }

                    if (chatProvider.isTyping) {
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
                    if (chatProvider.conversationStep <= 3) {
                      return _buildQuickReplyButtons(chatProvider);
                    }
                    return _buildFeedbackButtons(chatProvider);
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
                          hintText: chatProvider.getPlaceholder(),
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
      },
    );
  }
}