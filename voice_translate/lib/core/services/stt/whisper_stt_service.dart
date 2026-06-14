import 'dart:io';
import 'package:flutter/services.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'stt_service.dart';

class WhisperSttService implements SttService {
  WhisperSttService({required Logger logger}) : _logger = logger;

  final Logger _logger;
  final AudioRecorder _recorder = AudioRecorder();
  static const MethodChannel _channel = MethodChannel('com.voicetranslate/whisper');

  bool _isRecording = false;
  String? _currentRecordingPath;

  @override
  bool get isRecording => _isRecording;

  @override
  Future<void> initialize({required String modelPath}) async {
    try {
      final result = await _channel.invokeMethod<bool>('loadModel', {
        'modelPath': modelPath,
      });
      if (result != true) throw Exception('Failed to load Whisper model');
      _logger.i('Whisper model loaded from $modelPath');
    } catch (e) {
      _logger.e('Whisper init error: $e');
      rethrow;
    }
  }

  @override
  Future<void> startRecording() async {
    if (_isRecording) return;

    final tempDir = await getTemporaryDirectory();
    _currentRecordingPath = '${tempDir.path}/whisper_input.wav';

    final file = File(_currentRecordingPath!);
    if (await file.exists()) await file.delete();

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 128000,
      ),
      path: _currentRecordingPath!,
    );

    _isRecording = true;
    _logger.d('Recording started -> $_currentRecordingPath');
  }

  @override
  Future<String> stopRecordingAndTranscribe({required String language}) async {
    if (!_isRecording || _currentRecordingPath == null) return '';

    await _recorder.stop();
    _isRecording = false;
    _logger.d('Recording stopped, transcribing...');

    try {
      final transcript = await _channel.invokeMethod<String>('transcribe', {
        'audioPath': _currentRecordingPath!,
        'language': language,
      });
      _logger.i('Transcript: $transcript');
      return transcript?.trim() ?? '';
    } catch (e) {
      _logger.e('Transcription error: $e');
      return '';
    }
  }

  @override
  Future<void> cancelRecording() async {
    if (!_isRecording) return;
    await _recorder.stop();
    _isRecording = false;
  }

  @override
  Future<void> dispose() async {
    await _recorder.dispose();
    await _channel.invokeMethod('release');
  }
}
