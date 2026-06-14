import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/setup_bloc.dart';
import '../bloc/setup_event.dart';
import '../bloc/setup_state.dart';
import '../../translator/pages/translator_page.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});
  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  @override
  void initState() {
    super.initState();
    context.read<SetupBloc>().add(SetupStarted());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: BlocConsumer<SetupBloc, SetupState>(
        listener: (context, state) {
          if (state.allReady) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const TranslatorPage()),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.translate,
                      color: Color(0xFF6366F1), size: 64),
                  const SizedBox(height: 24),
                  const Text(
                    'VoiceTranslate',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (state.status == SetupStatus.error)
                    Text(
                      state.errorMessage ?? 'Lỗi không xác định',
                      style: const TextStyle(color: Colors.redAccent),
                      textAlign: TextAlign.center,
                    )
                  else
                    Text(
                      'Đang khởi tạo AI models...',
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 14),
                      textAlign: TextAlign.center,
                    ),
                  const SizedBox(height: 48),
                  if (state.status == SetupStatus.checkingModels ||
                      state.status == SetupStatus.copyingModels ||
                      state.status == SetupStatus.loadingModels)
                    _buildLoadingUI(state)
                  else if (state.status == SetupStatus.error)
                    _buildErrorUI(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildLoadingUI(SetupState state) {
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
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: state.progress,
              backgroundColor: Colors.white12,
              color: const Color(0xFF6366F1),
              minHeight: 6,
            ),
          ),
        const SizedBox(height: 8),
        const Text(
          'Chỉ cần làm lần đầu — sẽ nhanh hơn những lần sau',
          style: TextStyle(color: Colors.white38, fontSize: 12),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildErrorUI() {
    return Column(
      children: [
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: () =>
              context.read<SetupBloc>().add(SetupStarted()),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366F1),
            foregroundColor: Colors.white,
          ),
          child: const Text('Thử lại'),
        ),
      ],
    );
  }
}
