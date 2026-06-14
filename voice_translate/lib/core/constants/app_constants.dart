class AppConstants {
  AppConstants._();

  // --- Asset paths (bundled trong app) ---
  static const String whisperAssetPath = 'assets/models/ggml-base.bin';
  static const String gemmaAssetPath   = 'assets/models/gemma-2b-it-cpu-int4.bin';

  // --- File names (sau khi copy ra local storage) ---
  static const String whisperModelFileName = 'ggml-base.bin';
  static const String gemmaModelFileName   = 'gemma-2b-it-cpu-int4.bin';

  // --- Subdirectory trong Documents ---
  static const String modelsSubDir = 'models';

  // --- Model version cho app update detection ---
  static const String whisperModelVersion = 'base-v1';
  static const String gemmaModelVersion   = '2b-it-int4-v1';

  // --- Audio Recording ---
  static const int sampleRate        = 16000;
  static const int numChannels       = 1;
  static const int bitRate           = 128000;
  static const int maxRecordingSeconds = 30;
  static const double silenceThreshold = 0.02;

  // --- TTS ---
  static const double ttsDefaultRate   = 0.5;
  static const double ttsDefaultPitch  = 1.0;
  static const double ttsDefaultVolume = 1.0;

  // --- Language mapping ---
  static const Map<String, String> languageNames = {
    'vi': 'Vietnamese',
    'en': 'English',
  };

  // --- App ---
  static const int minRamMb = 3072;
}
