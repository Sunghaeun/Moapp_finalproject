import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lottie/lottie.dart';
import '../services/face_analysis_service.dart';
import '../services/openai_service.dart';
import '../services/naver_shopping_service.dart';
import '../models/gift_model.dart';
import '../widgets/gift_card.dart';
import '../models/chat_message.dart';

class FaceAnalysisScreen extends StatefulWidget {
  const FaceAnalysisScreen({super.key});

  @override
  State<FaceAnalysisScreen> createState() => _FaceAnalysisScreenState();
}

class _FaceAnalysisScreenState extends State<FaceAnalysisScreen> {
  final FaceAnalysisService _faceService = FaceAnalysisService();
  final OpenAIService _aiService = OpenAIService();
  final NaverShoppingService _naverService = NaverShoppingService();

  XFile? _selectedImage;
  FaceAnalysisResult? _analysisResult;
  List<Gift> _recommendedGifts = [];
  bool _isAnalyzing = false;
  bool _isLoadingGifts = false;

  @override
  void dispose() {
    _faceService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _faceService.pickImage(source: source);
    if (image == null) return;

    setState(() {
      _selectedImage = image;
      _analysisResult = null;
      _recommendedGifts = [];
      _isAnalyzing = true;
    });

    // 얼굴 분석
    final result = await _faceService.analyzeFace(image.path);

    if (result == null) {
      setState(() => _isAnalyzing = false);
      _showErrorDialog('얼굴을 찾을 수 없어요', '사진에 얼굴이 명확하게 나오도록 다시 찍어주세요.');
      return;
    }

    setState(() {
      _analysisResult = result;
      _isAnalyzing = false;
    });

    // 선물 추천 받기
    _getGiftRecommendations();
  }

  Future<void> _getGiftRecommendations() async {
    if (_analysisResult == null) return;

    setState(() => _isLoadingGifts = true);

    try {
      // AI에게 얼굴 분석 결과를 바탕으로 추천 요청
      final prompt = '''
받는 사람 분석 결과:
- 연령대: ${_analysisResult!.estimatedAge}
- 성격: ${_analysisResult!.getPersonalityDescription()}
- 분위기: ${_analysisResult!.mood}
- 미소: ${_analysisResult!.isSmiling ? "밝게 웃고 있음" : "진지한 표정"}

이 분석을 바탕으로 어울리는 선물을 추천해주세요.
${_analysisResult!.getGiftRecommendationHint()}
''';

      final response = await _aiService.getRecommendation(
        userInput: prompt,
        conversationHistory: [],
      );

      print('검색어: ${response.searchQuery}');

      // 네이버 쇼핑 검색
      final gifts = await _naverService.search(response.searchQuery);

      setState(() {
        _recommendedGifts = gifts;
        _isLoadingGifts = false;
      });
    } catch (e) {
      print('선물 추천 오류: $e');
      setState(() => _isLoadingGifts = false);
      _showErrorDialog('추천 실패', '선물 추천 중 오류가 발생했어요. 다시 시도해주세요.');
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.orange),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('확인'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '👤 얼굴로 선물 찾기',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.purple[400]!, Colors.purple[700]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildImageSection(),
            if (_isAnalyzing) _buildAnalyzingSection(),
            if (_analysisResult != null && !_isAnalyzing) _buildResultSection(),
            if (_isLoadingGifts) _buildLoadingGiftsSection(),
            if (_recommendedGifts.isNotEmpty && !_isLoadingGifts) _buildGiftSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.purple[50]!, Colors.white],
        ),
      ),
      child: Column(
        children: [
          if (_selectedImage == null) ...[
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                shape: BoxShape.circle,
                border: Border.all(color: Colors.purple[200]!, width: 3),
              ),
              child: Icon(
                Icons.person,
                size: 100,
                color: Colors.grey[400],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '받는 사람의 사진을 선택하세요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '얼굴을 분석해서 딱 맞는 선물을 찾아드려요!',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ] else ...[
            Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(_selectedImage!.path),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // 시뮬레이터에서는 카메라 비활성화
              _buildActionButton(
                icon: Icons.camera_alt_rounded,
                label: '카메라',
                color: Colors.grey[400]!,
                onPressed: null, // 비활성화
              ),
              const SizedBox(width: 16),
              _buildActionButton(
                icon: Icons.photo_library_rounded,
                label: '갤러리에서 선택',
                color: Colors.blue[600]!,
                onPressed: () => _pickImage(ImageSource.gallery),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed, // nullable로 변경
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24),
      label: Text(label, style: const TextStyle(fontSize: 16)),
      style: ElevatedButton.styleFrom(
        backgroundColor: onPressed == null ? Colors.grey[300] : color,
        foregroundColor: onPressed == null ? Colors.grey[600] : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: onPressed == null ? 0 : 4,
      ),
    );
  }

  Widget _buildAnalyzingSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Lottie.asset(
              'assets/animations/snowman_thinking.json',
              errorBuilder: (context, error, stackTrace) {
                return const CircularProgressIndicator();
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '🔍 얼굴 분석 중...',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '잠시만 기다려주세요',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[50]!, Colors.purple[50]!],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.auto_awesome, color: Colors.purple, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  '분석 결과',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildResultItem(
            icon: Icons.sentiment_satisfied_alt,
            label: '감지된 감정',
            value: '${_analysisResult!.getEmotionEmoji()} ${_analysisResult!.detectedEmotion}',
          ),
          _buildResultItem(
            icon: Icons.mood,
            label: '표정',
            value: _analysisResult!.isSmiling ? '😊 밝게 웃고 있어요' : '😌 차분한 표정이에요',
          ),
          _buildResultItem(
            icon: Icons.cake,
            label: '추정 연령',
            value: _analysisResult!.estimatedAge,
          ),
          _buildResultItem(
            icon: Icons.psychology,
            label: '성격',
            value: _analysisResult!.getPersonalityDescription(),
          ),
          _buildResultItem(
            icon: Icons.wb_sunny,
            label: '분위기',
            value: '${_analysisResult!.mood} 느낌',
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.orange, size: 20),
                    SizedBox(width: 8),
                    Text(
                      '추천 힌트',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _analysisResult!.getGiftRecommendationHint(),
                  style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.purple[700], size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingGiftsSection() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          SizedBox(
            height: 150,
            child: Lottie.asset(
              'assets/animations/snowman_thinking.json',
              errorBuilder: (context, error, stackTrace) {
                return const CircularProgressIndicator();
              },
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '🎁 맞춤 선물 찾는 중...',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '분석 결과를 바탕으로 최적의 선물을 찾고 있어요',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildGiftSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green[400]!, Colors.green[600]!],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '추천 선물',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${_recommendedGifts.length}개를 찾았어요!',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _recommendedGifts.length,
            itemBuilder: (context, index) {
              return GiftCard(gift: _recommendedGifts[index]);
            },
          ),
        ],
      ),
    );
  }
}