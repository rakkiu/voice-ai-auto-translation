package com.voicetranslate.voice_translate

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        WhisperChannel(this, flutterEngine)
        MediaPipeLlmChannel(this, flutterEngine)
        AssetCopyChannel(this, flutterEngine)
    }
}
