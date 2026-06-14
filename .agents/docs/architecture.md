# Architecture

## Project Structure

```
voice_translate/
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml          # RECORD_AUDIO, INTERNET, largeHeap
│       └── kotlin/com/voicetranslate/voice_translate/
│           ├── MainActivity.kt          # Registers WhisperChannel
│           └── WhisperChannel.kt        # MethodChannel handler for Whisper JNI
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart       # Sample rates, model URLs, timeouts
│   │   ├── di/
│   │   │   └── injection.dart           # GetIt service locator setup
│   │   ├── models/
│   │   │   ├── language.dart            # Language enum (vi, en)
│   │   │   └── translation_session.dart # Entity for one translation
│   │   └── services/
│   │       ├── model_manager.dart       # Whisper model download + path mgmt
│   │       ├── stt/
│   │       │   ├── stt_service.dart     # Abstract interface
│   │       │   └── whisper_stt_service.dart  # Record → MethodChannel → Whisper
│   │       └── tts/
│   │           ├── tts_service.dart     # Abstract interface
│   │           └── flutter_tts_service.dart  # flutter_tts wrapper
│   ├── features/
│   │   └── translator/
│   │       ├── bloc/
│   │       │   ├── translator_bloc.dart
│   │       │   ├── translator_event.dart
│   │       │   └── translator_state.dart
│   │       ├── pages/
│   │       │   └── translator_page.dart
│   │       └── widgets/
│   │           ├── language_toggle.dart
│   │           ├── mic_button.dart
│   │           └── transcript_card.dart
│   ├── app.dart                        # MaterialApp + BlocProvider
│   └── main.dart                       # Entry: DI setup, mic permission, runApp
├── assets/models/                      # Whisper .bin files (downloaded at runtime)
└── pubspec.yaml
```

## Layering

1. **UI Layer** — `features/translator/pages/` + `widgets/`. Stateless widgets. No business logic. Dispatch events via `context.read<TranslatorBloc>().add(...)`.
2. **State Layer** — `features/translator/bloc/`. Translates events → service calls → emits new state.
3. **Service Layer** — `core/services/`. Interfaces + implementations. Swappable via DI.
4. **Model Layer** — `core/models/`. Plain data classes. Extend `Equatable` for value equality.

## Data Flow

```
User holds mic button
  → UI dispatches RecordingStarted
    → Bloc calls SttService.startRecording()
      → AudioRecorder writes 16kHz mono WAV to temp file
  → User releases mic button
    → UI dispatches RecordingStopped
      → Bloc calls SttService.stopRecordingAndTranscribe(language)
        → MethodChannel invokes Whisper JNI on audio file
        → Returns transcript text
      → Bloc emits state with originalText + auto-plays TTS
```

## Native Bridge

- MethodChannel name: `com.voicetranslate/whisper`
- Methods: `loadModel`, `transcribe`, `release`
- Kotlin handler in `WhisperChannel.kt` wired in `MainActivity.configureFlutterEngine()`
- Currently returns placeholder text — real JNI integration TBD in Sprint 2
