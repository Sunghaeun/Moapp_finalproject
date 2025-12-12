import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/gift_model.dart';
import '../services/cart_service.dart';

class GiftCard extends StatefulWidget {
  final Gift gift;

  const GiftCard({super.key, required this.gift});

  @override
  State<GiftCard> createState() => _GiftCardState();
}

class _GiftCardState extends State<GiftCard> {
  final CartService _cartService = CartService();
  bool _isInCart = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCartStatus();
  }

  Future<void> _checkCartStatus() async {
    final inCart = await _cartService.isInCart(widget.gift.id);
    if (mounted) {
      setState(() => _isInCart = inCart);
    }
  }

  Future<void> _toggleCart() async {
    setState(() => _isLoading = true);

    if (_isInCart) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이미 장바구니에 있습니다')),
      );
    } else {
      final success = await _cartService.addToCart(widget.gift);
      
      if (mounted) {
        if (success) {
          setState(() => _isInCart = true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('장바구니에 추가되었습니다'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('이미 장바구니에 있습니다'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    }

    setState(() => _isLoading = false);
  }

  Future<void> _launchUrl() async {
    final uri = Uri.parse(widget.gift.purchaseLink);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _formatPrice(int price) {
    final formatter = NumberFormat('#,###');
    return formatter.format(price);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: _launchUrl,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 상품 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  widget.gift.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[300],
                      child: const Icon(Icons.card_giftcard, size: 40),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              
              // 상품 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.gift.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (widget.gift.description.isNotEmpty)
                      Text(
                        widget.gift.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 8),
                    Text(
                      '${_formatPrice(widget.gift.price)}원',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // 버튼들
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isLoading ? null : _toggleCart,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : Icon(
                                    _isInCart ? Icons.check : Icons.shopping_cart_outlined,
                                    size: 16,
                                  ),
                            label: Text(_isInCart ? '담김' : '담기'),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              side: BorderSide(
                                color: _isInCart 
                                    ? Colors.green 
                                    : Colors.grey.shade300,
                              ),
                              foregroundColor: _isInCart 
                                  ? Colors.green 
                                  : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _launchUrl,
                            icon: const Icon(Icons.shopping_bag, size: 16),
                            label: const Text('구매'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              backgroundColor: const Color(0xFF51934C),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}