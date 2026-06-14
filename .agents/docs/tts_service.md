# Text-to-Speech Service

## Implementation

`FlutterTtsService` wraps `flutter_tts` package. Implements `TtsService` abstract interface.

## Initialization

```dart
await _tts.setVolume(1.0);
await _tts.setSpeechRate(0.5);   // 0.0 - 1.0
await _tts.setPitch(1.0);        // 0.5 - 2.0
await _tts.awaitSpeakCompletion(true);
```

Sets `_isSpeaking` flag via handlers:
- `setStartHandler` → `_isSpeaking = true`
- `setCompletionHandler` → `_isSpeaking = false`
- `setErrorHandler` → `_isSpeaking = false` + log error

## Speak

```dart
speak(text, locale)
  → _tts.setLanguage(locale)   // "vi-VN" or "en-US"
  → _tts.speak(text)
```

Locale values are defined in `Language` enum:
- `Language.vi` → locale `"vi-VN"`
- `Language.en` → locale `"en-US"`

## Default Constants (`app_constants.dart`)

| Parameter | Default |
|---|---|
| Rate | 0.5 |
| Pitch | 1.0 |
| Volume | 1.0 |

## Usage in Bloc

- Auto-play on recording stop: `Bloc` dispatches `PlaybackRequested(text, sourceLanguage)`
- Manual play: User taps speaker icon on any `TranscriptCard` → dispatches `PlaybackRequested(text, language)`
- Language determines which TTS voice is used
