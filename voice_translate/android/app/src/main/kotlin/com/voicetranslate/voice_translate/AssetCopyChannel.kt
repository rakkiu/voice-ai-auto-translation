package com.voicetranslate.voice_translate

import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import java.io.File
import java.io.FileOutputStream

class AssetCopyChannel(
    private val context: Context,
    flutterEngine: FlutterEngine
) : MethodChannel.MethodCallHandler {

    private val scope = CoroutineScope(Dispatchers.IO)

    init {
        val channel = MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.voicetranslate/asset_copy"
        )
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "copyAsset" -> copyAsset(call, result)
            else -> result.notImplemented()
        }
    }

    private fun copyAsset(call: MethodCall, result: MethodChannel.Result) {
        val assetPath = call.argument<String>("assetPath") ?: run {
            result.error("INVALID_ARGS", "assetPath required", null)
            return
        }
        val destPath = call.argument<String>("destPath") ?: run {
            result.error("INVALID_ARGS", "destPath required", null)
            return
        }

        scope.launch {
            try {
                val destFile = File(destPath)
                if (destFile.exists()) {
                    CoroutineScope(Dispatchers.Main).launch {
                        result.success(true)
                    }
                    return@launch
                }

                destFile.parentFile?.mkdirs()

                val inputStream = context.assets.open(assetPath)
                val outputStream = FileOutputStream(destFile)
                val buffer = ByteArray(8192)
                var bytesRead: Int

                inputStream.use { input ->
                    outputStream.use { output ->
                        while (input.read(buffer).also { bytesRead = it } != -1) {
                            output.write(buffer, 0, bytesRead)
                        }
                    }
                }

                CoroutineScope(Dispatchers.Main).launch {
                    result.success(true)
                }
            } catch (e: Exception) {
                CoroutineScope(Dispatchers.Main).launch {
                    result.error("COPY_ERROR", e.message, null)
                }
            }
        }
    }
}
