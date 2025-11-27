// models/chat_message.dart
import 'gift_model.dart';

enum MessageType { user, assistant }

class ChatMessage {
  final String id;
  final String content;
  final MessageType type;
  final DateTime timestamp;
  final List<Gift>? recommendedGifts;

  ChatMessage({
    required this.id,
    required this.content,
    required this.type,
    required this.timestamp,
    this.recommendedGifts,
  });
}