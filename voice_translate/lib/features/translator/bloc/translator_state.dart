import 'package:equatable/equatable.dart';
import '../../../core/models/language.dart';

enum TranslatorStatus {
  idle,
  recording,
  transcribing,
  translating,
  speaking,
  error,
}

class TranslatorState extends Equatable {
  const TranslatorState({
    this.status = TranslatorStatus.idle,
    this.sourceLanguage = Language.vi,
    this.targetLanguage = Language.en,
    this.originalText = '',
    this.translatedText = '',
    this.errorMessage,
  });

  final TranslatorStatus status;
  final Language sourceLanguage;
  final Language targetLanguage;
  final String originalText;
  final String translatedText;
  final String? errorMessage;

  bool get isRecording => status == TranslatorStatus.recording;
  bool get isProcessing =>
      status == TranslatorStatus.transcribing ||
      status == TranslatorStatus.translating;

  TranslatorState copyWith({
    TranslatorStatus? status,
    Language? sourceLanguage,
    Language? targetLanguage,
    String? originalText,
    String? translatedText,
    String? errorMessage,
  }) {
    return TranslatorState(
      status: status ?? this.status,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
        status,
        sourceLanguage,
        targetLanguage,
        originalText,
        translatedText,
        errorMessage,
      ];
}
