// services/gift_database_service.dart
import 'package:hive/hive.dart';
import '../models/gift_model.dart';

class GiftDatabaseService {
  static const String _boxName = 'gifts';
  
  Future<Box<Gift>> _getBox() async {
    if (!Hive.isBoxOpen(_boxName)) {
      return await Hive.openBox<Gift>(_boxName);
    }
    return Hive.box<Gift>(_boxName);
  }

  // 선물 검색 (키워드 기반)
  Future<List<Gift>> searchGifts(String query) async {
    final box = await _getBox();
    final allGifts = box.values.toList();
    
    if (query.isEmpty) return allGifts;
    
    final lowerQuery = query.toLowerCase();
    return allGifts.where((gift) {
      return gift.name.toLowerCase().contains(lowerQuery) ||
             gift.description.toLowerCase().contains(lowerQuery) ||
             gift.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
    }).toList();
  }

  // 카테고리별 선물 조회
  Future<List<Gift>> getGiftsByCategory(String category) async {
    final box = await _getBox();
    return box.values
        .where((gift) => gift.category == category)
        .toList();
  }

  // 가격대별 선물 조회
  Future<List<Gift>> getGiftsByPriceRange(int minPrice, int maxPrice) async {
    final box = await _getBox();
    return box.values
        .where((gift) => gift.price >= minPrice && gift.price <= maxPrice)
        .toList();
  }

  // 인기 선물 조회
  Future<List<Gift>> getPopularGifts({int limit = 10}) async {
    final box = await _getBox();
    final gifts = box.values.toList();
    // 실제로는 인기도 점수나 구매 횟수로 정렬
    return gifts.take(limit).toList();
  }

  // 선물 추가
  Future<void> addGift(Gift gift) async {
    final box = await _getBox();
    await box.put(gift.id, gift);
  }

  // 선물 삭제
  Future<void> deleteGift(String id) async {
    final box = await _getBox();
    await box.delete(id);
  }

  // 초기 데이터 로드
  Future<void> loadInitialData() async {
    final box = await _getBox();
    
    if (box.isEmpty) {
      final sampleGifts = [
        Gift(
          id: '1',
          name: 'AirPods Pro 2세대',
          description: '액티브 노이즈 캔슬링이 탑재된 무선 이어폰',
          price: 359000,
          imageUrl: 'https://example.com/airpods.jpg',
          category: '전자기기',
          tags: ['무선', '음악', '애플', '프리미엄'],
          purchaseLink: 'https://www.apple.com/kr/airpods-pro/',
        ),
        Gift(
          id: '2',
          name: '디올 립스틱 세트',
          description: '인기 컬러 3종이 포함된 럭셔리 립스틱 세트',
          price: 150000,
          imageUrl: 'https://example.com/dior-lipstick.jpg',
          category: '뷰티',
          tags: ['화장품', '명품', '여성', '립스틱'],
          purchaseLink: 'https://www.dior.com/',
        ),
        Gift(
          id: '3',
          name: '스타벅스 기프티콘 5만원',
          description: '언제 어디서나 사용 가능한 스타벅스 모바일 상품권',
          price: 50000,
          imageUrl: 'https://example.com/starbucks.jpg',
          category: '기프티콘',
          tags: ['카페', '실용적', '간편', '커피'],
          purchaseLink: 'https://www.starbucks.co.kr/',
        ),
        Gift(
          id: '4',
          name: '나이키 에어포스 1',
          description: '클래식한 디자인의 운동화',
          price: 139000,
          imageUrl: 'https://example.com/nike.jpg',
          category: '패션',
          tags: ['신발', '운동화', '캐주얼', '나이키'],
          purchaseLink: 'https://www.nike.com/',
        ),
        Gift(
          id: '5',
          name: '조말론 우드 세이지 앤 씨 솔트 코롱',
          description: '상쾌하고 깔끔한 향의 향수',
          price: 195000,
          imageUrl: 'https://example.com/jomalone.jpg',
          category: '향수',
          tags: ['향수', '명품', '남녀공용', '조말론'],
          purchaseLink: 'https://www.jomalone.co.kr/',
        ),
        Gift(
          id: '6',
          name: 'iPad 10세대',
          description: '공부, 그림, 엔터테인먼트까지 만능 태블릿',
          price: 679000,
          imageUrl: 'https://example.com/ipad.jpg',
          category: '전자기기',
          tags: ['태블릿', '애플', '학생', '업무'],
          purchaseLink: 'https://www.apple.com/kr/ipad/',
        ),
      ];

      for (var gift in sampleGifts) {
        await box.put(gift.id, gift);
      }
    }
  }
}