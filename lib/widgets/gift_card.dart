import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/gift_model.dart';

class GiftCard extends StatelessWidget {
  final Gift gift;

  const GiftCard({super.key, required this.gift});

  Future<void> _launchURL(String urlString, BuildContext context) async {
    final Uri uri = Uri.parse(urlString);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      // URL을 열 수 없는 경우에 대한 예외 처리
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('링크를 열 수 없습니다: $urlString')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final numberFormat = NumberFormat.currency(locale: 'ko_KR', symbol: '');

    return Card(
      // main.dart에 정의된 CardTheme을 사용합니다.
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _launchURL(gift.purchaseLink, context),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. 이미지
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  gift.imageUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 100,
                      height: 100,
                      color: Colors.grey[200],
                      child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              // 2. 상품 정보
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      gift.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${numberFormat.format(gift.price)}원',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: gift.tags.take(2).map((tag) => Chip(
                        label: Text(tag),
                        // main.dart에 정의된 ChipTheme을 사용합니다.
                      )).toList(),
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
