import 'package:equatable/equatable.dart';
import '../../../core/models/language.dart';

abstract class TranslatorEvent extends Equatable {
  const TranslatorEvent();

  @override
  List<Object?> get props => [];
}

class RecordingStarted extends TranslatorEvent {}

class RecordingStopped extends TranslatorEvent {}

class RecordingCancelled extends TranslatorEvent {}

class LanguageToggled extends TranslatorEvent {}

class PlaybackRequested extends TranslatorEvent {
  const PlaybackRequested({required this.text, required this.language});
  final String text;
  final Language language;
  @override
  List<Object?> get props => [text, language];
}

class SessionReset extends TranslatorEvent {}
