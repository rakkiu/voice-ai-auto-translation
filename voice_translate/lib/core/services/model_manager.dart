import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

final _assetCopyChannel = const MethodChannel('com.voicetranslate/asset_copy');

class ModelManager {
  ModelManager._();

  // ─── Whisper ───────────────────────────────────────────────

  static Future<String> getWhisperModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/${AppConstants.modelsSubDir}/${AppConstants.whisperModelFileName}';
  }

  static Future<bool> isWhisperModelReady() async {
    final path = await getWhisperModelPath();
    return File(path).existsSync();
  }

  static Future<void> prepareWhisperModel({
    void Function(double progress)? onProgress,
  }) async {
    final destPath = await getWhisperModelPath();
    await _copyAssetToLocal(
      assetPath: AppConstants.whisperAssetPath,
      destPath: destPath,
      version: AppConstants.whisperModelVersion,
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

  static Future<void> prepareGemmaModel({
    void Function(double progress)? onProgress,
  }) async {
    final destPath = await getGemmaModelPath();
    await _copyAssetToLocal(
      assetPath: AppConstants.gemmaAssetPath,
      destPath: destPath,
      version: AppConstants.gemmaModelVersion,
      onProgress: onProgress,
    );
  }

  // ─── Helper ───────────────────────────────────────────────

  static Future<bool> _isModelVersionMatch(
    String localPath,
    String expectedVersion,
  ) async {
    final versionFile = File('$localPath.version');
    if (!versionFile.existsSync()) return false;
    return (await versionFile.readAsString()).trim() == expectedVersion;
  }

  static Future<void> _copyAssetToLocal({
    required String assetPath,
    required String destPath,
    String? version,
    void Function(double progress)? onProgress,
  }) async {
    final destFile = File(destPath);

    // Nếu file đã tồn tại, check version để quyết định có re-copy không
    if (destFile.existsSync()) {
      if (version != null) {
        final match = await _isModelVersionMatch(destPath, version);
        if (match) return;
      } else {
        return;
      }
    }

    // Tạo thư mục nếu chưa có
    final dir = destFile.parent;
    if (!dir.existsSync()) await dir.create(recursive: true);

    onProgress?.call(0.0);

    // Ưu tiên copy qua native Android AssetManager (chunked stream, không OOM)
    try {
      await _assetCopyChannel.invokeMethod('copyAsset', {
        'assetPath': assetPath,
        'destPath': destPath,
      });
    } catch (_) {
      // Fallback: copy qua Dart (dùng cho non-Android hoặc debug)
      final byteData = await rootBundle.load(assetPath);
      final bytes = byteData.buffer.asUint8List();
      final tmpPath = '$destPath.tmp';
      try {
        await File(tmpPath).writeAsBytes(bytes, flush: true);
        await File(tmpPath).rename(destPath);
      } on FileSystemException catch (e) {
        if (e.osError?.errorCode == 28) {
          throw Exception('Không đủ dung lượng. Cần thêm ~1.6GB trống.');
        }
        rethrow;
      }
    }

    // Ghi version file
    if (version != null) {
      await File('$destPath.version').writeAsString(version);
    }

    onProgress?.call(1.0);
  }

  /// Xoá cả 2 model khỏi local storage (debug / reset).
  static Future<void> clearAll() async {
    final whisperPath = await getWhisperModelPath();
    final gemmaPath = await getGemmaModelPath();
    for (final path in [whisperPath, gemmaPath]) {
      final file = File(path);
      if (file.existsSync()) await file.delete();
      final versionFile = File('$path.version');
      if (versionFile.existsSync()) await versionFile.delete();
    }
  }
}
