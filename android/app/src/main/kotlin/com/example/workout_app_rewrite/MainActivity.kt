package com.example.workout_app_rewrite

import android.media.AudioManager
import android.media.ToneGenerator
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val metronomeChannelName = "workout_app_rewrite/metronome"
    private var toneGenerator: ToneGenerator? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            metronomeChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "playClick" -> {
                    playMetronomeClick()
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        toneGenerator?.release()
        toneGenerator = null
        super.onDestroy()
    }

    private fun playMetronomeClick() {
        val generator = toneGenerator
            ?: ToneGenerator(AudioManager.STREAM_MUSIC, 100).also {
                toneGenerator = it
            }
        generator.startTone(ToneGenerator.TONE_PROP_BEEP2, 45)
    }
}
