# Sprint 1 — Foundation: Project Setup, Whisper STT & TTS

> **Mục tiêu:** Dựng skeleton project, tích hợp Whisper offline STT và TTS hệ thống. Cuối sprint có thể: nói → thấy text → nghe TTS đọc lại (chưa có dịch).

---

## 0. Thông Tin Dự Án

| Field | Value |
|---|---|
| **App name** | VoiceTranslate |
| **Framework** | Flutter 3.x (Dart) |
| **Platform** | Android only |
| **Min SDK** | Android 8.0 (API 26) |
| **Target SDK** | API 34 |
| **Min RAM** | 3 GB |
| **STT Engine** | Whisper.cpp (offline, via Flutter plugin/FFI) |
| **LLM Engine** | MediaPipe + Gemma 2B (Sprint 2) |
| **TTS Engine** | flutter_tts (system TTS, offline) |
| **State Management** | flutter_bloc |
| **Languages** | Tiếng Việt ↔ English |

---

## 1. Cấu Trúc Thư Mục

```
voice_translate/
├── android/
│   ├── app/
│   │   ├── src/main/
│   │   │   ├── AndroidManifest.xml         ← thêm RECORD_AUDIO, INTERNET, WRITE_EXTERNAL_STORAGE
│   │   │   └── kotlin/com/voicetranslate/
│   │   │       └── MainActivity.kt
│   │   └── build.gradle                    ← minSdk 26, targetSdk 34
│   └── build.gradle
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart          ← paths, timeouts, supported languages
│   │   ├── di/
│   │   │   └── injection.dart              ← GetIt service locator
│   │   ├── models/
│   │   │   ├── language.dart               ← enum Language { vi, en }
│   │   │   └── translation_session.dart    ← entity cho 1 lần dịch
│   │   └── services/
│   │       ├── stt/
│   │       │   ├── stt_service.dart        ← abstract interface
│   │       │   └── whisper_stt_service.dart← implementation
│   │       └── tts/
│   │           ├── tts_service.dart        ← abstract interface
│   │           └── flutter_tts_service.dart← implementation
│   ├── features/
│   │   └── translator/
│   │       ├── bloc/
│   │       │   ├── translator_bloc.dart
│   │       │   ├── translator_event.dart
│   │       │   └── translator_state.dart
│   │       ├── pages/
│   │       │   └── translator_page.dart
│   │       └── widgets/
│   │           ├── mic_button.dart
│   │           ├── transcript_card.dart
│   │           └── language_toggle.dart
│   ├── app.dart
│   └── main.dart
├── pubspec.yaml
└── README.md
```

---

## 2. pubspec.yaml — Dependencies

```yaml
name: voice_translate
description: Offline voice translation app (VI ↔ EN)
version: 1.0.0+1

environment:
  sdk: ">=3.0.0 <4.0.0"
  flutter: ">=3.10.0"

dependencies:
  flutter:
    sdk: flutter

  # State Management
  flutter_bloc: ^8.1.4
  equatable: ^2.0.5

  # STT — Whisper offline
  # Dùng plugin: flutter_whisper_kit HOẶC tự build FFI bridge
  # Option A: Plugin có sẵn (kiểm tra compatibility trước)
  # whisper_flutter_new: ^1.0.0
  # Option B (khuyến nghị): dùng record + whisper.cpp via MethodChannel
  record: ^5.1.0             # Ghi âm microphone → file .wav
  path_provider: ^2.1.2      # Lấy path lưu file âm thanh + model

  # TTS
  flutter_tts: ^4.0.2

  # Permissions
  permission_handler: ^11.3.0

  # Utils
  get_it: ^7.7.0             # Dependency injection
  logger: ^2.3.0
  uuid: ^4.4.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^4.0.0
  mocktail: ^1.0.3

flutter:
  uses-material-design: true
  assets:
    - assets/models/           # Thư mục chứa Whisper model (sau khi download)
```

> **Lưu ý Whisper:** Plugin `whisper_flutter_new` hoặc `flutter_whisper_kit` cần kiểm tra Android support. Nếu không dùng được, implement `WhisperMethodChannel` bridge sang native Kotlin dùng `ggerganov/whisper.cpp` JNI wrapper (`whisper-android`).

---

## 3. AndroidManifest.xml

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android">

    <!-- Permissions -->
    <uses-permission android:name="android.permission.RECORD_AUDIO" />
    <uses-permission android:name="android.permission.INTERNET" />
    <!-- Cần cho download model lần đầu -->
    <uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE"
        android:maxSdkVersion="28" />
    <uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
        android:maxSdkVersion="32" />

    <application
        android:label="VoiceTranslate"
        android:name="${applicationName}"
        android:icon="@mipmap/ic_launcher"
        android:largeHeap="true">   <!-- ← BẮT BUỘC cho LLM/Whisper model lớn -->

        <activity
            android:name=".MainActivity"
            android:exported="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:windowSoftInputMode="adjustResize">
            <intent-filter>
                <action android:name="android.intent.action.MAIN"/>
                <category android:name="android.intent.category.LAUNCHER"/>
            </intent-filter>
        </activity>
    </application>
</manifest>
```

---

## 4. Core Models

### 4.1 `lib/core/models/language.dart`

```dart
enum Language {
  vi('vi-VN', 'Tiếng Việt', 'vi'),
  en('en-US', 'English', 'en');

  const Language(this.locale, this.displayName, this.whisperCode);

  /// Locale dùng cho TTS
  final String locale;

  /// Tên hiển thị trên UI
  final String displayName;

  /// Code truyền vào Whisper (language hint)
  final String whisperCode;

  Language get opposite => this == Language.vi ? Language.en : Language.vi;
}
```

### 4.2 `lib/core/models/translation_session.dart`

```dart
import 'package:equatable/equatable.dart';
import 'language.dart';

class TranslationSession extends Equatable {
  const TranslationSession({
    required this.id,
    required this.originalText,
    required this.translatedText,
    required this.sourceLanguage,
    required this.targetLanguage,
    required this.createdAt,
  });

  final String id;
  final String originalText;
  final String translatedText;
  final Language sourceLanguage;
  final Language targetLanguage;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, originalText, translatedText, sourceLanguage, targetLanguage];
}
```

### 4.3 `lib/core/constants/app_constants.dart`

```dart
class AppConstants {
  AppConstants._();

  // --- Whisper Model ---
  static const String whisperModelFileName = 'ggml-base.bin';
  // Download URL cho Whisper base model (~142MB) — hỗ trợ VI tốt
  static const String whisperModelUrl =
      'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.bin';

  // --- Gemma Model (dùng Sprint 2) ---
  static const String gemmaModelFileName = 'gemma-2b-it-cpu-int4.bin';

  // --- Audio Recording ---
  static const int sampleRate = 16000; // Whisper yêu cầu 16kHz
  static const int numChannels = 1;    // Mono
  static const int bitRate = 128000;

  // --- STT ---
  static const int maxRecordingSeconds = 30;
  static const double silenceThreshold = 0.02; // amplitude threshold

  // --- TTS ---
  static const double ttsDefaultRate = 0.5;   // 0.0 - 1.0
  static const double ttsDefaultPitch = 1.0;
  static const double ttsDefaultVolume = 1.0;

  // --- App ---
  static const int minRamMb = 3072; // 3GB minimum
}
```

---

## 5. Service Interfaces

### 5.1 `lib/core/services/stt/stt_service.dart`

```dart
/// Abstract interface cho Speech-to-Text service.
/// Swap implementation mà không cần sửa Bloc.
abstract class SttService {
  /// Khởi tạo engine (load model, setup audio session).
  /// Gọi 1 lần khi app start.
  Future<void> initialize({required String modelPath});

  /// Bắt đầu ghi âm vào buffer.
  Future<void> startRecording();

  /// Dừng ghi âm, trả về transcript từ audio vừa thu.
  /// [language] là hint ngôn ngữ để Whisper ưu tiên (vi / en).
  Future<String> stopRecordingAndTranscribe({required String language});

  /// Huỷ recording hiện tại mà không transcribe.
  Future<void> cancelRecording();

  /// Giải phóng tài nguyên.
  Future<void> dispose();

  /// True nếu đang trong quá trình ghi âm.
  bool get isRecording;
}
```

### 5.2 `lib/core/services/tts/tts_service.dart`

```dart
abstract class TtsService {
  Future<void> initialize();

  /// Đọc [text] bằng ngôn ngữ [locale] (vd: 'vi-VN', 'en-US').
  Future<void> speak({required String text, required String locale});

  Future<void> stop();

  Future<void> setRate(double rate);    // 0.0 - 1.0
  Future<void> setPitch(double pitch);  // 0.5 - 2.0
  Future<void> setVolume(double volume);// 0.0 - 1.0

  Future<void> dispose();

  bool get isSpeaking;
}
```

---

## 6. Whisper STT Implementation

### 6.1 Chiến lược tích hợp Whisper

```
Cách tiếp cận: record audio → lưu .wav → gọi Whisper.cpp → trả về text

Flow:
1. Dùng `record` package ghi âm → lưu vào temp file (16kHz, mono, WAV)
2. Gọi Whisper qua MethodChannel hoặc FFI để transcribe file đó
3. Trả về chuỗi text

Whisper Android wrapper khuyến nghị:
→ Dùng repo: https://github.com/ggerganov/whisper.cpp
→ Android example trong: whisper.cpp/examples/whisper.android/
→ Build AAR và import vào Flutter project
```

### 6.2 Kotlin MethodChannel Bridge

Tạo file `android/app/src/main/kotlin/com/voicetranslate/WhisperChannel.kt`:

```kotlin
package com.voicetranslate

import android.content.Context
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class WhisperChannel(
    private val context: Context,
    private val channel: MethodChannel
) : MethodChannel.MethodCallHandler {

    private var whisperContext: Long = 0L // native pointer

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadModel" -> {
                val modelPath = call.argument<String>("modelPath")!!
                // Gọi native whisper_init_from_file(modelPath)
                // whisperContext = WhisperJNI.initFromFile(modelPath)
                result.success(true)
            }
            "transcribe" -> {
                val audioPath = call.argument<String>("audioPath")!!
                val language = call.argument<String>("language") ?: "auto"
                // Gọi native whisper_full() với params
                // val text = WhisperJNI.transcribe(whisperContext, audioPath, language)
                result.success("placeholder transcript") // thay bằng kết quả thật
            }
            "release" -> {
                // WhisperJNI.free(whisperContext)
                result.success(true)
            }
            else -> result.notImplemented()
        }
    }
}
```

### 6.3 `lib/core/services/stt/whisper_stt_service.dart`

```dart
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

    // Xoá file cũ nếu tồn tại
    final file = File(_currentRecordingPath!);
    if (await file.exists()) await file.delete();

    await _recorder.start(
      RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000, // Whisper yêu cầu 16kHz
        numChannels: 1,    // Mono
        bitRate: 128000,
      ),
      path: _currentRecordingPath!,
    );

    _isRecording = true;
    _logger.d('Recording started → $_currentRecordingPath');
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
        'language': language, // 'vi' hoặc 'en'
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
```

---

## 7. TTS Implementation

### 7.1 `lib/core/services/tts/flutter_tts_service.dart`

```dart
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
    await _tts.setLanguage(locale); // 'vi-VN' hoặc 'en-US'
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
```

---

## 8. Dependency Injection

### `lib/core/di/injection.dart`

```dart
import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import '../services/stt/stt_service.dart';
import '../services/stt/whisper_stt_service.dart';
import '../services/tts/tts_service.dart';
import '../services/tts/flutter_tts_service.dart';

final GetIt sl = GetIt.instance;

Future<void> setupDependencies() async {
  // Logger
  sl.registerLazySingleton<Logger>(() => Logger(
    printer: PrettyPrinter(methodCount: 2, errorMethodCount: 5),
  ));

  // Services
  sl.registerLazySingleton<SttService>(
    () => WhisperSttService(logger: sl<Logger>()),
  );
  sl.registerLazySingleton<TtsService>(
    () => FlutterTtsService(logger: sl<Logger>()),
  );
}
```

---

## 9. Translator Bloc

### 9.1 `lib/features/translator/bloc/translator_event.dart`

```dart
import 'package:equatable/equatable.dart';
import '../../../core/models/language.dart';

abstract class TranslatorEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

/// User nhấn giữ mic button
class RecordingStarted extends TranslatorEvent {}

/// User thả mic button
class RecordingStopped extends TranslatorEvent {}

/// User huỷ recording (swipe up cancel)
class RecordingCancelled extends TranslatorEvent {}

/// Toggle hướng dịch (VI→EN hoặc EN→VI)
class LanguageToggled extends TranslatorEvent {}

/// Yêu cầu TTS đọc lại bản dịch
class PlaybackRequested extends TranslatorEvent {
  const PlaybackRequested({required this.text, required this.language});
  final String text;
  final Language language;
  @override
  List<Object?> get props => [text, language];
}

/// Reset về trạng thái ban đầu
class SessionReset extends TranslatorEvent {}
```

### 9.2 `lib/features/translator/bloc/translator_state.dart`

```dart
import 'package:equatable/equatable.dart';
import '../../../core/models/language.dart';

enum TranslatorStatus {
  idle,
  recording,
  transcribing,
  translating,
  speaking,
  error,
}

class TranslatorState extends Equatable {
  const TranslatorState({
    this.status = TranslatorStatus.idle,
    this.sourceLanguage = Language.vi,
    this.targetLanguage = Language.en,
    this.originalText = '',
    this.translatedText = '',
    this.errorMessage,
  });

  final TranslatorStatus status;
  final Language sourceLanguage;
  final Language targetLanguage;
  final String originalText;
  final String translatedText;
  final String? errorMessage;

  bool get isRecording => status == TranslatorStatus.recording;
  bool get isProcessing =>
      status == TranslatorStatus.transcribing ||
      status == TranslatorStatus.translating;

  TranslatorState copyWith({
    TranslatorStatus? status,
    Language? sourceLanguage,
    Language? targetLanguage,
    String? originalText,
    String? translatedText,
    String? errorMessage,
  }) {
    return TranslatorState(
      status: status ?? this.status,
      sourceLanguage: sourceLanguage ?? this.sourceLanguage,
      targetLanguage: targetLanguage ?? this.targetLanguage,
      originalText: originalText ?? this.originalText,
      translatedText: translatedText ?? this.translatedText,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    status, sourceLanguage, targetLanguage,
    originalText, translatedText, errorMessage,
  ];
}
```

### 9.3 `lib/features/translator/bloc/translator_bloc.dart`

```dart
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/models/language.dart';
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
      // Sprint 1: chỉ STT, chưa translate
      final transcript = await _stt.stopRecordingAndTranscribe(
        language: state.sourceLanguage.whisperCode,
      );

      if (transcript.isEmpty) {
        emit(state.copyWith(status: TranslatorStatus.idle));
        return;
      }

      emit(state.copyWith(
        originalText: transcript,
        // Sprint 2 sẽ điền translatedText sau khi gọi LLM
        translatedText: '[Translation coming in Sprint 2]',
        status: TranslatorStatus.idle,
      ));

      // Auto-play TTS với bản gốc (Sprint 1 test)
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
```

---

## 10. UI

### 10.1 `lib/features/translator/pages/translator_page.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/translator_bloc.dart';
import '../bloc/translator_event.dart';
import '../bloc/translator_state.dart';
import '../widgets/language_toggle.dart';
import '../widgets/mic_button.dart';
import '../widgets/transcript_card.dart';

class TranslatorPage extends StatelessWidget {
  const TranslatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'VoiceTranslate',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            onPressed: () {/* Sprint 3: Settings page */},
          ),
        ],
      ),
      body: BlocConsumer<TranslatorBloc, TranslatorState>(
        listener: (context, state) {
          if (state.status == TranslatorStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                // Language Direction Toggle
                LanguageToggleWidget(
                  sourceLanguage: state.sourceLanguage,
                  targetLanguage: state.targetLanguage,
                  onToggle: () => context.read<TranslatorBloc>().add(LanguageToggled()),
                ),

                const SizedBox(height: 16),

                // Original Text Card
                Expanded(
                  child: TranscriptCard(
                    label: state.sourceLanguage.displayName,
                    text: state.originalText,
                    isLoading: state.status == TranslatorStatus.transcribing,
                    onSpeak: state.originalText.isNotEmpty
                      ? () => context.read<TranslatorBloc>().add(
                          PlaybackRequested(
                            text: state.originalText,
                            language: state.sourceLanguage,
                          ),
                        )
                      : null,
                  ),
                ),

                const Divider(color: Colors.white12, height: 1),

                // Translated Text Card
                Expanded(
                  child: TranscriptCard(
                    label: state.targetLanguage.displayName,
                    text: state.translatedText,
                    isLoading: state.status == TranslatorStatus.translating,
                    onSpeak: state.translatedText.isNotEmpty
                      ? () => context.read<TranslatorBloc>().add(
                          PlaybackRequested(
                            text: state.translatedText,
                            language: state.targetLanguage,
                          ),
                        )
                      : null,
                  ),
                ),

                // Mic Button
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: MicButton(
                    isRecording: state.isRecording,
                    isProcessing: state.isProcessing,
                    onRecordStart: () =>
                        context.read<TranslatorBloc>().add(RecordingStarted()),
                    onRecordStop: () =>
                        context.read<TranslatorBloc>().add(RecordingStopped()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
```

### 10.2 `lib/features/translator/widgets/mic_button.dart`

```dart
import 'package:flutter/material.dart';

class MicButton extends StatelessWidget {
  const MicButton({
    super.key,
    required this.isRecording,
    required this.isProcessing,
    required this.onRecordStart,
    required this.onRecordStop,
  });

  final bool isRecording;
  final bool isProcessing;
  final VoidCallback onRecordStart;
  final VoidCallback onRecordStop;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPressStart: (_) => onRecordStart(),
      onLongPressEnd: (_) => onRecordStop(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: isRecording ? 90 : 72,
        height: isRecording ? 90 : 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isRecording
              ? Colors.redAccent
              : isProcessing
                  ? Colors.orange
                  : const Color(0xFF6366F1), // Indigo
          boxShadow: [
            BoxShadow(
              color: (isRecording ? Colors.redAccent : const Color(0xFF6366F1))
                  .withOpacity(0.5),
              blurRadius: isRecording ? 30 : 15,
              spreadRadius: isRecording ? 5 : 2,
            ),
          ],
        ),
        child: isProcessing
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : Icon(
                isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 32,
              ),
      ),
    );
  }
}
```

### 10.3 `lib/features/translator/widgets/transcript_card.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TranscriptCard extends StatelessWidget {
  const TranscriptCard({
    super.key,
    required this.label,
    required this.text,
    required this.isLoading,
    this.onSpeak,
  });

  final String label;
  final String text;
  final bool isLoading;
  final VoidCallback? onSpeak;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Language label + action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white54,
                  fontSize: 12,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (text.isNotEmpty)
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.copy, size: 18),
                      color: Colors.white54,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: text));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã copy!')),
                        );
                      },
                    ),
                    if (onSpeak != null)
                      IconButton(
                        icon: const Icon(Icons.volume_up, size: 18),
                        color: Colors.white54,
                        onPressed: onSpeak,
                      ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 8),
          // Content
          Expanded(
            child: isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Color(0xFF6366F1),
                      strokeWidth: 2,
                    ),
                  )
                : text.isEmpty
                    ? Center(
                        child: Text(
                          'Giữ nút mic để nói...',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.2),
                            fontSize: 16,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            height: 1.5,
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
```

---

## 11. main.dart & app.dart

### `lib/main.dart`

```dart
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/di/injection.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup DI
  await setupDependencies();

  // Xin quyền microphone ngay khi start
  await Permission.microphone.request();

  runApp(const VoiceTranslateApp());
}
```

### `lib/app.dart`

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/services/stt/stt_service.dart';
import 'core/services/tts/tts_service.dart';
import 'features/translator/bloc/translator_bloc.dart';
import 'features/translator/pages/translator_page.dart';

class VoiceTranslateApp extends StatelessWidget {
  const VoiceTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoiceTranslate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFF6366F1),
          secondary: const Color(0xFF10B981),
        ),
      ),
      home: BlocProvider(
        create: (_) => TranslatorBloc(
          sttService: sl<SttService>(),
          ttsService: sl<TtsService>(),
        ),
        child: const TranslatorPage(),
      ),
    );
  }
}
```

---

## 12. Whisper Model Management (Sprint 1 — download first run)

```dart
// lib/core/services/model_manager.dart
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

class ModelManager {
  /// Trả về path đến Whisper model.
  /// Nếu chưa tồn tại → throw, cần gọi downloadWhisperModel() trước.
  static Future<String> getWhisperModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/models/${AppConstants.whisperModelFileName}';
  }

  /// Kiểm tra model đã download chưa.
  static Future<bool> isWhisperModelReady() async {
    final path = await getWhisperModelPath();
    return File(path).exists();
  }

  /// Download Whisper base model (~142MB).
  /// [onProgress]: callback với % tiến độ (0.0 - 1.0)
  static Future<void> downloadWhisperModel({
    required void Function(double progress) onProgress,
  }) async {
    final path = await getWhisperModelPath();
    final dir = Directory(path).parent;
    if (!await dir.exists()) await dir.create(recursive: true);

    final request = http.Request('GET', Uri.parse(AppConstants.whisperModelUrl));
    final response = await http.Client().send(request);

    final totalBytes = response.contentLength ?? 0;
    int receivedBytes = 0;

    final file = File(path).openWrite();
    await for (final chunk in response.stream) {
      file.add(chunk);
      receivedBytes += chunk.length;
      if (totalBytes > 0) {
        onProgress(receivedBytes / totalBytes);
      }
    }
    await file.close();
  }
}
```

---

## 13. Checklist Sprint 1

- [ ] `flutter create voice_translate` và cấu hình pubspec.yaml
- [ ] Setup cấu trúc thư mục theo mục 1
- [ ] Cấu hình `AndroidManifest.xml` (permissions + largeHeap)
- [ ] Implement `ModelManager` — download + check Whisper model
- [ ] Tích hợp Whisper: build `.aar` từ whisper.cpp hoặc dùng plugin, kết nối MethodChannel
- [ ] Implement `WhisperSttService` — record + transcribe
- [ ] Implement `FlutterTtsService` — speak với locale
- [ ] Setup GetIt DI
- [ ] Implement `TranslatorBloc` (chưa cần LLM, test STT → TTS)
- [ ] Build UI cơ bản: `TranslatorPage`, `MicButton`, `TranscriptCard`, `LanguageToggle`
- [ ] Test end-to-end: nói VI → Whisper nhận text → TTS đọc lại
- [ ] Xử lý permission flow (request microphone khi start)

---

## 14. Definition of Done — Sprint 1

> Sprint 1 hoàn thành khi:
> 1. Giữ nút mic → nói tiếng Việt → thấy transcript text trên màn hình
> 2. Giữ nút mic → nói tiếng Anh (sau khi toggle) → thấy transcript
> 3. Nhấn speaker icon → nghe TTS đọc lại đúng ngôn ngữ
> 4. Không crash khi model chưa download → hiện loading/download screen
> 5. Chạy được trên thiết bị Android thật có ≥ 3GB RAM
