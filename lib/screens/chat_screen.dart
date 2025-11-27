import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import '../providers/chat_provider.dart';
import '../widgets/gift_card.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final chatProvider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.red[700],
        title: const Text('선물 추천 AI'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ChatProvider>().restartConversation();
            },
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: _buildBody(chatProvider),
              ),
              if (chatProvider.state == ChatState.asking) _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(ChatProvider provider) {
    switch (provider.state) {
      case ChatState.loading:
        return _buildCharacterView('생각 중...', isLoading: true);
      case ChatState.finished:
        return _buildFinishedView(provider);
      case ChatState.asking:
      default:
        return _buildCharacterView(provider.currentQuestion);
    }
  }

  Widget _buildCharacterView(String message, {bool isLoading = false}) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Lottie 애니메이션을 사용합니다. assets/snowman.json 파일이 필요합니다.
        // 파일이 없다면 Image.asset 등으로 대체할 수 있습니다.
        SizedBox(
          height: 200,
          child: isLoading
              ? Lottie.asset('assets/animations/snowman_thinking.json')
              : Lottie.asset('assets/animations/snowman_talking.json'),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildFinishedView(ChatProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          provider.currentQuestion, // 최종 분석 내용
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          '이런 선물들은 어떠세요? 🎁',
          style: TextStyle(fontSize: 16, color: Colors.black54),
        ),
        const Divider(height: 24),
        Expanded(
          child: ListView.builder(
            itemCount: provider.recommendations.length,
            itemBuilder: (context, index) {
              return GiftCard(gift: provider.recommendations[index]);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildInputArea() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: '답변을 입력하세요...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.grey[400]!),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide(color: Colors.red[700]!, width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
              ),
              onSubmitted: (_) => _sendAnswer(),
            ),
          ),
          const SizedBox(width: 8),
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.red[700],
            child: IconButton(
              icon: const Icon(Icons.send, color: Colors.white),
              onPressed: _sendAnswer,
            ),
          ),
        ],
      ),
    );
  }

  void _sendAnswer() {
    if (_controller.text.trim().isEmpty) return;
    final content = _controller.text;
    _controller.clear();
    context.read<ChatProvider>().sendAnswer(content);
  }
}