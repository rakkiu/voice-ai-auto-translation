# Speech-to-Text Pipeline

## Architecture

```
[Microphone] → AudioRecorder (record package) → 16kHz mono WAV file
                                              → MethodChannel ("com.voicetranslate/whisper")
                                                → Kotlin WhisperChannel.kt
                                                  → whisper.cpp JNI (not yet integrated)
```

## Recording Config

All constants in `app_constants.dart`:

| Parameter | Value | Reason |
|---|---|---|
| Sample rate | 16000 Hz | Whisper requirement |
| Channels | 1 (mono) | Whisper requirement |
| Encoder | WAV | Simplest format for file-based inference |
| Bit rate | 128000 | Standard WAV 16-bit |
| Max duration | 30s | Hard limit per recording session |
| Silence threshold | 0.02 | Amplitude below which considered silence |

## AudioRecorder Usage (`whisper_stt_service.dart`)

1. **startRecording()** — Creates temp file path at `getTemporaryDirectory()/whisper_input.wav`, deletes any existing file, calls `_recorder.start(RecordConfig(...), path: ...)`.
2. **stopRecordingAndTranscribe()** — Calls `_recorder.stop()`, then invokes `_channel.invokeMethod('transcribe', { audioPath, language })`.
3. **cancelRecording()** — Calls `_recorder.stop()` without transcribing.

## Native Bridge (`WhisperChannel.kt`)

Registered in `MainActivity.configureFlutterEngine()`. Handles three methods:

- **loadModel** — Receives `modelPath` string. Should call `whisper_init_from_file()`. Currently returns `true`.
- **transcribe** — Receives `audioPath` + `language`. Should call `whisper_full()`. Currently returns placeholder string `"[Whisper JNI not yet integrated]"`.
- **release** — Should free native context. Returns `true`.

## Model Management (`model_manager.dart`)

- `getWhisperModelPath()` — Returns `{appDocDir}/models/ggml-base.bin`
- `isWhisperModelReady()` — Checks file existence
- `downloadWhisperModel(onProgress)` — HTTP GET from HuggingFace, streams to file with progress callback (~142MB for base model)

## Upcoming: Real JNI Integration

The sprint plan specifies building an AAR from `ggerganov/whisper.cpp` Android example (`whisper.cpp/examples/whisper.android/`) and calling:
- `WhisperJNI.initFromFile(modelPath)` → returns native pointer
- `WhisperJNI.transcribe(pointer, audioPath, language)` → returns text
- `WhisperJNI.free(pointer)` → cleanup
