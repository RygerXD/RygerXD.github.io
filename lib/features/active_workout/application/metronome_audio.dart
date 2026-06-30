import 'package:audioplayers/audioplayers.dart';
import 'package:workout_app_rewrite/core/audio/built_in_sound_catalog.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class WorkoutAudio {
  static const String _assetPrefix = 'assets/';
  static final AudioContext _cueAudioContext = AudioContext(
    android: const AudioContextAndroid(
      contentType: AndroidContentType.sonification,
      usageType: AndroidUsageType.assistanceSonification,
      audioFocus: AndroidAudioFocus.gainTransientMayDuck,
    ),
  );
  static final Map<String, Future<AudioPool>> _builtInPools =
      <String, Future<AudioPool>>{};
  static final Map<String, Future<AudioPool>> _customPools =
      <String, Future<AudioPool>>{};

  static Future<void> preloadBuiltInSounds(Iterable<String> sounds) =>
      Future.wait(sounds.toSet().map((String sound) async {
        try {
          await _builtInPool(sound);
        } catch (_) {
          // Preloading is best effort.
        }
      }));

  static Future<void> playSharedSound({
    required String sound,
    CustomWorkoutSound? customSound,
    required double volume,
  }) async {
    final double? safeVolume = _safeVolume(volume);
    if (safeVolume == null) return;
    if (customSound != null) {
      try {
        await _playCustom(customSound, safeVolume);
        return;
      } catch (_) {
        // Fall back to the selected packaged sound.
      }
    }
    await _playBuiltIn(sound, safeVolume);
  }

  static Future<void> playCustomSound({
    required CustomWorkoutSound sound,
    required double volume,
  }) async {
    final double? safeVolume = _safeVolume(volume);
    if (safeVolume != null) await _playCustom(sound, safeVolume);
  }

  static Future<void> _playBuiltIn(String sound, double volume) async {
    final AudioPool pool = await _builtInPool(sound);
    await pool.start(volume: volume);
  }

  static Future<AudioPool> _builtInPool(String sound) async {
    final BuiltInWorkoutSound asset = await BuiltInSoundCatalog.resolve(sound);
    return _builtInPools.putIfAbsent(
      asset.assetPath,
      () => AudioPool.create(
        source: AssetSource(asset.assetPath.startsWith(_assetPrefix)
            ? asset.assetPath.substring(_assetPrefix.length)
            : asset.assetPath),
        audioContext: _cueAudioContext,
        maxPlayers: 3,
      ),
    );
  }

  static Future<void> _playCustom(
    CustomWorkoutSound sound,
    double volume,
  ) async {
    final AudioPool pool = await _customPools.putIfAbsent(
      sound.audioIdentity,
      () => AudioPool.create(
        source: BytesSource(sound.bytes, mimeType: sound.mimeType),
        audioContext: _cueAudioContext,
        maxPlayers: 3,
      ),
    );
    await pool.start(volume: volume);
  }

  static double? _safeVolume(double volume) =>
      volume <= 0 ? null : volume.clamp(0, 1).toDouble();
}
