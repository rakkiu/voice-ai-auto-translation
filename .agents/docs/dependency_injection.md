# Dependency Injection

## Tool

`get_it` (v7.7.0) — service locator. Singleton instance `sl`.

## Setup (`injection.dart`)

```dart
final GetIt sl = GetIt.instance;

Future<void> setupDependencies() async {
  sl.registerLazySingleton<Logger>(() => Logger(
    printer: PrettyPrinter(methodCount: 2, errorMethodCount: 5),
  ));

  sl.registerLazySingleton<SttService>(
    () => WhisperSttService(logger: sl<Logger>()),
  );

  sl.registerLazySingleton<TtsService>(
    () => FlutterTtsService(logger: sl<Logger>()),
  );
}
```

Called once in `main.dart` before `runApp`:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  await Permission.microphone.request();
  runApp(const VoiceTranslateApp());
}
```

## Resolution

Accessed via `sl<T>()`:

```dart
// In app.dart:
TranslatorBloc(sttService: sl<SttService>(), ttsService: sl<TtsService>())

// Inside service implementations:
WhisperSttService(logger: sl<Logger>())
```

## Rules

- All services registered as `LazySingleton` — created on first access, kept for app lifetime.
- To swap implementations (e.g., replace Whisper with system STT), create a new class implementing `SttService` and change the registration.
- `Logger` is injected rather than instantiated directly to keep consistent formatting across the app.
