import 'package:flutter/material.dart';
import '../models/gift_model.dart';
import '../services/naver_shopping_service.dart';
import '../services/openai_service.dart';
import '../widgets/gift_card.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});
  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _formKey = GlobalKey<FormState>();
  final _recipientController = TextEditingController();
  final _interestsController = TextEditingController();

  final OpenAIService _aiService = OpenAIService();
  final NaverShoppingService _naverService = NaverShoppingService();

  String? _selectedStyle;
  String? _selectedPriceRange;
  bool _isLoading = false;
  List<Gift> _recommendedGifts = [];
  String? _aiAnalysis;

  final List<String> _styles = ['실용적인', '트렌디한', '고급스러운', '재미있는', '감성적인'];
  final List<String> _priceRanges = ['2만원 이하', '2-5만원', '5-10만원', '10만원 이상'];

  @override
  void dispose() {
    _recipientController.dispose();
    _interestsController.dispose();
    super.dispose();
  }

  Future<void> _getRecommendations() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    FocusScope.of(context).unfocus(); // 키보드 숨기기

    setState(() {
      _isLoading = true;
      _recommendedGifts = [];
      _aiAnalysis = null;
    });

    try {
      final userInput = _buildPrompt();
      final response = await _aiService.getRecommendation(
        userInput: userInput,
        conversationHistory: [],
      );

      // 네이버 쇼핑 검색 (여러 검색어 처리)
      final List<Gift> giftResults = [];
      for (final query in response.searchQueries) {
        final gifts = await _naverService.search(query, display: 1); // 각 검색어 당 1개만 가져옴
        if (gifts.isNotEmpty) {
          giftResults.add(gifts.first); // 첫번째 결과만 리스트에 추가
        }
      }

      setState(() {
        _aiAnalysis = response.analysis;
        _recommendedGifts = giftResults;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('오류가 발생했습니다: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _buildPrompt() {
    return '''
다음 정보를 바탕으로 선물을 추천해줘:
- 받는 사람: ${_recipientController.text}
- مناسبات: 크리스마스
- 가격대: ${_selectedPriceRange ?? '상관 없음'}
- 관심사/특징: ${_interestsController.text}
- 원하는 선물 스타일: ${_selectedStyle ?? 'AI가 가장 잘 어울리는 스타일로 추천'}
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('💬 대화로 선물 찾기'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20.0),
            children: [
              const Text(
                '누구에게 선물하시나요?',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'AI가 맞춤 크리스마스 선물을 찾도록 정보를 입력해주세요.',
                style: TextStyle(fontSize: 15, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              _buildTextFormField(
                controller: _recipientController,
                label: '받는 사람',
                hint: '예: 20대 여자친구, 부모님',
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 24),
              _buildChipSelection(
                label: '어떤 스타일의 선물을 원하세요?',
                items: _styles,
                selectedItem: _selectedStyle,
                onSelected: (item) => setState(() => _selectedStyle = item),
                icon: Icons.auto_awesome_outlined,
              ),
              const SizedBox(height: 24),
              _buildChipSelection(
                label: '가격대는요?',
                items: _priceRanges,
                selectedItem: _selectedPriceRange,
                onSelected: (item) => setState(() => _selectedPriceRange = item),
                icon: Icons.wallet_outlined,
              ),
              const SizedBox(height: 24),
              _buildTextFormField(
                controller: _interestsController,
                label: '관심사 또는 특징',
                hint: '예: 운동 좋아함, 귀여운 캐릭터 선호',
                icon: Icons.interests_outlined,
                required: false,
              ),
              const SizedBox(height: 32),
              _buildSubmitButton(),
              const SizedBox(height: 24),
              if (_isLoading) _buildLoadingIndicator(),
              if (_aiAnalysis != null) _buildResultSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.grey),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          validator: required
              ? (value) => (value == null || value.isEmpty) ? '$label 항목은 필수입니다.' : null
              : null,
        ),
      ],
    );
  }

  Widget _buildChipSelection({
    required String label,
    required List<String> items,
    required String? selectedItem,
    required Function(String) onSelected,
    required IconData icon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10.0,
          runSpacing: 10.0,
          children: items.map((item) {
            final isSelected = selectedItem == item;
            return ChoiceChip(
              label: Text(item),
              selected: isSelected,
              onSelected: (_) => onSelected(item),
              selectedColor: Theme.of(context).colorScheme.primary,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface),
              backgroundColor: Colors.grey[200],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey[300]!),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isLoading ? null : _getRecommendations,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('AI 선물 추천받기'),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: Column(
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('AI가 최고의 선물을 찾고 있어요...', style: TextStyle(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildResultSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(height: 40),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFFDEDEC), // Light Red from palette
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: Color(0xFFEF463F)),
                  SizedBox(width: 8),
                  Text(
                    'AI의 추천 이유',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _aiAnalysis!,
                style: TextStyle(fontSize: 15, height: 1.5, color: Colors.grey[800]),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (_recommendedGifts.isNotEmpty)
          ...[
            const Text(
              '추천 선물 목록 🎁',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recommendedGifts.length,
              itemBuilder: (context, index) => GiftCard(gift: _recommendedGifts[index]),
              separatorBuilder: (context, index) => const SizedBox(height: 12),
            ),
          ]
        else
          const Center(
            child: Text(
              '추천할 만한 선물을 찾지 못했어요.\n다른 키워드로 시도해보세요.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ),
      ],
    );
  }
}