abstract class LlmService {
  Future<void> initialize({required String modelPath});

  Future<String> translate({
    required String text,
    required String sourceLang,
    required String targetLang,
  });

  Stream<String> translateStream({
    required String text,
    required String sourceLang,
    required String targetLang,
  });

  bool get isInitialized;
  bool get isGenerating;

  Future<void> dispose();
}
