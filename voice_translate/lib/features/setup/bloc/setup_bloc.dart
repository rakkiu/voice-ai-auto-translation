import 'dart:io';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/services/model_manager.dart';
import '../../../core/di/injection.dart';
import '../../../core/services/stt/stt_service.dart';
import '../../../core/services/llm/llm_service.dart';
import 'setup_event.dart';
import 'setup_state.dart';

class SetupBloc extends Bloc<SetupEvent, SetupState> {
  SetupBloc() : super(const SetupState()) {
    on<SetupStarted>(_onSetupStarted);
  }

  Future<void> _onSetupStarted(
    SetupStarted event,
    Emitter<SetupState> emit,
  ) async {
    emit(state.copyWith(status: SetupStatus.checkingModels));

    try {
      // 1. Kiểm tra RAM
      final hasRam = await _checkSufficientRam();
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
        status: SetupStatus.loadingModels,
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

  Future<bool> _checkSufficientRam() async {
    try {
      final memInfo = await File('/proc/meminfo').readAsString();
      final match = RegExp(r'MemAvailable:\s+(\d+)').firstMatch(memInfo);
      if (match != null) {
        final availableKb = int.parse(match.group(1)!);
        final availableMb = availableKb ~/ 1024;
        return availableMb >= 2500;
      }
    } catch (_) {}
    return true;
  }
}
