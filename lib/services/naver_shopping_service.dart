import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/gift_model.dart';

class NaverShoppingService {
  // 임시 테스트용: 여기에 직접 입력해보세요
  final String clientId = dotenv.env['NAVER_CLIENT_ID'] ?? ''; // 또는 '직접_입력'
  final String clientSecret = dotenv.env['NAVER_CLIENT_SECRET'] ?? ''; // 또는 '직접_입력'
  final String baseUrl = 'https://openapi.naver.com/v1/search/shop.json';

  Future<List<Gift>> search(String query, {int retryCount = 0}) async {
    // ========== 디버깅 출력 시작 ==========
    print('\n========== 네이버 API 디버깅 정보 ==========');
    print('📋 .env 파일에서 로드된 모든 키:');
    print('   NAVER_CLIENT_ID: ${dotenv.env['NAVER_CLIENT_ID']}');
    print('   NAVER_CLIENT_SECRET: ${dotenv.env['NAVER_CLIENT_SECRET']}');
    print('   OPENAI_API_KEY: ${dotenv.env['OPENAI_API_KEY']}');
    
    print('\n🔑 실제 사용될 값:');
    print('   clientId: $clientId');
    print('   clientId 길이: ${clientId.length}');
    print('   clientId가 비어있나?: ${clientId.isEmpty}');
    print('   clientSecret 앞 8자: ${clientSecret.isNotEmpty ? clientSecret.substring(0, clientSecret.length > 8 ? 8 : clientSecret.length) : "비어있음"}...');
    print('   clientSecret 길이: ${clientSecret.length}');
    print('=========================================\n');
    // ========== 디버깅 출력 끝 ==========

    // API 키 확인
    if (clientId.isEmpty || clientSecret.isEmpty) {
      throw Exception('❌ .env 파일 문제\n\n'
          '현재 상태:\n'
          '- NAVER_CLIENT_ID: ${clientId.isEmpty ? "❌ 비어있음" : "✅ 있음 (${clientId.length}자)"}\n'
          '- NAVER_CLIENT_SECRET: ${clientSecret.isEmpty ? "❌ 비어있음" : "✅ 있음 (${clientSecret.length}자)"}\n\n'
          '해결 방법:\n'
          '1. 프로젝트 루트에 .env 파일 생성\n'
          '2. 다음 형식으로 작성 (따옴표 없이!):\n'
          '   NAVER_CLIENT_ID=your_id\n'
          '   NAVER_CLIENT_SECRET=your_secret\n'
          '3. pubspec.yaml의 assets에 .env 추가\n'
          '4. flutter clean 실행\n'
          '5. 앱 완전 재시작');
    }

    print('=== 네이버 쇼핑 API 요청 ===');
    print('검색어: $query');

    try {
      final url = '$baseUrl?query=${Uri.encodeComponent(query)}&display=10&sort=sim';
      print('요청 URL: $url');
      print('헤더 Client ID: ${clientId.substring(0, clientId.length > 10 ? 10 : clientId.length)}...');
      
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'X-Naver-Client-Id': clientId,
          'X-Naver-Client-Secret': clientSecret,
        },
      );

      print('📡 응답 코드: ${response.statusCode}');
      print('📦 응답 헤더: ${response.headers}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        print('✅ API 응답 성공');
        
        final List items = data['items'] ?? [];
        print('검색 결과 수: ${items.length}');

        if (items.isEmpty) {
          print('⚠️ 검색 결과가 없습니다.');
          
          // 검색 결과가 없을 때 대체 검색어 시도
          if (retryCount == 0) {
            print('🔄 대체 검색어로 재시도...');
            final alternativeQueries = _getAlternativeQueries(query);
            
            for (var altQuery in alternativeQueries) {
              print('대체 검색어 시도: $altQuery');
              try {
                final results = await search(altQuery, retryCount: 1);
                if (results.isNotEmpty) {
                  print('✅ 대체 검색어로 ${results.length}개 결과 찾음');
                  return results;
                }
              } catch (e) {
                print('대체 검색어 실패: $e');
              }
            }
          }
          
          return [];
        }

        return items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          final title = (item['title'] as String?)?.replaceAll(RegExp(r'<[^>]*>'), '') ?? '이름 없음';
          final productId = item['productId']?.toString() ?? 
                          item['link']?.toString().hashCode.toString() ?? 
                          'product_$index';
          
          final lprice = item['lprice'];
          int price = 0;
          if (lprice != null) {
            if (lprice is int) {
              price = lprice;
            } else if (lprice is String) {
              price = int.tryParse(lprice) ?? 0;
            }
          }
          
          final category1 = item['category1']?.toString() ?? '쇼핑';
          final category2 = item['category2']?.toString();
          final category3 = item['category3']?.toString();
          final category4 = item['category4']?.toString();
          
          final tags = <String>[];
          if (category2 != null && category2.isNotEmpty) tags.add(category2);
          if (category3 != null && category3.isNotEmpty) tags.add(category3);
          if (category4 != null && category4.isNotEmpty) tags.add(category4);
          
          if (tags.isEmpty) {
            tags.add('추천상품');
          }
          
          return Gift(
            id: productId,
            name: title,
            description: '네이버 쇼핑에서 추천하는 상품입니다.',
            price: price,
            imageUrl: item['image'] ?? 'https://via.placeholder.com/150?text=No+Image',
            category: category1,
            tags: tags,
            purchaseLink: item['link'] ?? 'https://shopping.naver.com',
          );
        }).toList();
        
      } else if (response.statusCode == 401) {
        final errorBody = utf8.decode(response.bodyBytes);
        print('❌ 401 오류 상세:');
        print(errorBody);
        
        throw Exception('❌ 인증 실패 (401)\n\n'
            '입력한 API 키:\n'
            'Client ID: $clientId\n'
            'Client Secret: ${clientSecret.substring(0, 8)}...\n\n'
            '확인사항:\n'
            '1. 네이버 개발자센터(developers.naver.com/apps)에서\n'
            '   Client ID와 Secret을 다시 복사\n'
            '2. .env 파일에 공백/따옴표 없이 붙여넣기\n'
            '3. 앱 완전 재시작 (flutter clean 후 재실행)\n\n'
            '오류 상세:\n$errorBody');
      } else if (response.statusCode == 403) {
        throw Exception('❌ 권한 없음 (403)\n\n'
            '네이버 개발자센터에서:\n'
            '1. 애플리케이션 선택\n'
            '2. API 권한관리 탭\n'
            '3. "검색" 체크\n'
            '4. 저장 후 앱 재시작');
      } else if (response.statusCode == 429) {
        throw Exception('❌ 요청 한도 초과 (429)\n\n'
            'API 호출 횟수를 초과했습니다.\n'
            '잠시 후 다시 시도해주세요.');
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        print('❌ 알 수 없는 오류: $errorBody');
        throw Exception('네이버 쇼핑 API 오류 (${response.statusCode})\n\n$errorBody');
      }
    } catch (e, stackTrace) {
      print('❌ 예외 발생: $e');
      print('스택: $stackTrace');
      
      if (e is Exception) {
        rethrow;
      } else {
        throw Exception('네트워크 오류\n\n$e');
      }
    }
  }

  // 대체 검색어 생성
  List<String> _getAlternativeQueries(String originalQuery) {
    final alternatives = <String>[];
    
    // 키워드 매핑
    final Map<String, List<String>> keywordMap = {
      '향수': ['퍼퓸', '코롱', '향수세트'],
      '립스틱': ['립', '립스틱세트', '립메이크업'],
      '가방': ['백', '토트백', '크로스백'],
      '시계': ['손목시계', '워치', '스마트워치'],
      '이어폰': ['무선이어폰', '블루투스이어폰', '에어팟'],
      '텀블러': ['보온병', '물병', '스테인리스텀블러'],
      '커피': ['원두', '커피세트', '드립커피'],
      '초콜릿': ['초콜릿세트', '수제초콜릿', '명품초콜릿'],
      '와인': ['레드와인', '와인세트', '선물용와인'],
      '지갑': ['반지갑', '장지갑', '카드지갑'],
    };
    
    // 원본 쿼리의 키워드 추출
    for (var entry in keywordMap.entries) {
      if (originalQuery.contains(entry.key)) {
        alternatives.addAll(entry.value);
      }
    }
    
    // 대체 검색어가 없으면 일반적인 선물 키워드 사용
    if (alternatives.isEmpty) {
      alternatives.addAll(['선물세트', '기념일선물', '생일선물']);
    }
    
    return alternatives.take(3).toList();
  }}