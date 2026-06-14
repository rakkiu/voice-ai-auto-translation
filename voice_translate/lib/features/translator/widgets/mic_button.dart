import 'package:flutter/material.dart';

class MicButton extends StatelessWidget {
  const MicButton({
    super.key,
    required this.isRecording,
    required this.isProcessing,
    required this.onRecordStart,
    required this.onRecordStop,
  });

  final bool isRecording;
  final bool isProcessing;
  final VoidCallback onRecordStart;
  final VoidCallback onRecordStop;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => onRecordStart(),
      onLongPressEnd: (_) => onRecordStop(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isRecording ? 90 : 72,
        height: isRecording ? 90 : 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording
              ? Colors.redAccent
              : isProcessing
                  ? Colors.orange
                  : const Color(0xFF6366F1),
          boxShadow: [
            BoxShadow(
              color: (isRecording ? Colors.redAccent : const Color(0xFF6366F1))
                  .withValues(alpha: 0.5),
              blurRadius: isRecording ? 30 : 15,
              spreadRadius: isRecording ? 5 : 2,
            ),
          ],
        ),
        child: isProcessing
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 32,
              ),
      ),
    );
  }
}
