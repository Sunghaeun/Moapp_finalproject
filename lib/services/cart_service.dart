// lib/services/cart_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/cart_item.dart';
import '../models/gift_model.dart';

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _userId => _auth.currentUser?.uid ?? 'guest';

  // 장바구니 컬렉션 참조
  CollectionReference get _cartCollection => 
      _firestore.collection('carts').doc(_userId).collection('items');

  // 장바구니에 추가
  Future<bool> addToCart(Gift gift) async {
    try {
      // id를 productId로 사용
      final existingItem = await _cartCollection
          .where('productId', isEqualTo: gift.id)
          .get();

      if (existingItem.docs.isNotEmpty) {
        return false; // 이미 장바구니에 있음
      }

      final cartItem = CartItem(
        id: '',
        userId: _userId,
        productId: gift.id,  // id 사용
        title: gift.name,    // name 사용
        imageUrl: gift.imageUrl,
        price: gift.price,
        link: gift.purchaseLink,  // purchaseLink 사용
        addedAt: DateTime.now(),
      );

      await _cartCollection.add(cartItem.toMap());
      return true;
    } catch (e) {
      print('장바구니 추가 오류: $e');
      return false;
    }
  }

  // 장바구니 아이템 삭제
  Future<void> removeFromCart(String itemId) async {
    try {
      await _cartCollection.doc(itemId).delete();
    } catch (e) {
      print('장바구니 삭제 오류: $e');
    }
  }

  // 장바구니 전체 조회
  Stream<List<CartItem>> getCartItems() {
    return _cartCollection
        .orderBy('addedAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => CartItem.fromMap(doc.id, doc.data() as Map<String, dynamic>))
            .toList());
  }

  // 장바구니 전체 조회 (1회성)
  Future<List<CartItem>> getCartItemsOnce() async {
    final snapshot = await _cartCollection
        .orderBy('addedAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => CartItem.fromMap(doc.id, doc.data() as Map<String, dynamic>))
        .toList();
  }
  // 장바구니 개수 조회
  Future<int> getCartCount() async {
    try {
      final snapshot = await _cartCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      print('장바구니 개수 조회 오류: $e');
      return 0;
    }
  }

  // 장바구니 비우기
  Future<void> clearCart() async {
    try {
      final snapshot = await _cartCollection.get();
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('장바구니 비우기 오류: $e');
    }
  }

  // 장바구니에 있는지 확인
  Future<bool> isInCart(String productId) async {
    try {
      final snapshot = await _cartCollection
          .where('productId', isEqualTo: productId)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('장바구니 확인 오류: $e');
      return false;
    }
  }
}