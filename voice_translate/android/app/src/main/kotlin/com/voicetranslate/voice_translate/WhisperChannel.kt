package com.voicetranslate.voice_translate

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

class WhisperChannel(private val context: Context, flutterEngine: FlutterEngine) {

    private var whisperContext: Long = 0L

    init {
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "com.voicetranslate/whisper")
        channel.setMethodCallHandler { call, result ->
            handleMethodCall(call, result)
        }
    }

    private fun handleMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadModel" -> {
                val modelPath = call.argument<String>("modelPath")
                if (modelPath == null) {
                    result.error("INVALID_ARGS", "modelPath is required", null)
                    return
                }
                try {
                    // TODO: implement whisper_init_from_file(modelPath) via JNI
                    // whisperContext = WhisperJNI.initFromFile(modelPath)
                    result.success(true)
                } catch (e: Exception) {
                    result.error("LOAD_FAILED", "Failed to load model: ${e.message}", null)
                }
            }
            "transcribe" -> {
                val audioPath = call.argument<String>("audioPath")
                val language = call.argument<String>("language") ?: "auto"
                if (audioPath == null) {
                    result.error("INVALID_ARGS", "audioPath is required", null)
                    return
                }
                try {
                    // TODO: implement whisper_full() via JNI
                    // val text = WhisperJNI.transcribe(whisperContext, audioPath, language)
                    // For now return a placeholder
                    result.success("[Whisper JNI not yet integrated]")
                } catch (e: Exception) {
                    result.error("TRANSCRIBE_FAILED", "Transcription failed: ${e.message}", null)
                }
            }
            "release" -> {
                try {
                    // TODO: implement whisper_free(whisperContext) via JNI
                    // WhisperJNI.free(whisperContext)
                    whisperContext = 0L
                    result.success(true)
                } catch (e: Exception) {
                    result.error("RELEASE_FAILED", "Release failed: ${e.message}", null)
                }
            }
            else -> result.notImplemented()
        }
    }
}
