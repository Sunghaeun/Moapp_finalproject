import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/chat_provider.dart';
import '../widgets/gift_card.dart';
import '../widgets/feedback_buttons.dart';
import '../widgets/chat_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showConversationView = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 300), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🎄 AI 선물 추천',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.red[700],
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (chatProvider.conversationHistory.length > 2)
            IconButton(
              icon: Icon(
                _showConversationView ? Icons.view_agenda : Icons.chat_bubble_outline,
                color: Colors.white,
              ),
              tooltip: _showConversationView ? '결과 화면으로' : '대화 내역 보기',
              onPressed: () {
                setState(() {
                  _showConversationView = !_showConversationView;
                });
                if (_showConversationView) {
                  _scrollToBottom();
                }
              },
            ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: '처음부터 다시',
            onPressed: () {
              setState(() {
                _showConversationView = false;
              });
              context.read<ChatProvider>().restartConversation();
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _showConversationView 
                    ? _buildConversationView(chatProvider)
                    : _buildBody(chatProvider),
              ),
            ),
            // 텍스트 입력 질문일 때만 입력창 표시
            if (chatProvider.state == ChatState.asking && chatProvider.currentQuestionType == QuestionType.text)
              _buildInputArea(chatProvider)
            else if (chatProvider.state == ChatState.finished && 
                     chatProvider.recommendations.isNotEmpty &&
                     !_showConversationView)
              FeedbackButtons(
                onLike: () {
                  context.read<ChatProvider>().refineRecommendations(true);
                },
                onDislike: () {
                  context.read<ChatProvider>().refineRecommendations(false);
                },
                onRestart: () {
                  setState(() {
                    _showConversationView = false;
                  });
                  context.read<ChatProvider>().restartConversation();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationView(ChatProvider provider) {
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.history, color: Colors.blue[700], size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  '전체 대화 내역',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: provider.conversationHistory.length,
            itemBuilder: (context, index) {
              final message = provider.conversationHistory[index];
              return ChatBubble(message: message);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBody(ChatProvider provider) {
    switch (provider.state) {
      case ChatState.loading:
        return _buildLoadingView();
      case ChatState.finished:
        return _buildFinishedView(provider);
      case ChatState.asking:
      default:
        return _buildAskingView(provider);
    }
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 200,
            child: Lottie.asset(
              'assets/animations/snowman_thinking.json',
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.card_giftcard,
                  size: 100,
                  color: Colors.red,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              children: [
                Text(
                  '🎁 선물을 찾는 중...',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                CircularProgressIndicator(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAskingView(ChatProvider provider) {
    final questionData = provider.currentQuestionData;

    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 200,
            child: Lottie.asset(
              'assets/animations/snowman_talking.json',
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.card_giftcard,
                  size: 100,
                  color: Colors.red,
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              provider.currentQuestion,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, height: 1.5),
            ),
          ),
          // 선택형 질문인 경우 선택지 표시
          if (provider.currentQuestionType == QuestionType.selection && questionData.choices != null) ...[
            const SizedBox(height: 24),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: questionData.choices!.map((choice) {
                return ElevatedButton(
                  onPressed: () {
                    context.read<ChatProvider>().sendAnswer(choice.value);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black87,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey[300]!),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  ),
                  child: Column(
                    children: [
                      if (choice.emoji != null) ...[
                        Text(choice.emoji!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(height: 4),
                      ],
                      Text(choice.label, style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
          const SizedBox(height: 24), // 하단 여백
        ],
      ),
    );
  }

  Widget _buildFinishedView(ChatProvider provider) {
    if (provider.recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                provider.currentQuestion,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _showConversationView = false;
                });
                context.read<ChatProvider>().restartConversation();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('처음부터 다시 시작'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.auto_awesome, color: Colors.blue[700]),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  provider.currentQuestion,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.blue[900],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            const Text(
              '추천 선물 목록',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.red[700],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${provider.recommendations.length}개',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Spacer(),
            TextButton.icon(
              onPressed: () {
                setState(() {
                  _showConversationView = true;
                });
                _scrollToBottom();
              },
              icon: const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('대화 내역', style: TextStyle(fontSize: 14)),
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: provider.recommendations.length,
            itemBuilder: (context, index) {
              final gift = provider.recommendations[index];
              return GiftCard(gift: gift);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea(ChatProvider chatProvider) {
    // 텍스트 입력형 질문
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: '답변을 입력하세요...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: Colors.red[700]!, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.grey[50],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                onSubmitted: (_) => _sendTextAnswer(),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.red[700],
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white, size: 20),
                onPressed: _sendTextAnswer,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _sendTextAnswer() {
    if (_controller.text.trim().isEmpty) return;
    final content = _controller.text;
    _controller.clear();
    context.read<ChatProvider>().sendAnswer(content);
  }
}