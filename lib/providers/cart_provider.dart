// lib/providers/cart_provider.dart
import 'package:flutter/foundation.dart';
import '../models/cart_item.dart';
import '../models/gift_model.dart';
import '../services/cart_service.dart';

class CartProvider extends ChangeNotifier {
  final CartService _cartService = CartService();
  
  List<CartItem> _items = [];
  bool _isLoading = false;
  String? _error;

  List<CartItem> get items => _items;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  // 장바구니 아이템 개수
  int get itemCount => _items.length;
  
  // 총 가격
  int get totalPrice => _items.fold<int>(
    0,
    (sum, item) => sum + item.price,
  );

  CartProvider() {
    _loadCartItems();
  }

  // 장바구니 아이템 로드
  void _loadCartItems() {
    _cartService.getCartItems().listen(
      (items) {
        _items = items;
        _error = null;
        notifyListeners();
      },
      onError: (error) {
        _error = error.toString();
        notifyListeners();
      },
    );
  }

  // 장바구니에 추가
  Future<bool> addToCart(Gift gift) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      final success = await _cartService.addToCart(gift);
      
      if (success) {
        // _loadCartItems()가 자동으로 업데이트하므로 여기서는 로딩만 해제
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false; // 이미 장바구니에 있음
      }
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // 장바구니에서 삭제
  Future<void> removeFromCart(String itemId) async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _cartService.removeFromCart(itemId);
      
      // _loadCartItems()가 자동으로 업데이트하므로 여기서는 로딩만 해제
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // 장바구니 비우기
  Future<void> clearCart() async {
    try {
      _isLoading = true;
      notifyListeners();
      
      await _cartService.clearCart();
      
      // _loadCartItems()가 자동으로 업데이트하므로 여기서는 로딩만 해제
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // 장바구니에 있는지 확인
  Future<bool> isInCart(String productId) async {
    try {
      return await _cartService.isInCart(productId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // 장바구니 개수 조회
  Future<int> getCartCount() async {
    try {
      return await _cartService.getCartCount();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0;
    }
  }
}
