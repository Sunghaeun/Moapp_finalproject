// widgets/selection_dialog.dart
import 'package:flutter/material.dart';

class SelectionDialog extends StatefulWidget {
  final String title;
  final String question;
  final List<SelectionOption> options;
  final Function(String) onSelected;

  const SelectionDialog({
    super.key,
    required this.title,
    required this.question,
    required this.options,
    required this.onSelected,
  });

  @override
  State<SelectionDialog> createState() => _SelectionDialogState();
}

class _SelectionDialogState extends State<SelectionDialog> {
  String? selectedValue;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 헤더
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 24),
            
            // 질문
            Text(
              widget.question,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            
            // 선택 옵션들
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: widget.options.map((option) {
                final isSelected = selectedValue == option.value;
                return _buildOptionButton(
                  label: option.label,
                  emoji: option.emoji,
                  value: option.value,
                  isSelected: isSelected,
                );
              }).toList(),
            ),
            
            const SizedBox(height: 24),
            
            // 확인 버튼
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: selectedValue != null
                    ? () {
                        Navigator.pop(context);
                        widget.onSelected(selectedValue!);
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.yellow[700],
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.grey[300],
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  '선물탐험 시작',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    String? emoji,
    required String value,
    required bool isSelected,
  }) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedValue = value;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.black : Colors.grey[300]!,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (emoji != null) ...[
              Text(
                emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SelectionOption {
  final String label;
  final String value;
  final String? emoji;

  SelectionOption({
    required this.label,
    required this.value,
    this.emoji,
  });
}

// 선택형 질문 표시 헬퍼 함수
Future<void> showSelectionDialog({
  required BuildContext context,
  required String title,
  required String question,
  required List<SelectionOption> options,
  required Function(String) onSelected,
}) {
  return showDialog(
    context: context,
    builder: (context) => SelectionDialog(
      title: title,
      question: question,
      options: options,
      onSelected: onSelected,
    ),
  );
}