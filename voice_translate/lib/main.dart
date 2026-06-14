import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/di/injection.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await setupDependencies();

  await Permission.microphone.request();

  runApp(const VoiceTranslateApp());
}
