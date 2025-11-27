import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/gift_model.dart';

class NaverShoppingService {
  final String clientId = dotenv.env['NAVER_CLIENT_ID'] ?? '';
  final String clientSecret = dotenv.env['NAVER_CLIENT_SECRET'] ?? '';
  final String baseUrl = 'https://openapi.naver.com/v1/search/shop.json';

  Future<List<Gift>> search(String query) async {
    if (clientId.isEmpty || clientSecret.isEmpty) {
      throw Exception('네이버 API 키가 .env 파일에 설정되지 않았습니다.');
    }

    print('=== 네이버 쇼핑 API 요청 ===');
    print('검색어: $query');

    final response = await http.get(
      Uri.parse('$baseUrl?query=${Uri.encodeComponent(query)}&display=10&sort=sim'),
      headers: {
        'X-Naver-Client-Id': clientId,
        'X-Naver-Client-Secret': clientSecret,
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      final List items = data['items'];

      return items.map((item) {
        // HTML 태그 제거
        final title = item['title']?.replaceAll(RegExp(r'<[^>]*>'), '');
        
        return Gift(
          id: item['productId'],
          name: title ?? '이름 없음',
          description: '네이버 쇼핑에서 추천하는 상품입니다.', // 상세 설명은 네이버에 없으므로 기본값 설정
          price: int.tryParse(item['lprice'] ?? '0') ?? 0,
          imageUrl: item['image'] ?? 'https://via.placeholder.com/150?text=No+Image',
          category: item['category1'] ?? '쇼핑',
          tags: [item['category2'], item['category3']]
              .whereType<String>() // null이 아니고 String 타입인 요소만 필터링
              .where((s) => s.isNotEmpty) // 비어있지 않은 문자열만 필터링
              .toList(),
          purchaseLink: item['link'] ?? 'https://shopping.naver.com',
        );
      }).toList();
    } else {
      print('네이버 API 오류: ${response.body}');
      throw Exception('네이버 쇼핑 API 요청에 실패했습니다 (${response.statusCode}).');
    }
  }
}