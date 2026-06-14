abstract class TtsService {
  Future<void> initialize();

  Future<void> speak({required String text, required String locale});

  Future<void> stop();

  Future<void> setRate(double rate);
  Future<void> setPitch(double pitch);
  Future<void> setVolume(double volume);

  Future<void> dispose();

  bool get isSpeaking;
}
