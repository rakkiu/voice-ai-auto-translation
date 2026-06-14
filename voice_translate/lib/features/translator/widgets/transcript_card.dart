import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TranscriptCard extends StatelessWidget {
  const TranscriptCard({
    super.key,
    required this.label,
    required this.text,
    required this.isLoading,
    this.onSpeak,
  });

  final String label;
  final String text;
  final bool isLoading;
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (text.isNotEmpty)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      color: Colors.white54,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã copy!')),
                        );
                      },
                    ),
                    if (onSpeak != null)
                      IconButton(
                        icon: const Icon(Icons.volume_up, size: 18),
                        color: Colors.white54,
                        onPressed: onSpeak,
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6366F1),
                      strokeWidth: 2,
                    ),
                  )
                : text.isEmpty
                    ? Center(
                        child: Text(
                          'Giữ nút mic để nói...',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.2),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            height: 1.5,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
