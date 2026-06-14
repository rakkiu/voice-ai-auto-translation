# State Management

## Approach

`flutter_bloc` (Cubit-like pattern using `Bloc<Event, State>`). Single `TranslatorBloc` manages the entire translator feature.

## Events (`translator_event.dart`)

| Event | Trigger |
|---|---|
| `RecordingStarted` | User presses-and-holds mic button |
| `RecordingStopped` | User releases mic button |
| `RecordingCancelled` | Swipe-up cancel gesture |
| `LanguageToggled` | Taps swap icon |
| `PlaybackRequested(text, language)` | Taps speaker icon on a transcript card |
| `SessionReset` | Resets to initial state |

## State (`translator_state.dart`)

```dart
enum TranslatorStatus { idle, recording, transcribing, translating, speaking, error }

class TranslatorState {
  TranslatorStatus status;
  Language sourceLanguage;   // default: Language.vi
  Language targetLanguage;   // default: Language.en
  String originalText;
  String translatedText;
  String? errorMessage;
}
```

Computed getters: `isRecording` (status == recording), `isProcessing` (transcribing || translating).

## Bloc Logic (`translator_bloc.dart`)

- **RecordingStarted**: Stops any ongoing TTS → calls `_stt.startRecording()` → emits `recording`.
- **RecordingStopped**: Emits `transcribing` → calls `_stt.stopRecordingAndTranscribe()` → on success emits `idle` with transcript + auto-dispatches `PlaybackRequested` to echo the original text via TTS. On empty transcript, silently returns to `idle`.
- **LanguageToggled**: Swaps source ↔ target languages AND swaps their displayed texts.
- **PlaybackRequested**: Sets status `speaking` → calls `_tts.speak()` → back to `idle`.
- **RecordingCancelled**: Calls `_stt.cancelRecording()` → `idle`.
- **SessionReset**: Resets to `TranslatorState()`.

## Wiring

```dart
BlocProvider(
  create: (_) => TranslatorBloc(sttService: sl(), ttsService: sl()),
  child: const TranslatorPage(),
)
```
