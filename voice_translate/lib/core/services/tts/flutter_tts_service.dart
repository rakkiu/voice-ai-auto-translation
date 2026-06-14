import 'package:flutter_tts/flutter_tts.dart';
import 'package:logger/logger.dart';
import 'tts_service.dart';

class FlutterTtsService implements TtsService {
  FlutterTtsService({required Logger logger}) : _logger = logger;

  final Logger _logger;
  final FlutterTts _tts = FlutterTts();
  bool _isSpeaking = false;

  @override
  bool get isSpeaking => _isSpeaking;

  @override
  Future<void> initialize() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.5);
    await _tts.setPitch(1.0);
    await _tts.awaitSpeakCompletion(true);

    _tts.setStartHandler(() => _isSpeaking = true);
    _tts.setCompletionHandler(() => _isSpeaking = false);
    _tts.setErrorHandler((msg) {
      _isSpeaking = false;
      _logger.e('TTS error: $msg');
    });

    _logger.i('TTS service initialized');
  }

  @override
  Future<void> speak({required String text, required String locale}) async {
    if (text.isEmpty) return;
    await _tts.setLanguage(locale);
    await _tts.speak(text);
  }

  @override
  Future<void> stop() async {
    await _tts.stop();
    _isSpeaking = false;
  }

  @override
  Future<void> setRate(double rate) => _tts.setSpeechRate(rate);

  @override
  Future<void> setPitch(double pitch) => _tts.setPitch(pitch);

  @override
  Future<void> setVolume(double volume) => _tts.setVolume(volume);

  @override
  Future<void> dispose() async => _tts.stop();
}
