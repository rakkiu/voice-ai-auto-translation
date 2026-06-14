import 'package:get_it/get_it.dart';
import 'package:logger/logger.dart';
import '../services/stt/stt_service.dart';
import '../services/stt/whisper_stt_service.dart';
import '../services/tts/tts_service.dart';
import '../services/tts/flutter_tts_service.dart';

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
