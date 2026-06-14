class AppConstants {
  AppConstants._();

  static const String whisperModelFileName = 'ggml-base.bin';
  static const String whisperModelUrl =
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin';

  static const String gemmaModelFileName = 'gemma-2b-it-cpu-int4.bin';

  static const int sampleRate = 16000;
  static const int numChannels = 1;
  static const int bitRate = 128000;

  static const int maxRecordingSeconds = 30;
  static const double silenceThreshold = 0.02;

  static const double ttsDefaultRate = 0.5;
  static const double ttsDefaultPitch = 1.0;
  static const double ttsDefaultVolume = 1.0;

  static const int minRamMb = 3072;
}
