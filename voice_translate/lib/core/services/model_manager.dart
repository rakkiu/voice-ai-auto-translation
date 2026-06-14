import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import '../constants/app_constants.dart';

class ModelManager {
  static Future<String> getWhisperModelPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/models/${AppConstants.whisperModelFileName}';
  }

  static Future<bool> isWhisperModelReady() async {
    final path = await getWhisperModelPath();
    return File(path).exists();
  }

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
