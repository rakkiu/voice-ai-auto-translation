import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/stt/stt_service.dart';
import '../../../core/services/tts/tts_service.dart';
import 'translator_event.dart';
import 'translator_state.dart';

class TranslatorBloc extends Bloc<TranslatorEvent, TranslatorState> {
  TranslatorBloc({
    required SttService sttService,
    required TtsService ttsService,
  })  : _stt = sttService,
        _tts = ttsService,
        super(const TranslatorState()) {
    on<RecordingStarted>(_onRecordingStarted);
    on<RecordingStopped>(_onRecordingStopped);
    on<RecordingCancelled>(_onRecordingCancelled);
    on<LanguageToggled>(_onLanguageToggled);
    on<PlaybackRequested>(_onPlaybackRequested);
    on<SessionReset>(_onSessionReset);
  }

  final SttService _stt;
  final TtsService _tts;

  Future<void> _onRecordingStarted(
    RecordingStarted event,
    Emitter<TranslatorState> emit,
  ) async {
    try {
      await _tts.stop();
      await _stt.startRecording();
      emit(state.copyWith(status: TranslatorStatus.recording));
    } catch (e) {
      emit(state.copyWith(
        status: TranslatorStatus.error,
        errorMessage: 'Không thể bắt đầu ghi âm: $e',
      ));
    }
  }

  Future<void> _onRecordingStopped(
    RecordingStopped event,
    Emitter<TranslatorState> emit,
  ) async {
    emit(state.copyWith(status: TranslatorStatus.transcribing));

    try {
      final transcript = await _stt.stopRecordingAndTranscribe(
        language: state.sourceLanguage.whisperCode,
      );

      if (transcript.isEmpty) {
        emit(state.copyWith(status: TranslatorStatus.idle));
        return;
      }

      emit(state.copyWith(
        originalText: transcript,
        translatedText: '[Translation coming in Sprint 2]',
        status: TranslatorStatus.idle,
      ));

      add(PlaybackRequested(
        text: transcript,
        language: state.sourceLanguage,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: TranslatorStatus.error,
        errorMessage: 'Lỗi nhận dạng giọng nói: $e',
      ));
    }
  }

  Future<void> _onRecordingCancelled(
    RecordingCancelled event,
    Emitter<TranslatorState> emit,
  ) async {
    await _stt.cancelRecording();
    emit(state.copyWith(status: TranslatorStatus.idle));
  }

  void _onLanguageToggled(
    LanguageToggled event,
    Emitter<TranslatorState> emit,
  ) {
    emit(state.copyWith(
      sourceLanguage: state.targetLanguage,
      targetLanguage: state.sourceLanguage,
      originalText: state.translatedText,
      translatedText: state.originalText,
    ));
  }

  Future<void> _onPlaybackRequested(
    PlaybackRequested event,
    Emitter<TranslatorState> emit,
  ) async {
    emit(state.copyWith(status: TranslatorStatus.speaking));
    await _tts.speak(text: event.text, locale: event.language.locale);
    emit(state.copyWith(status: TranslatorStatus.idle));
  }

  void _onSessionReset(SessionReset event, Emitter<TranslatorState> emit) {
    emit(const TranslatorState());
  }
}
