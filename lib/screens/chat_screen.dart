import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/typing_indicator.dart';
import '../models/chat_message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // 화면이 빌드된 후 스크롤을 맨 아래로 이동합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  @override
  Widget build(BuildContext context) {
    // ChatProvider를 사용하여 상태를 감시합니다.
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('선물 추천 AI'),
        backgroundColor: Colors.red[700],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: chatProvider.messages.length,
              itemBuilder: (context, index) {
                return ChatBubble(message: chatProvider.messages[index]);
              },
            ),
          ),
          if (chatProvider.isLoading)
            const Padding( // This was the error, but since TypingIndicator is not const, we remove it.
              padding: EdgeInsets.all(8),
              child: TypingIndicator(),
            ),
          _buildFollowupQuestions(chatProvider),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildFollowupQuestions(ChatProvider chatProvider) {
    // 로딩 중이 아니거나 후속 질문이 있을 때만 버튼들을 보여줍니다.
    if (chatProvider.isLoading || chatProvider.followupQuestions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8.0,
        runSpacing: 8.0,
        children: chatProvider.followupQuestions.map((question) {
          return ActionChip(
            label: Text(question),
            onPressed: () {
              _sendFollowupQuestion(question);
            },
            backgroundColor: Colors.red[50],
            labelStyle: TextStyle(color: Colors.red[800]),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16.0),
              side: BorderSide(color: Colors.red[100]!),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _sendFollowupQuestion(String question) {
    // 텍스트 필드에 질문을 채우고 바로 전송합니다.
    _controller.text = question;
    _sendMessage();
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            offset: const Offset(0, -2),
            blurRadius: 4,
            color: Colors.black12,
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '20대 여자친구에게 줄 3만원대 크리스마스 선물 추천해줘',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            backgroundColor: Colors.red[700],
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: context.watch<ChatProvider>().isLoading ? null : _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
  
  Future<void> _sendMessage() async {
    if (_controller.text.trim().isEmpty) return;
    
    final content = _controller.text;
    _controller.clear();
    
    // Provider를 통해 메시지 전송
    // UI 업데이트는 Provider가 알아서 처리합니다.
    await context.read<ChatProvider>().sendMessage(content);
    
    _scrollToBottom(); // 메시지 전송 후 스크롤
  }

  void _scrollToBottom() {
    // Provider가 상태를 업데이트하고 위젯이 리빌드된 후에 스크롤합니다.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }
}