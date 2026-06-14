abstract class SttService {
  Future<void> initialize({required String modelPath});

  Future<void> startRecording();

  Future<String> stopRecordingAndTranscribe({required String language});

  Future<void> cancelRecording();

  Future<void> dispose();

  bool get isRecording;
}
