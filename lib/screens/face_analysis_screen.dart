import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/openai_service.dart';
import '../services/naver_shopping_service.dart';
import '../models/gift_model.dart';
import '../widgets/gift_card.dart';

class FaceAnalysisScreen extends StatefulWidget {
  const FaceAnalysisScreen({super.key});

  @override
  State<FaceAnalysisScreen> createState() => _FaceAnalysisScreenState();
}

class _FaceAnalysisScreenState extends State<FaceAnalysisScreen> {
  final _picker = ImagePicker();
  final OpenAIService _aiService = OpenAIService();
  final NaverShoppingService _naverService = NaverShoppingService();

  XFile? _selectedImage;
  String? _analysisResultText;
  List<Gift> _recommendedGifts = [];
  bool _isAnalyzing = false;
  bool _isLoadingGifts = false;
  int _recommendationAttempt = 0; // 추천 시도 횟수

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 80,
    );
    if (image == null) return;

    setState(() {
      _selectedImage = image;
      _analysisResultText = null;
      _recommendedGifts = [];
      _recommendationAttempt = 0;
    });

    _isAnalyzing = false; // ML Kit 분석이 없어졌으므로 바로 선물 추천으로

    // 선물 추천 받기
    _getGiftRecommendations();
  }

  Future<void> _getGiftRecommendations() async {
    if (_selectedImage == null) return;

    setState(() => _isLoadingGifts = true);
    _recommendationAttempt++;

    try {
      // AI에게 이미지 분석 및 추천 요청
      final response = await _aiService.getRecommendationFromImage(
        imagePath: _selectedImage!.path,
        attemptCount: _recommendationAttempt,
      );

      print('=== AI 응답 ===');
      print('분석: ${response.analysis}');
      print('검색어 리스트: ${response.searchQueries}');

      // 네이버 쇼핑 검색 (여러 검색어 처리)
      final List<Gift> giftResults = [];
      for (final query in response.searchQueries) {
        final gifts = await _naverService.search(query, display: 1); // 각 검색어 당 1개만 가져옴
        if (gifts.isNotEmpty) {
          giftResults.add(gifts.first); // 첫번째 결과만 리스트에 추가
        }
      }

      setState(() {
        _analysisResultText = response.analysis;
        _recommendedGifts = giftResults;
        _isLoadingGifts = false;
      });

      if (giftResults.isEmpty) {
        // 모든 검색어에 대해 결과가 없는 경우
        _showRetryDialog(response.searchQueries.join(', '));
      }
    } catch (e) {
      print('선물 추천 오류: $e');
      setState(() => _isLoadingGifts = false);
      _showErrorDialog('추천 실패', 
          '선물 추천 중 오류가 발생했어요.\n\n'
          '오류: ${e.toString()}\n\n'
          '다시 시도하거나 다른 사진을 선택해주세요.');
    }
  }

  void _showRetryDialog(String failedQuery) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.orange),
            SizedBox(width: 8),
            Text('검색 결과 없음'),
          ],
        ),
        content: Text(
          '"$failedQuery" 검색 결과가 없어요.\n\n'
          '다른 선물을 찾아볼까요?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _getGiftRecommendations(); // 재시도
            },
            child: const Text('다시 추천받기'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('닫기'),
          ),
        ],
      ),
    );
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
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (_analysisResultText != null)
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: '다른 선물 추천받기',
              onPressed: _isLoadingGifts ? null : _getGiftRecommendations,
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildImageSection(),
            if (_analysisResultText != null) _buildResultSection(),
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
        color: Theme.of(context).colorScheme.background,
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
                border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.3), width: 3),
              ),
              child: Icon(
                Icons.person,
                size: 100,
                color: Colors.grey[350],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              '받는 사람의 사진을 선택하세요',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              '얼굴을 정밀 분석해서 딱 맞는 선물을 찾아드려요!',
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
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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
          _buildActionButton(
            icon: Icons.photo_library_rounded,
            label: '갤러리에서 사진 선택',
            color: Theme.of(context).colorScheme.primary,
            onPressed: _pickImage,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback? onPressed,
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

  Widget _buildResultSection() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4ED), // Light Green from palette
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
                child: Icon(Icons.auto_awesome, color: Theme.of(context).colorScheme.secondary, size: 28),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'AI 분석 결과',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _analysisResultText ?? '분석 결과가 없습니다.',
            style: TextStyle(
              fontSize: 15,
              height: 1.6,
              color: Colors.grey[800],
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
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            _recommendationAttempt == 1 
                ? '🎁 AI가 사진을 분석하고 있어요...'
                : '🔄 AI가 다른 선물을 찾고 있어요...',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            '나이, 표정, 분위기를 파악하여 맞춤 선물을 추천합니다.',
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
              color: Theme.of(context).colorScheme.secondary,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _recommendationAttempt > 1 
                            ? '${_recommendationAttempt}번째 추천 선물'
                            : '추천 선물',
                        style: const TextStyle(
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
                IconButton(
                  icon: const Icon(Icons.refresh, color: Colors.white),
                  onPressed: _getGiftRecommendations,
                  tooltip: '다른 선물 보기',
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