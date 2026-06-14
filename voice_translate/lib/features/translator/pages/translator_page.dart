import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/translator_bloc.dart';
import '../bloc/translator_event.dart';
import '../bloc/translator_state.dart';
import '../widgets/language_toggle.dart';
import '../widgets/mic_button.dart';
import '../widgets/transcript_card.dart';

class TranslatorPage extends StatelessWidget {
  const TranslatorPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'VoiceTranslate',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings, color: Colors.white54),
            onPressed: () {},
          ),
        ],
      ),
      body: BlocConsumer<TranslatorBloc, TranslatorState>(
        listener: (context, state) {
          if (state.status == TranslatorStatus.error &&
              state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage!),
                backgroundColor: Colors.redAccent,
              ),
            );
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Column(
              children: [
                LanguageToggleWidget(
                  sourceLanguage: state.sourceLanguage,
                  targetLanguage: state.targetLanguage,
                  onToggle: () =>
                      context.read<TranslatorBloc>().add(LanguageToggled()),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: TranscriptCard(
                    label: state.sourceLanguage.displayName,
                    text: state.originalText,
                    isLoading: state.status == TranslatorStatus.transcribing,
                    onSpeak: state.originalText.isNotEmpty
                        ? () => context.read<TranslatorBloc>().add(
                              PlaybackRequested(
                                text: state.originalText,
                                language: state.sourceLanguage,
                              ),
                            )
                        : null,
                  ),
                ),
                const Divider(color: Colors.white12, height: 1),
                Expanded(
                  child: TranscriptCard(
                    label: state.targetLanguage.displayName,
                    text: state.translatedText,
                    isLoading: state.status == TranslatorStatus.translating,
                    onSpeak: state.translatedText.isNotEmpty
                        ? () => context.read<TranslatorBloc>().add(
                              PlaybackRequested(
                                text: state.translatedText,
                                language: state.targetLanguage,
                              ),
                            )
                        : null,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: MicButton(
                    isRecording: state.isRecording,
                    isProcessing: state.isProcessing,
                    onRecordStart: () =>
                        context.read<TranslatorBloc>().add(RecordingStarted()),
                    onRecordStop: () =>
                        context.read<TranslatorBloc>().add(RecordingStopped()),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
