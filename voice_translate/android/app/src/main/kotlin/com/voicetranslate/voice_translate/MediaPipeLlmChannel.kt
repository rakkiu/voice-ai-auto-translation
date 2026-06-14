package com.voicetranslate.voice_translate

import android.content.Context
import com.google.mediapipe.tasks.genai.llminference.LlmInference
import com.google.mediapipe.tasks.genai.llminference.LlmInference.LlmInferenceOptions
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch

class MediaPipeLlmChannel(
    private val context: Context,
    flutterEngine: FlutterEngine
) : MethodChannel.MethodCallHandler {

    private var llmInference: LlmInference? = null
    private val scope = CoroutineScope(Dispatchers.IO)

    init {
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.voicetranslate/mediapipe_llm"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "loadModel" -> loadModel(call, result)
            "generate"  -> generate(call, result)
            "release"   -> release(result)
            else        -> result.notImplemented()
        }
    }

    private fun loadModel(call: MethodCall, result: MethodChannel.Result) {
        scope.launch {
            try {
                val modelPath  = call.argument<String>("modelPath")!!
                val maxTokens  = call.argument<Int>("maxTokens") ?: 512
                val topK       = call.argument<Int>("topK") ?: 40
                val temperature = call.argument<Double>("temperature")?.toFloat() ?: 0.3f
                val seed       = call.argument<Int>("randomSeed") ?: 42

                val options = LlmInferenceOptions.builder()
                    .setModelPath(modelPath)
                    .setMaxTokens(maxTokens)
                    .setTopK(topK)
                    .setTemperature(temperature)
                    .setRandomSeed(seed)
                    .build()

                llmInference?.close()
                llmInference = LlmInference.createFromOptions(context, options)

                CoroutineScope(Dispatchers.Main).launch {
                    result.success(true)
                }
            } catch (e: Exception) {
                CoroutineScope(Dispatchers.Main).launch {
                    result.error("LOAD_ERROR", e.message, null)
                }
            }
        }
    }

    private fun generate(call: MethodCall, result: MethodChannel.Result) {
        val prompt = call.argument<String>("prompt") ?: run {
            result.error("MISSING_PROMPT", "prompt is required", null)
            return
        }

        scope.launch {
            try {
                val response = llmInference?.generateResponse(prompt)
                    ?: throw Exception("LLM not initialized")

                CoroutineScope(Dispatchers.Main).launch {
                    result.success(response)
                }
            } catch (e: Exception) {
                CoroutineScope(Dispatchers.Main).launch {
                    result.error("GENERATE_ERROR", e.message, null)
                }
            }
        }
    }

    private fun release(result: MethodChannel.Result) {
        llmInference?.close()
        llmInference = null
        result.success(true)
    }
}
