import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/di/injection.dart';
import 'core/services/stt/stt_service.dart';
import 'core/services/tts/tts_service.dart';
import 'features/translator/bloc/translator_bloc.dart';
import 'features/translator/pages/translator_page.dart';

class VoiceTranslateApp extends StatelessWidget {
  const VoiceTranslateApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoiceTranslate',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF10B981),
        ),
      ),
      home: BlocProvider(
        create: (_) => TranslatorBloc(
          sttService: sl<SttService>(),
          ttsService: sl<TtsService>(),
        ),
        child: const TranslatorPage(),
      ),
    );
  }
}
