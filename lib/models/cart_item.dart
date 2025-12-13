class CartItem {
  final String id;
  final String userId;
  final String productId;
  final String title;
  final String imageUrl;
  final int price;
  final String link;
  final DateTime addedAt;

  CartItem({
    required this.id,
    required this.userId,
    required this.productId,
    required this.title,
    required this.imageUrl,
    required this.price,
    required this.link,
    required this.addedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'productId': productId,
      'title': title,
      'imageUrl': imageUrl,
      'price': price,
      'link': link,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CartItem.fromMap(String id, Map<String, dynamic> map) {
    return CartItem(
      id: id,
      userId: map['userId'] ?? '',
      productId: map['productId'] ?? '',
      title: map['title'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      price: map['price'] ?? 0,
      link: map['link'] ?? '',
      addedAt: DateTime.parse(map['addedAt'] ?? DateTime.now().toIso8601String()),
    );
  }
}