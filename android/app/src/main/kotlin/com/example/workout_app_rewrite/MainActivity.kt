package com.example.workout_app_rewrite

import android.media.AudioFormat
import android.media.AudioManager
import android.media.AudioTrack
import android.net.Uri
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import kotlin.math.PI
import kotlin.math.exp
import kotlin.math.sin

class MainActivity : FlutterActivity() {
    private val metronomeChannelName = "workout_app_rewrite/metronome"
    private val mediaChannelName = "workout_app_rewrite/media"
    private val sampleRate = 44100
    private val activeTracks = mutableSetOf<AudioTrack>()

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            metronomeChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "playClick" -> {
                    val sound = call.argument<String>("sound") ?: "classic"
                    val volume = call.argument<Double>("volume") ?: 0.8
                    playMetronomeClick(sound, volume)
                    result.success(null)
                }

                "playGetReadyDing" -> {
                    val sound = call.argument<String>("sound") ?: "classic"
                    val volume = call.argument<Double>("volume") ?: 0.8
                    playGetReadyDing(sound, volume)
                    result.success(null)
                }

                "playGetReadyCountdown" -> {
                    val sound = call.argument<String>("sound") ?: "click"
                    val volume = call.argument<Double>("volume") ?: 0.8
                    playGetReadyCountdown(sound, volume)
                    result.success(null)
                }

                "playExerciseCountdown" -> {
                    val sound = call.argument<String>("sound") ?: "pulse"
                    val volume = call.argument<Double>("volume") ?: 0.8
                    playExerciseCountdown(sound, volume)
                    result.success(null)
                }

                "playExerciseFinishedDing" -> {
                    val sound = call.argument<String>("sound") ?: "classic"
                    val volume = call.argument<Double>("volume") ?: 0.8
                    playExerciseFinishedDing(sound, volume)
                    result.success(null)
                }

                else -> result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            mediaChannelName,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "copyKeyboardContent" -> {
                    val uri = call.argument<String>("uri")
                    val mimeType = call.argument<String>("mimeType") ?: ""
                    if (uri == null) {
                        result.error("missing_uri", "No content URI was provided.", null)
                        return@setMethodCallHandler
                    }

                    try {
                        result.success(copyKeyboardContent(uri, mimeType))
                    } catch (error: Exception) {
                        result.error("copy_failed", error.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }

    private fun copyKeyboardContent(uriString: String, mimeType: String): String {
        val mediaDirectory = File(filesDir, "exercise_media")
        mediaDirectory.mkdirs()

        val extension = extensionForMimeType(mimeType)
        val mediaFile = File(
            mediaDirectory,
            "keyboard_${System.currentTimeMillis()}$extension",
        )
        contentResolver.openInputStream(Uri.parse(uriString)).use { inputStream ->
            requireNotNull(inputStream) { "Could not open keyboard content." }
            mediaFile.outputStream().use { outputStream ->
                inputStream.copyTo(outputStream)
            }
        }
        return mediaFile.absolutePath
    }

    private fun extensionForMimeType(mimeType: String): String {
        return when (mimeType.lowercase()) {
            "image/gif" -> ".gif"
            "image/png" -> ".png"
            "image/webp" -> ".webp"
            "image/jpeg", "image/jpg" -> ".jpg"
            else -> ".img"
        }
    }

    private fun playMetronomeClick(sound: String, volume: Double) {
        playPcm(buildClickPcm(sound), volume)
    }

    private fun playGetReadyDing(sound: String, volume: Double) {
        playPcm(buildGetReadyDingPcm(sound), volume)
    }

    private fun playGetReadyCountdown(sound: String, volume: Double) {
        playPcm(buildCountdownPcm(sound, exerciseCue = false), volume)
    }

    private fun playExerciseCountdown(sound: String, volume: Double) {
        playPcm(buildCountdownPcm(sound, exerciseCue = true), volume)
    }

    private fun playExerciseFinishedDing(sound: String, volume: Double) {
        playPcm(buildExerciseFinishedDingPcm(sound), volume)
    }

    private fun playPcm(pcm: ByteArray, volume: Double) {
        val safeVolume = volume.coerceIn(0.0, 1.0).toFloat()
        if (safeVolume <= 0f) {
            return
        }

        val audioTrack = AudioTrack(
            AudioManager.STREAM_MUSIC,
            sampleRate,
            AudioFormat.CHANNEL_OUT_MONO,
            AudioFormat.ENCODING_PCM_16BIT,
            pcm.size,
            AudioTrack.MODE_STATIC,
        )
        audioTrack.setVolume(safeVolume)
        audioTrack.write(pcm, 0, pcm.size)
        audioTrack.setNotificationMarkerPosition(pcm.size / 2)
        audioTrack.setPlaybackPositionUpdateListener(
            object : AudioTrack.OnPlaybackPositionUpdateListener {
                override fun onMarkerReached(track: AudioTrack) {
                    activeTracks.remove(track)
                    track.release()
                }

                override fun onPeriodicNotification(track: AudioTrack) = Unit
            },
        )
        activeTracks.add(audioTrack)
        audioTrack.play()
    }

    override fun onDestroy() {
        activeTracks.forEach(AudioTrack::release)
        activeTracks.clear()
        super.onDestroy()
    }

    private fun buildClickPcm(sound: String): ByteArray {
        val durationMs = when (sound) {
            "sharp" -> 28
            "low" -> 55
            "bell" -> 85
            else -> 40
        }
        val frameCount = sampleRate * durationMs / 1000
        val pcm = ByteArray(frameCount * 2)

        for (frame in 0 until frameCount) {
            val t = frame.toDouble() / sampleRate
            val normalized = frame.toDouble() / frameCount
            val sample = when (sound) {
                "sharp" -> {
                    val envelope = exp(-normalized * 24.0)
                    envelope * (sin(2.0 * PI * 3600.0 * t) + 0.45 * sin(2.0 * PI * 6200.0 * t))
                }

                "low" -> {
                    val envelope = exp(-normalized * 12.0)
                    envelope * (sin(2.0 * PI * 850.0 * t) + 0.35 * sin(2.0 * PI * 1700.0 * t))
                }

                "bell" -> {
                    val envelope = exp(-normalized * 8.0)
                    envelope * (sin(2.0 * PI * 1320.0 * t) + 0.6 * sin(2.0 * PI * 2640.0 * t))
                }

                else -> {
                    val envelope = exp(-normalized * 16.0)
                    envelope * (sin(2.0 * PI * 1800.0 * t) + 0.5 * sin(2.0 * PI * 3600.0 * t))
                }
            }
            val intSample = (sample.coerceIn(-1.0, 1.0) * Short.MAX_VALUE * 0.75).toInt()
            val byteIndex = frame * 2
            pcm[byteIndex] = (intSample and 0xff).toByte()
            pcm[byteIndex + 1] = ((intSample shr 8) and 0xff).toByte()
        }

        return pcm
    }

    private fun buildGetReadyDingPcm(sound: String): ByteArray {
        val durationMs = when (sound) {
            "bright" -> 160
            "soft" -> 220
            "bell" -> 240
            else -> 180
        }
        val frameCount = sampleRate * durationMs / 1000
        val pcm = ByteArray(frameCount * 2)

        for (frame in 0 until frameCount) {
            val t = frame.toDouble() / sampleRate
            val normalized = frame.toDouble() / frameCount
            val sample = when (sound) {
                "bright" -> {
                    val envelope = exp(-normalized * 6.0)
                    envelope * (sin(2.0 * PI * 1568.0 * t) + 0.55 * sin(2.0 * PI * 3136.0 * t))
                }

                "soft" -> {
                    val envelope = exp(-normalized * 5.0)
                    envelope * (sin(2.0 * PI * 740.0 * t) + 0.4 * sin(2.0 * PI * 1480.0 * t))
                }

                "bell" -> {
                    val envelope = exp(-normalized * 4.5)
                    envelope * (
                        sin(2.0 * PI * 1320.0 * t) +
                            0.45 * sin(2.0 * PI * 1976.0 * t) +
                            0.35 * sin(2.0 * PI * 2637.0 * t)
                        )
                }

                else -> {
                    val envelope = exp(-normalized * 5.5)
                    envelope * (sin(2.0 * PI * 1046.0 * t) + 0.5 * sin(2.0 * PI * 2093.0 * t))
                }
            }
            val intSample = (sample.coerceIn(-1.0, 1.0) * Short.MAX_VALUE * 0.7).toInt()
            val byteIndex = frame * 2
            pcm[byteIndex] = (intSample and 0xff).toByte()
            pcm[byteIndex + 1] = ((intSample shr 8) and 0xff).toByte()
        }

        return pcm
    }

    private fun buildCountdownPcm(sound: String, exerciseCue: Boolean): ByteArray {
        val durationMs = when (sound) {
            "pulse" -> if (exerciseCue) 90 else 70
            "low" -> if (exerciseCue) 90 else 80
            "wood" -> if (exerciseCue) 55 else 45
            else -> if (exerciseCue) 60 else 50
        }
        val frameCount = sampleRate * durationMs / 1000
        val pcm = ByteArray(frameCount * 2)

        for (frame in 0 until frameCount) {
            val t = frame.toDouble() / sampleRate
            val normalized = frame.toDouble() / frameCount
            val sample = when (sound) {
                "pulse" -> {
                    val base = if (exerciseCue) 880.0 else 980.0
                    val envelope = exp(-normalized * 10.0)
                    envelope * (sin(2.0 * PI * base * t) + 0.45 * sin(2.0 * PI * base * 2.0 * t))
                }

                "wood" -> {
                    val base = if (exerciseCue) 640.0 else 720.0
                    val envelope = exp(-normalized * 18.0)
                    envelope * (sin(2.0 * PI * base * t) + 0.55 * sin(2.0 * PI * base * 1.5 * t))
                }

                "low" -> {
                    val base = if (exerciseCue) 420.0 else 520.0
                    val envelope = exp(-normalized * 12.0)
                    envelope * (sin(2.0 * PI * base * t) + 0.4 * sin(2.0 * PI * base * 2.0 * t))
                }

                else -> {
                    val base = if (exerciseCue) 1450.0 else 1200.0
                    val envelope = exp(-normalized * 16.0)
                    envelope * (sin(2.0 * PI * base * t) + 0.45 * sin(2.0 * PI * base * 2.0 * t))
                }
            }
            val intSample = (sample.coerceIn(-1.0, 1.0) * Short.MAX_VALUE * 0.65).toInt()
            val byteIndex = frame * 2
            pcm[byteIndex] = (intSample and 0xff).toByte()
            pcm[byteIndex + 1] = ((intSample shr 8) and 0xff).toByte()
        }

        return pcm
    }

    private fun buildExerciseFinishedDingPcm(sound: String): ByteArray {
        val durationMs = when (sound) {
            "bright" -> 180
            "soft" -> 240
            "bell" -> 280
            else -> 200
        }
        val frameCount = sampleRate * durationMs / 1000
        val pcm = ByteArray(frameCount * 2)

        for (frame in 0 until frameCount) {
            val t = frame.toDouble() / sampleRate
            val normalized = frame.toDouble() / frameCount
            val sample = when (sound) {
                "bright" -> {
                    val envelope = exp(-normalized * 5.5)
                    envelope * (sin(2.0 * PI * 1760.0 * t) + 0.5 * sin(2.0 * PI * 3520.0 * t))
                }

                "soft" -> {
                    val envelope = exp(-normalized * 4.8)
                    envelope * (sin(2.0 * PI * 660.0 * t) + 0.4 * sin(2.0 * PI * 1320.0 * t))
                }

                "bell" -> {
                    val envelope = exp(-normalized * 4.2)
                    envelope * (
                        sin(2.0 * PI * 1480.0 * t) +
                            0.45 * sin(2.0 * PI * 2220.0 * t) +
                            0.35 * sin(2.0 * PI * 2960.0 * t)
                        )
                }

                else -> {
                    val envelope = exp(-normalized * 5.2)
                    envelope * (sin(2.0 * PI * 1175.0 * t) + 0.5 * sin(2.0 * PI * 2350.0 * t))
                }
            }
            val intSample = (sample.coerceIn(-1.0, 1.0) * Short.MAX_VALUE * 0.7).toInt()
            val byteIndex = frame * 2
            pcm[byteIndex] = (intSample and 0xff).toByte()
            pcm[byteIndex + 1] = ((intSample shr 8) and 0xff).toByte()
        }

        return pcm
    }
}
