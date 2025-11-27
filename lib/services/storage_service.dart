// services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/gift_model.dart';
import '../models/chat_message.dart';

class StorageService {
  static const String _conversationKey = 'conversation_history';
  static const String _wishlistKey = 'wishlist';

  // 대화 히스토리 저장
  Future<void> saveConversation(List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = messages.map((msg) {
      final Map<String, dynamic> json = {
        'id': msg.id,
        'content': msg.content,
        'type': msg.type.toString(),
        'timestamp': msg.timestamp.toIso8601String(),
      };
      if (msg.recommendedGifts != null) {
        json['recommendedGifts'] = msg.recommendedGifts!.map((g) => g.toJson()).toList();
      }
      return json;
    }).toList();
    
    await prefs.setString(_conversationKey, jsonEncode(jsonList));
  }

  // 대화 히스토리 불러오기
  Future<List<ChatMessage>> loadConversation() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_conversationKey);
    
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) {
      final List<Gift>? gifts = json['recommendedGifts'] != null
          ? (json['recommendedGifts'] as List).map((g) => Gift.fromJson(g)).toList()
          : null;
      return ChatMessage(
        id: json['id'],
        content: json['content'],
        type: _parseMessageType(json['type']),
        timestamp: DateTime.parse(json['timestamp']),
        recommendedGifts: gifts,
      );
    }).toList();
  }

  // 대화 히스토리 삭제
  Future<void> clearConversation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_conversationKey);
  }

  // 위시리스트 저장
  Future<void> saveToWishlist(String giftId) async {
    final prefs = await SharedPreferences.getInstance();
    final wishlist = prefs.getStringList(_wishlistKey) ?? [];
    
    if (!wishlist.contains(giftId)) {
      wishlist.add(giftId);
      await prefs.setStringList(_wishlistKey, wishlist);
    }
  }

  // 위시리스트 조회
  Future<List<String>> getWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_wishlistKey) ?? [];
  }

  // 위시리스트에서 제거
  Future<void> removeFromWishlist(String giftId) async {
    final prefs = await SharedPreferences.getInstance();
    final wishlist = prefs.getStringList(_wishlistKey) ?? [];
    wishlist.remove(giftId);
    await prefs.setStringList(_wishlistKey, wishlist);
  }

  MessageType _parseMessageType(String typeString) {
    return MessageType.values.firstWhere(
      (type) => type.toString() == typeString,
      orElse: () => MessageType.user,
    );
  }

  // 사용자 설정 저장
  Future<void> saveUserPreference(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, value);
  }

  // 사용자 설정 불러오기
  Future<String?> getUserPreference(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(key);
  }
}