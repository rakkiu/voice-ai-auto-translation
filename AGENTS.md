# AGENTS.md — Voice AI Auto Translation

## Project Overview

Offline Vietnamese ↔ English speech translation app built with Flutter. Entire AI pipeline (STT → LLM → TTS) runs on-device — no cloud calls, no internet required. Currently in Sprint 1: foundation with STT recording, TTS playback, and UI shell.

## Tech Stack

| Layer | Tech | Version |
|---|---|---|
| Framework | Flutter | 3.41.9 (Dart 3.11.5) |
| Platform | Android only | minSdk 26, targetSdk 34 |
| State Management | flutter_bloc | ^8.1.4 |
| Equality | equatable | ^2.0.5 |
| STT Recording | record | ^6.0.0 |
| TTS | flutter_tts | ^4.0.2 |
| DI | get_it | ^7.7.0 |
| Permissions | permission_handler | ^11.3.0 |
| Logging | logger | ^2.3.0 |
| Native Bridge | MethodChannel | `com.voicetranslate/whisper` |

## Dev Commands

```sh
# Run on connected device/emulator
flutter run

# Build APK (debug)
flutter build apk --debug

# Build APK (release)
flutter build apk --release

# Run tests
flutter test

# Analyze code
flutter analyze
```

*Run all commands from `voice_translate/` directory.*

## Core Logic Summary

Pipeline: **Record audio (16kHz mono WAV) → STT (Whisper.cpp via MethodChannel) → LLM (Sprint 2) → TTS (flutter_tts)**. Bloc orchestrates async stages: recording → transcribing → translating (future) → speaking → idle. Language toggle swaps source/target and their displayed texts.

## Branch Management

- **Never commit directly on `main`** — always work on a new branch.
- **Bug branches**: `bug/[desc]` (e.g., `bug/fix-crash-on-empty-transcript`).
- **Feature branches**: `feature/[desc]` (e.g., `feature/add-language-toggle`).
- **Never push directly to `main`** — open a PR for review.

## Key Constraints

- **Do NOT remove `android:largeHeap="true"`** from AndroidManifest — required for model inference.
- **Do NOT change sample rate (16000) or channels (1)** — Whisper hard requirement.
- **Do NOT add iOS-specific code** — Android only until explicitly scoped.
- **Do NOT bundle model files** in git — downloaded at runtime via `ModelManager`. Only `.gitkeep` in `assets/models/`.
- **Do NOT use `http` package** in production UI code — only in `ModelManager` for downloading models.
- **Do NOT bypass the abstract service interfaces** (`SttService`, `TtsService`) — all implementations must implement them for swappability.
- **Do NOT commit secrets or API keys** — the app is fully offline with no cloud services.

## Additional Documentation

| File | Contents |
|---|---|
| [Architecture](.agents/docs/architecture.md) | Directory structure, layering, data flow, native bridge |
| [State Management](.agents/docs/state_management.md) | Bloc events, state, handlers |
| [STT Pipeline](.agents/docs/stt_pipeline.md) | Recording config, Whisper integration, model download |
| [TTS Service](.agents/docs/tts_service.md) | flutter_tts setup, locale mapping, defaults |
| [Dependency Injection](.agents/docs/dependency_injection.md) | GetIt registration, resolution pattern |
| [Permissions](.agents/docs/permissions.md) | Android manifest + runtime permission flow |
