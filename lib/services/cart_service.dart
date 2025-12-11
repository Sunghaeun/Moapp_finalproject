// lib/services/cart_service.dart
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/gift_model.dart';

class CartService {
  static const String _cartKey = 'shopping_cart';
  
  // 장바구니에 추가
  Future<void> addToCart(Gift gift) async {
    final prefs = await SharedPreferences.getInstance();
    final cartItems = await getCartItems();
    
    // 이미 있는지 확인
    final exists = cartItems.any((item) => item.id == gift.id);
    if (!exists) {
      cartItems.add(gift);
      await _saveCart(cartItems);
    }
  }
  
  // 장바구니에서 제거
  Future<void> removeFromCart(String giftId) async {
    final cartItems = await getCartItems();
    cartItems.removeWhere((item) => item.id == giftId);
    await _saveCart(cartItems);
  }
  
  // 장바구니 비우기
  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cartKey);
  }
  
  // 장바구니 아이템 가져오기
  Future<List<Gift>> getCartItems() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_cartKey);
    
    if (jsonString == null) return [];
    
    final jsonList = jsonDecode(jsonString) as List;
    return jsonList.map((json) => Gift.fromJson(json)).toList();
  }
  
  // 장바구니에 있는지 확인
  Future<bool> isInCart(String giftId) async {
    final cartItems = await getCartItems();
    return cartItems.any((item) => item.id == giftId);
  }
  
  // 장바구니 아이템 개수
  Future<int> getCartCount() async {
    final cartItems = await getCartItems();
    return cartItems.length;
  }
  
  // 장바구니 총 금액
  Future<int> getTotalPrice() async {
    final cartItems = await getCartItems();
    int total = 0;
    for (var item in cartItems) {
      total += item.price;
    }
    return total;
  }
  
  // 내부: 장바구니 저장
  Future<void> _saveCart(List<Gift> items) async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = items.map((gift) => gift.toJson()).toList();
    await prefs.setString(_cartKey, jsonEncode(jsonList));
  }
}