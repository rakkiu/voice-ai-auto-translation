# Sprint Revision — Bundled Models (No Download Required)

> **Lý do thay đổi:** Thay vì yêu cầu user tải model khi lần đầu mở app, cả 2 model **Whisper (STT)** và **Gemma 2B (LLM)** sẽ được đóng gói sẵn trong APK/Bundle. User cài app xong → dùng ngay, không cần internet, không cần chờ.

---

## 0. Tóm Tắt Thay Đổi

| Hạng mục | Trước (Sprint 1–2 cũ) | Sau (Revision này) |
|---|---|---|
| **Whisper model** | Download lần đầu (~142MB) | Bundle sẵn trong `assets/models/` |
| **Gemma 2B model** | Download lần đầu (~1.4GB) | Bundle sẵn trong `assets/models/` |
| **SetupPage** | Hiện progress download | Chỉ hiện loading spinner init model |
| **ModelManager** | Download + verify file | Chỉ copy từ assets → local path |
| **Internet permission** | Cần cho download | Có thể bỏ hoàn toàn |
| **APK size** | ~50MB (model download sau) | ~1.6GB (model trong bundle) |
| **UX lần đầu** | Chờ download 5–30 phút | Khởi động ~10–20s để init model |

> ⚠️ **Lưu ý APK size:** APK ~1.6GB sẽ vượt giới hạn Play Store (100MB). Cần dùng **Play Asset Delivery (PAD)** hoặc **APK split** để phân phối model. Xem chi tiết mục 6.

---

## 1. Các File Cần Thay Đổi

### 1.1 `pubspec.yaml` — Khai báo assets model

**Xoá:**
```yaml
dependencies:
  http: ^1.2.1
  dio: ^5.4.3
```

**Sửa block `flutter.assets`:**
```yaml
flutter:
  uses-material-design: true
  assets:
    - assets/models/ggml-base.bin          # Whisper base model (~142MB)
    - assets/models/gemma-2b-it-cpu-int4.bin  # Gemma 2B INT4 (~1.4GB)
    - assets/icon/
    - assets/splash/
```

> **Chuẩn bị file model:**
> - `ggml-base.bin` — tải từ https://huggingface.co/ggerganov/whisper.cpp
> - `gemma-2b-it-cpu-int4.bin` — tải từ Kaggle (google/gemma), cần accept license
> - Đặt cả 2 vào `assets/models/` trong project root

---

### 1.2 `lib/core/constants/app_constants.dart` — Xoá URL, thêm asset paths

**Xoá hoàn toàn:**
```dart
static const String whisperModelUrl = 'https://...';
static const String gemmaModelUrl   = 'YOUR_GEMMA_DOWNLOAD_URL_HERE';
```

**Thêm vào:**
```dart
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
```

---

### 1.3 `lib/core/services/model_manager.dart` — Thay download bằng asset copy

**Xoá toàn bộ logic download.** Viết lại file này:

```dart
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

/// Quản lý việc copy model từ Flutter assets → local storage.
/// Model được bundle sẵn trong app, không cần download.
class ModelManager {

  // ─── Whisper ───────────────────────────────────────────────

  static Future<String> getWhisperModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${AppConstants.modelsSubDir}/${AppConstants.whisperModelFileName}';
  }

  static Future<bool> isWhisperModelReady() async {
    final path = await getWhisperModelPath();
    return File(path).existsSync();
  }

  /// Copy Whisper model từ assets → local storage (chỉ lần đầu).
  /// [onProgress]: callback 0.0–1.0 (optional, để hiện spinner)
  static Future<void> prepareWhisperModel({
    void Function(double progress)? onProgress,
  }) async {
    final destPath = await getWhisperModelPath();
    await _copyAssetToLocal(
      assetPath: AppConstants.whisperAssetPath,
      destPath: destPath,
      onProgress: onProgress,
    );
  }

  // ─── Gemma ────────────────────────────────────────────────

  static Future<String> getGemmaModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${AppConstants.modelsSubDir}/${AppConstants.gemmaModelFileName}';
  }

  static Future<bool> isGemmaModelReady() async {
    final path = await getGemmaModelPath();
    return File(path).existsSync();
  }

  /// Copy Gemma model từ assets → local storage (chỉ lần đầu).
  static Future<void> prepareGemmaModel({
    void Function(double progress)? onProgress,
  }) async {
    final destPath = await getGemmaModelPath();
    await _copyAssetToLocal(
      assetPath: AppConstants.gemmaAssetPath,
      destPath: destPath,
      onProgress: onProgress,
    );
  }

  // ─── Helper ───────────────────────────────────────────────

  /// Copy 1 asset file → local path.
  /// Bỏ qua nếu file đã tồn tại (idempotent).
  static Future<void> _copyAssetToLocal({
    required String assetPath,
    required String destPath,
    void Function(double progress)? onProgress,
  }) async {
    final destFile = File(destPath);
    if (destFile.existsSync()) return; // Đã copy rồi, skip

    // Tạo thư mục nếu chưa có
    final dir = destFile.parent;
    if (!dir.existsSync()) await dir.create(recursive: true);

    onProgress?.call(0.0);

    // Load từ asset bundle
    final byteData = await rootBundle.load(assetPath);
    final bytes = byteData.buffer.asUint8List();

    onProgress?.call(0.5);

    // Ghi ra file
    await destFile.writeAsBytes(bytes, flush: true);

    onProgress?.call(1.0);
  }

  /// Xoá cả 2 model khỏi local storage (debug / reset).
  static Future<void> clearAll() async {
    final whisperPath = await getWhisperModelPath();
    final gemmaPath   = await getGemmaModelPath();
    for (final path in [whisperPath, gemmaPath]) {
      final file = File(path);
      if (file.existsSync()) await file.delete();
    }
  }
}
```

> **Tại sao copy ra local thay vì đọc thẳng từ assets?**
> Whisper.cpp và MediaPipe LLM đều cần đường dẫn **file path tuyệt đối** trên filesystem để mmap model vào memory. Flutter asset bundle không expose file path trực tiếp — cần copy ra `getApplicationDocumentsDirectory()` trước.

---

### 1.4 `lib/features/setup/bloc/setup_bloc.dart` — Thay download bằng copy

**Cập nhật `_onSetupStarted`:**

```dart
Future<void> _onSetupStarted(
  SetupStarted event,
  Emitter<SetupState> emit,
) async {
  emit(state.copyWith(status: SetupStatus.checkingModels));

  try {
    // 1. Kiểm tra RAM
    final hasRam = await checkSufficientRam();
    if (!hasRam) {
      emit(state.copyWith(
        status: SetupStatus.error,
        errorMessage: 'Không đủ RAM. Đóng bớt ứng dụng và thử lại.',
      ));
      return;
    }

    // 2. Chuẩn bị Whisper model (copy từ assets nếu chưa có)
    emit(state.copyWith(
      status: SetupStatus.copyingModels,
      progressMessage: 'Đang khởi tạo Whisper...',
      progress: 0.0,
    ));

    if (!await ModelManager.isWhisperModelReady()) {
      await ModelManager.prepareWhisperModel(
        onProgress: (p) => emit(state.copyWith(progress: p * 0.4)),
      );
    } else {
      emit(state.copyWith(progress: 0.4));
    }

    // 3. Chuẩn bị Gemma model (copy từ assets nếu chưa có)
    emit(state.copyWith(
      progressMessage: 'Đang khởi tạo Gemma...',
      progress: 0.4,
    ));

    if (!await ModelManager.isGemmaModelReady()) {
      await ModelManager.prepareGemmaModel(
        onProgress: (p) => emit(state.copyWith(progress: 0.4 + p * 0.4)),
      );
    } else {
      emit(state.copyWith(progress: 0.8));
    }

    // 4. Load Whisper vào memory
    emit(state.copyWith(
      progressMessage: 'Đang nạp mô hình vào bộ nhớ...',
      progress: 0.8,
    ));
    final whisperPath = await ModelManager.getWhisperModelPath();
    await sl<SttService>().initialize(modelPath: whisperPath);

    // 5. Load Gemma vào memory
    emit(state.copyWith(progress: 0.9));
    final gemmaPath = await ModelManager.getGemmaModelPath();
    await sl<LlmService>().initialize(modelPath: gemmaPath);

    emit(state.copyWith(
      status: SetupStatus.ready,
      progress: 1.0,
    ));

  } catch (e) {
    emit(state.copyWith(
      status: SetupStatus.error,
      errorMessage: 'Lỗi khởi tạo: $e\nThử khởi động lại app.',
    ));
  }
}
```

**Thêm `SetupStatus.copyingModels` vào enum:**
```dart
enum SetupStatus {
  initial,
  checkingModels,
  copyingModels,    // ← MỚI: đang copy từ assets
  loadingModels,
  ready,
  error,
}
```

---

### 1.5 `lib/features/setup/pages/setup_page.dart` — Cập nhật UI

Thay **download progress UI** bằng **initialization loading UI**. Không cần hiện download speed hay eta.

```dart
// Trong _buildBody() của SetupPage:

case SetupStatus.copyingModels:
case SetupStatus.loadingModels:
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const CircularProgressIndicator(color: Color(0xFF6366F1)),
      const SizedBox(height: 24),
      Text(
        state.progressMessage ?? 'Đang khởi tạo...',
        style: const TextStyle(color: Colors.white70, fontSize: 16),
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 12),
      if (state.progress != null)
        LinearProgressIndicator(
          value: state.progress,
          backgroundColor: Colors.white12,
          color: const Color(0xFF6366F1),
        ),
      const SizedBox(height: 8),
      const Text(
        'Chỉ cần làm lần đầu — sẽ nhanh hơn những lần sau',
        style: TextStyle(color: Colors.white38, fontSize: 12),
        textAlign: TextAlign.center,
      ),
    ],
  );

// Xoá hoàn toàn các case: downloading, downloadError, retrying
```

---

### 1.6 `AndroidManifest.xml` — Xoá Internet permission

```xml
<!-- XOÁ dòng này nếu app không cần internet cho mục đích nào khác -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- XOÁ permission storage nếu không cần -->
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" ... />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" ... />
```

> **Giữ lại:** `RECORD_AUDIO` (bắt buộc cho STT)

---

### 1.7 `lib/core/di/injection.dart` — Xoá http/dio

Không cần thay đổi gì thêm ngoài việc xoá import `http`/`dio` nếu có dùng trong file này.

---

## 2. Các File / Feature Cần XOÁ

| File/Feature | Lý do xoá |
|---|---|
| `ModelManager.downloadWhisperModel()` | Không còn download |
| `ModelManager.downloadGemmaModel()` | Không còn download |
| `SetupBloc` — handler `DownloadRequested` | Không còn download |
| `SetupState` — field `downloadSpeed`, `eta` | Không còn cần |
| `SetupPage` — `_buildDownloadProgress()` widget | Không còn hiện progress download |
| `SetupStatus.downloading` | Thay bằng `copyingModels` |
| `SetupStatus.downloadError` | Thay bằng generic `error` |
| `pubspec.yaml` — `http`, `dio`, `percent_indicator` (nếu chỉ dùng cho download) | Không còn cần |

---

## 3. Các File KHÔNG Thay Đổi

Các file sau **giữ nguyên 100%**, không cần sửa:

- `lib/core/models/language.dart`
- `lib/core/models/translation_session.dart`
- `lib/core/services/stt/stt_service.dart` (interface)
- `lib/core/services/stt/whisper_stt_service.dart`
- `lib/core/services/llm/llm_service.dart` (interface)
- `lib/core/services/llm/gemma_mediapipe_service.dart`
- `lib/core/services/tts/tts_service.dart`
- `lib/core/services/tts/flutter_tts_service.dart`
- `lib/features/translator/` (toàn bộ)
- `lib/features/history/` (toàn bộ)
- `lib/features/settings/` (toàn bộ)
- `android/app/src/main/kotlin/.../MediaPipeLlmChannel.kt`
- `android/app/src/main/kotlin/.../WhisperChannel.kt`
- `lib/core/database/`
- Sprint 3 features (History, Settings, UX Polish) — **giữ nguyên**

---

## 4. Thứ Tự Thực Hiện (cho AI Coding Agent)

```
Bước 1 — Chuẩn bị model files (MANUAL, ngoài code)
  → Tải ggml-base.bin từ Hugging Face
  → Tải gemma-2b-it-cpu-int4.bin từ Kaggle
  → Đặt vào assets/models/ trong project
  → Chạy: flutter pub get (để Flutter nhận assets mới)

Bước 2 — Sửa pubspec.yaml
  → Thêm assets/models/ vào flutter.assets block
  → Xoá http, dio khỏi dependencies

Bước 3 — Sửa AppConstants
  → Xoá các *Url constants
  → Thêm *AssetPath constants

Bước 4 — Viết lại ModelManager
  → Xoá toàn bộ download logic
  → Thêm _copyAssetToLocal() helper
  → Thêm prepareWhisperModel() và prepareGemmaModel()

Bước 5 — Cập nhật SetupBloc
  → Thêm SetupStatus.copyingModels vào enum
  → Xoá download handler
  → Viết lại _onSetupStarted() dùng ModelManager.prepare*()

Bước 6 — Cập nhật SetupPage UI
  → Xoá download progress widgets
  → Thêm init loading UI đơn giản

Bước 7 — Sửa AndroidManifest.xml
  → Xoá INTERNET permission (và STORAGE nếu không dùng)

Bước 8 — Test
  → flutter clean && flutter pub get
  → flutter run (lần đầu: model sẽ được copy ~10–20s)
  → flutter run (lần 2+: model đã có → boot ngay)
```

---

## 5. Edge Cases Cần Xử Lý

### 5.1 App Update — Model bị thay đổi version

Khi ship bản app mới có model version khác, cần detect và re-copy:

```dart
// Thêm vào AppConstants:
static const String whisperModelVersion = 'base-v1';
static const String gemmaModelVersion   = '2b-it-int4-v1';

// Trong ModelManager — check version trước khi skip copy:
static Future<bool> _isModelVersionMatch(
  String localPath,
  String expectedVersion,
) async {
  // Option đơn giản: lưu version string vào file .version cạnh model
  final versionFile = File('$localPath.version');
  if (!versionFile.existsSync()) return false;
  return (await versionFile.readAsString()).trim() == expectedVersion;
}

// Sau khi copy xong, ghi version:
await File('$destPath.version').writeAsString(expectedVersion);
```

### 5.2 Copy bị interrupt (app crash giữa chừng)

```dart
// Copy vào file .tmp trước, rename sau khi xong — atomic write:
final tmpPath = '$destPath.tmp';
await File(tmpPath).writeAsBytes(bytes, flush: true);
await File(tmpPath).rename(destPath); // atomic trên cùng filesystem
```

### 5.3 Storage không đủ chỗ

```dart
// Kiểm tra free space trước khi copy (cần plugin disk_space hoặc df)
// Thêm dependency: disk_space: ^2.0.0

// Hoặc check đơn giản qua try-catch khi writeAsBytes:
try {
  await destFile.writeAsBytes(bytes, flush: true);
} on FileSystemException catch (e) {
  if (e.osError?.errorCode == 28) { // ENOSPC
    throw Exception('Không đủ dung lượng. Cần thêm ~1.6GB trống.');
  }
  rethrow;
}
```

---

## 6. Vấn Đề Phân Phối APK (~1.6GB)

APK 1.6GB **không thể upload lên Play Store** (giới hạn 100MB AAB content, 150MB APK). Có 3 hướng:

### Option A — Play Asset Delivery (PAD) ✅ Khuyến nghị

Google Play tự phân phối model file riêng, app tải về khi install hoặc on-demand.

```
android/app/src/main/
├── assets/          ← giữ assets thường
└── play/
    └── asset-packs/
        └── model_pack/
            └── src/main/assets/models/
                ├── ggml-base.bin
                └── gemma-2b-it-cpu-int4.bin
```

```groovy
// android/app/build.gradle
android {
    assetPacks = [":model_pack"]
}
```

```kotlin
// Trong MainActivity.kt — request asset pack khi cần
val assetPackManager = AssetPackManagerFactory.getInstance(this)
```

> PAD vẫn bundle model trong app nhưng Play Store xử lý delivery. User vẫn "không cần tải thêm" sau khi install.

### Option B — Sideload APK trực tiếp (không qua Play Store)

Nếu không phân phối qua Play Store, APK 1.6GB hoàn toàn hợp lệ để share trực tiếp. Không có giới hạn size.

### Option C — Giữ model nhỏ hơn

| Swap | Model mới | Size |
|---|---|---|
| Whisper base → Whisper tiny | `ggml-tiny.bin` | ~75MB |
| Gemma 2B → Gemma 1.1 1B INT4 | `gemma-1.1-1b-it-int4.bin` | ~700MB |
| **Tổng** | | **~775MB** |

Chất lượng dịch giảm nhẹ nhưng vẫn chấp nhận được cho VI↔EN cơ bản.

---

## 7. Checklist Revision

**Chuẩn bị (Manual):**
- [ ] Tải `ggml-base.bin` từ Hugging Face, đặt vào `assets/models/`
- [ ] Tải `gemma-2b-it-cpu-int4.bin` từ Kaggle, đặt vào `assets/models/`
- [ ] Chạy `flutter pub get`

**Code changes:**
- [ ] Sửa `pubspec.yaml` — thêm assets, xoá http/dio
- [ ] Sửa `AppConstants` — xoá URL, thêm asset paths
- [ ] Viết lại `ModelManager` — copy-from-assets logic
- [ ] Thêm `SetupStatus.copyingModels` vào enum
- [ ] Cập nhật `SetupBloc._onSetupStarted()`
- [ ] Cập nhật `SetupPage` — xoá download UI, thêm init UI
- [ ] Sửa `AndroidManifest.xml` — xoá INTERNET permission
- [ ] Implement atomic write (`.tmp` → rename)
- [ ] Implement version check cho app update

**Test:**
- [ ] `flutter clean && flutter pub get && flutter run`
- [ ] Lần đầu: model copy ~10–20s → pipeline chạy bình thường
- [ ] Lần 2+: skip copy → boot nhanh hơn
- [ ] Uninstall → reinstall: model copy lại đúng
- [ ] Low storage test: xử lý lỗi ENOSPC gracefully
- [ ] `flutter build apk --release` thành công

---

## 8. Definition of Done — Revision

> Revision hoàn thành khi:
> 1. Cài app xong → mở lên → model sẵn sàng sau ~10–20s, không cần internet ✅
> 2. Lần 2 mở app → model đã có → không copy lại, boot ngay ✅
> 3. Pipeline STT → LLM → TTS hoạt động bình thường như Sprint 2 ✅
> 4. Không có code nào gọi HTTP download model nữa ✅
> 5. `INTERNET` permission đã xoá khỏi Manifest (nếu không dùng cho mục đích khác) ✅
> 6. App không crash khi storage đầy — hiện thông báo lỗi rõ ràng ✅
