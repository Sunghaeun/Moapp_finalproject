import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// API 키 테스트 화면
/// 개발 단계에서 API 키가 올바르게 설정되었는지 확인하는 화면입니다.
class ApiTestScreen extends StatefulWidget {
  const ApiTestScreen({super.key});

  @override
  State<ApiTestScreen> createState() => _ApiTestScreenState();
}

class _ApiTestScreenState extends State<ApiTestScreen> {
  String _naverClientId = '';
  String _naverClientSecret = '';
  String _openaiApiKey = '';
  String _testResult = '테스트를 시작하려면 버튼을 눌러주세요.';
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadEnvValues();
  }

  void _loadEnvValues() {
    setState(() {
      _naverClientId = dotenv.env['NAVER_CLIENT_ID'] ?? '설정 안됨';
      _naverClientSecret = dotenv.env['NAVER_CLIENT_SECRET'] ?? '설정 안됨';
      _openaiApiKey = dotenv.env['OPENAI_API_KEY'] ?? '설정 안됨';
    });
  }

  Future<void> _testNaverApi() async {
    setState(() {
      _isLoading = true;
      _testResult = '네이버 API 테스트 중...';
    });

    try {
      final clientId = dotenv.env['NAVER_CLIENT_ID'] ?? '';
      final clientSecret = dotenv.env['NAVER_CLIENT_SECRET'] ?? '';

      if (clientId.isEmpty || clientSecret.isEmpty) {
        setState(() {
          _testResult = '❌ 실패: .env 파일에 API 키가 설정되지 않았습니다.\n\n'
              '확인사항:\n'
              '1. 프로젝트 루트에 .env 파일이 있는지\n'
              '2. .env 파일에 다음 내용이 있는지:\n'
              '   NAVER_CLIENT_ID=your_id\n'
              '   NAVER_CLIENT_SECRET=your_secret\n'
              '3. pubspec.yaml의 assets에 .env가 등록되어 있는지\n'
              '4. 앱을 재시작했는지 (Hot Reload로는 .env 변경사항이 반영 안됨)';
          _isLoading = false;
        });
        return;
      }

      print('=== 네이버 API 테스트 ===');
      print('Client ID 앞 5자: ${clientId.substring(0, clientId.length > 5 ? 5 : clientId.length)}...');
      
      final response = await http.get(
        Uri.parse('https://openapi.naver.com/v1/search/shop.json?query=테스트&display=1'),
        headers: {
          'X-Naver-Client-Id': clientId,
          'X-Naver-Client-Secret': clientSecret,
        },
      );

      print('응답 코드: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        final total = data['total'];
        
        setState(() {
          _testResult = '✅ 성공!\n\n'
              '네이버 쇼핑 API가 정상적으로 작동합니다.\n'
              '검색 결과 수: $total개\n\n'
              'Client ID: ${clientId.substring(0, 8)}...\n'
              'Client Secret: ${clientSecret.substring(0, 8)}...';
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        final errorBody = utf8.decode(response.bodyBytes);
        setState(() {
          _testResult = '❌ 인증 실패 (401)\n\n'
              'API 키가 올바르지 않습니다.\n\n'
              '해결 방법:\n'
              '1. 네이버 개발자 센터 접속\n'
              '   https://developers.naver.com/apps\n\n'
              '2. "내 애플리케이션" 에서 Client ID와 Secret 확인\n\n'
              '3. .env 파일에 정확히 복사-붙여넣기\n'
              '   (공백이나 따옴표 없이)\n\n'
              '4. 앱 완전히 재시작\n\n'
              '현재 설정된 값:\n'
              'Client ID: $clientId\n'
              'Client Secret: ${clientSecret.substring(0, 8)}...\n\n'
              '오류 상세:\n$errorBody';
          _isLoading = false;
        });
      } else if (response.statusCode == 403) {
        setState(() {
          _testResult = '❌ 권한 없음 (403)\n\n'
              'API 권한이 설정되지 않았습니다.\n\n'
              '해결 방법:\n'
              '1. 네이버 개발자 센터 접속\n'
              '2. "내 애플리케이션" 선택\n'
              '3. "API 권한관리" 탭 클릭\n'
              '4. "검색" API에 체크\n'
              '5. 저장 후 앱 재시작';
          _isLoading = false;
        });
      } else if (response.statusCode == 429) {
        setState(() {
          _testResult = '❌ 요청 한도 초과 (429)\n\n'
              'API 호출 횟수를 초과했습니다.\n'
              '잠시 후 다시 시도해주세요.';
          _isLoading = false;
        });
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        setState(() {
          _testResult = '❌ 알 수 없는 오류 (${response.statusCode})\n\n$errorBody';
          _isLoading = false;
        });
      }
    } catch (e, stackTrace) {
      setState(() {
        _testResult = '❌ 네트워크 오류\n\n$e\n\n$stackTrace';
        _isLoading = false;
      });
    }
  }

  Future<void> _testOpenAiApi() async {
    setState(() {
      _isLoading = true;
      _testResult = 'OpenAI API 테스트 중...';
    });

    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';

      if (apiKey.isEmpty) {
        setState(() {
          _testResult = '❌ 실패: OpenAI API 키가 설정되지 않았습니다.';
          _isLoading = false;
        });
        return;
      }

      final response = await http.get(
        Uri.parse('https://api.openai.com/v1/models'),
        headers: {
          'Authorization': 'Bearer $apiKey',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _testResult = '✅ 성공!\n\n'
              'OpenAI API가 정상적으로 작동합니다.\n\n'
              'API Key: ${apiKey.substring(0, 10)}...';
          _isLoading = false;
        });
      } else if (response.statusCode == 401) {
        setState(() {
          _testResult = '❌ 인증 실패 (401)\n\n'
              'OpenAI API 키가 올바르지 않습니다.\n\n'
              '해결 방법:\n'
              '1. https://platform.openai.com/api-keys 접속\n'
              '2. API 키 생성 또는 확인\n'
              '3. .env 파일에 복사\n'
              '4. 앱 재시작';
          _isLoading = false;
        });
      } else {
        final errorBody = utf8.decode(response.bodyBytes);
        setState(() {
          _testResult = '❌ 오류 (${response.statusCode})\n\n$errorBody';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _testResult = '❌ 네트워크 오류\n\n$e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API 키 테스트'),
        backgroundColor: Colors.red[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '현재 설정된 API 키',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildApiKeyRow(
                      'NAVER_CLIENT_ID',
                      _naverClientId,
                      _naverClientId != '설정 안됨',
                    ),
                    const SizedBox(height: 8),
                    _buildApiKeyRow(
                      'NAVER_CLIENT_SECRET',
                      _naverClientSecret.length > 8
                          ? '${_naverClientSecret.substring(0, 8)}...'
                          : _naverClientSecret,
                      _naverClientSecret != '설정 안됨',
                    ),
                    const SizedBox(height: 8),
                    _buildApiKeyRow(
                      'OPENAI_API_KEY',
                      _openaiApiKey.length > 10
                          ? '${_openaiApiKey.substring(0, 10)}...'
                          : _openaiApiKey,
                      _openaiApiKey != '설정 안됨',
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testNaverApi,
                icon: const Icon(Icons.shopping_cart),
                label: const Text('네이버 쇼핑 API 테스트'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _isLoading ? null : _testOpenAiApi,
                icon: const Icon(Icons.psychology),
                label: const Text('OpenAI API 테스트'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.grey[100],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isLoading ? Icons.hourglass_empty : Icons.info_outline,
                          color: Colors.blue,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          '테스트 결과',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    if (_isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      SelectableText(
                        _testResult,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyRow(String label, String value, bool isSet) {
    return Row(
      children: [
        Icon(
          isSet ? Icons.check_circle : Icons.error,
          color: isSet ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: value));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('복사되었습니다')),
                  );
                },
                child: Text(
                  value,
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}