import 'package:equatable/equatable.dart';
import 'language.dart';

class TranslationSession extends Equatable {
  const TranslationSession({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.createdAt,
  });

  final String id;
  final String originalText;
  final String translatedText;
  final Language sourceLanguage;
  final Language targetLanguage;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
        id,
        originalText,
        translatedText,
        sourceLanguage,
        targetLanguage,
      ];
}
