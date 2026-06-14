import 'dart:async';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'llm_service.dart';

class GemmaMediaPipeService implements LlmService {
  GemmaMediaPipeService({required Logger logger}) : _logger = logger;

  final Logger _logger;
  static const MethodChannel _channel =
      MethodChannel('com.voicetranslate/mediapipe_llm');

  bool _isInitialized = false;
  bool _isGenerating = false;

  @override
  bool get isInitialized => _isInitialized;

  @override
  bool get isGenerating => _isGenerating;

  @override
  Future<void> initialize({required String modelPath}) async {
    try {
      _logger.i('Loading Gemma model from $modelPath...');
      final result = await _channel.invokeMethod<bool>('loadModel', {
        'modelPath': modelPath,
        'maxTokens': 512,
        'topK': 40,
        'temperature': 0.3,
        'randomSeed': 42,
      });
      _isInitialized = result == true;
      _logger.i('Gemma model loaded: $_isInitialized');
    } catch (e) {
      _logger.e('Gemma init error: $e');
      rethrow;
    }
  }

  @override
  Future<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) async {
    if (!_isInitialized) throw Exception('LLM not initialized');
    if (text.trim().isEmpty) return '';

    _isGenerating = true;
    try {
      final prompt = _buildTranslationPrompt(
        text: text,
        sourceLang: sourceLang,
        targetLang: targetLang,
      );

      _logger.d('Sending prompt to Gemma:\n$prompt');

      final result = await _channel.invokeMethod<String>('generate', {
        'prompt': prompt,
      });

      final cleaned = _cleanOutput(result ?? '');
      _logger.i('Translation result: $cleaned');
      return cleaned;
    } finally {
      _isGenerating = false;
    }
  }

  @override
  Stream<String> translateStream({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) {
    return Stream.fromFuture(translate(
      text: text,
      sourceLang: sourceLang,
      targetLang: targetLang,
    ));
  }

  String _buildTranslationPrompt({
    required String text,
    required String sourceLang,
    required String targetLang,
  }) {
    return '<start_of_turn>user\n'
        'Translate the following $sourceLang text to $targetLang.\n'
        'Output ONLY the translated text. Do not add explanations, notes, or any extra text.\n'
        '\n'
        '$sourceLang text: $text<end_of_turn>\n'
        '<start_of_turn>model\n';
  }

  String _cleanOutput(String raw) {
    var text = raw
        .replaceAll('<end_of_turn>', '')
        .replaceAll('<start_of_turn>', '')
        .trim();

    final prefixes = [
      'Here is the translation:',
      'Translation:',
      'The translation is:',
      'Sure!',
      'Here\'s',
    ];
    for (final prefix in prefixes) {
      if (text.startsWith(prefix)) {
        text = text.substring(prefix.length).trim();
      }
    }

    return text;
  }

  @override
  Future<void> dispose() async {
    await _channel.invokeMethod('release');
    _isInitialized = false;
  }
}
