// services/storage_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/gift_model.dart';
import '../models/chat_message.dart';

class StorageService {
  static const String _conversationKey = 'conversation_history';
  static const String _wishlistKey = 'wishlist';
  static const String _cartKey = 'shopping_cart'; // 새로운 장바구니 키

  // ========== 장바구니 기능 ==========
  
  // 장바구니에 추가
  Future<void> addToCart(Gift gift) async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);
    
    List<Map<String, dynamic>> cart = [];
    if (cartJson != null) {
      cart = List<Map<String, dynamic>>.from(jsonDecode(cartJson));
    }
    
    // 중복 체크
    if (!cart.any((item) => item['id'] == gift.id)) {
      cart.add(gift.toJson());
      await prefs.setString(_cartKey, jsonEncode(cart));
    }
  }

  // 장바구니에서 제거
  Future<void> removeFromCart(String giftId) async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);
    
    if (cartJson != null) {
      List<Map<String, dynamic>> cart = List<Map<String, dynamic>>.from(jsonDecode(cartJson));
      cart.removeWhere((item) => item['id'] == giftId);
      await prefs.setString(_cartKey, jsonEncode(cart));
    }
  }

  // 장바구니 아이템 가져오기
  Future<List<Gift>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);
    
    if (cartJson == null) return [];
    
    List<Map<String, dynamic>> cart = List<Map<String, dynamic>>.from(jsonDecode(cartJson));
    return cart.map((json) => Gift.fromJson(json)).toList();
  }

  // 장바구니에 있는지 확인
  Future<bool> isInCart(String giftId) async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(_cartKey);
    
    if (cartJson == null) return false;
    
    List<Map<String, dynamic>> cart = List<Map<String, dynamic>>.from(jsonDecode(cartJson));
    return cart.any((item) => item['id'] == giftId);
  }

  // 장바구니 비우기
  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }

  // 장바구니 아이템 개수
  Future<int> getCartCount() async {
    final items = await getCartItems();
    return items.length;
  }

  // ========== 기존 대화 히스토리 기능 ==========
  
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

  // ========== 위시리스트 기능 ==========
  
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