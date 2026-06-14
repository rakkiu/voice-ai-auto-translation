import 'package:flutter/material.dart';
import '../../../core/models/language.dart';

class LanguageToggleWidget extends StatelessWidget {
  const LanguageToggleWidget({
    super.key,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.onToggle,
  });

  final Language sourceLanguage;
  final Language targetLanguage;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            sourceLanguage.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: onToggle,
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.swap_horiz,
                color: Color(0xFF6366F1),
                size: 24,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            targetLanguage.displayName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
