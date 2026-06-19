import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class WorkoutAudio {
  static final Set<AudioPlayer> _players = <AudioPlayer>{};
  static final Map<SharedWorkoutSound, Future<Uint8List>> _builtInSoundBytes =
      <SharedWorkoutSound, Future<Uint8List>>{};

  static Future<void> playSharedSound({
    required SharedWorkoutSound sound,
    CustomWorkoutSound? customSound,
    required double volume,
  }) =>
      _play(
        volume,
        (double volume) => _playCustomOrFallback(
          customSound,
          volume,
          () => _playBuiltIn(sound, volume),
        ),
      );

  static Future<void> playMetronomeClick({
    required MetronomeClickSound sound,
    CustomWorkoutSound? customSound,
    required double volume,
  }) =>
      _play(
        volume,
        (double volume) => _playCustomOrFallback(
          customSound,
          volume,
          () => _playBuiltIn(
              SharedWorkoutSound.values.byName(sound.name), volume),
        ),
      );

  static Future<void> playGetReadyDing({
    required GetReadyDingSound sound,
    CustomWorkoutSound? customSound,
    required double volume,
  }) =>
      _play(
        volume,
        (double volume) => _playCustomOrFallback(
          customSound,
          volume,
          () => _playBuiltIn(
              SharedWorkoutSound.values.byName(sound.name), volume),
        ),
      );

  static Future<void> playGetReadyCountdown({
    required CountdownSound sound,
    CustomWorkoutSound? customSound,
    required double volume,
  }) =>
      _play(
        volume,
        (double volume) => _playCustomOrFallback(
          customSound,
          volume,
          () => _playBuiltIn(
              SharedWorkoutSound.values.byName(sound.name), volume),
        ),
      );

  static Future<void> playMoveCountdown({
    required CountdownSound sound,
    CustomWorkoutSound? customSound,
    required double volume,
  }) =>
      _play(
        volume,
        (double volume) => _playCustomOrFallback(
          customSound,
          volume,
          () => _playBuiltIn(
              SharedWorkoutSound.values.byName(sound.name), volume),
        ),
      );

  static Future<void> playMoveFinishedDing({
    required MoveFinishedDingSound sound,
    CustomWorkoutSound? customSound,
    required double volume,
  }) =>
      _play(
        volume,
        (double volume) => _playCustomOrFallback(
          customSound,
          volume,
          () => _playBuiltIn(
              SharedWorkoutSound.values.byName(sound.name), volume),
        ),
      );

  static Future<void> playMoveHalfway({
    CustomWorkoutSound? customSound,
    required double volume,
  }) =>
      _play(
        volume,
        (double volume) => _playCustomOrFallback(
          customSound,
          volume,
          () => _playBuiltIn(SharedWorkoutSound.soft, volume),
        ),
      );

  static Future<void> playWorkoutComplete({
    CustomWorkoutSound? customSound,
    required double volume,
  }) =>
      _play(
        volume,
        (double volume) => _playCustomOrFallback(
          customSound,
          volume,
          () => _playBuiltIn(SharedWorkoutSound.bright, volume),
        ),
      );

  static Future<void> playRestFinished({
    CustomWorkoutSound? customSound,
    required double volume,
  }) =>
      _play(
        volume,
        (double volume) => _playCustomOrFallback(
          customSound,
          volume,
          () => _playBuiltIn(SharedWorkoutSound.bell, volume),
        ),
      );

  static Future<void> playWorkoutEndedEarly({
    CustomWorkoutSound? customSound,
    required double volume,
  }) =>
      _play(
        volume,
        (double volume) => _playCustomOrFallback(
          customSound,
          volume,
          () => _playBuiltIn(SharedWorkoutSound.low, volume),
        ),
      );

  static Future<void> playCustomSound({
    required CustomWorkoutSound sound,
    required double volume,
  }) =>
      _play(volume, (double volume) => _playCustom(sound, volume));

  static Future<void> _playCustomOrFallback(
    CustomWorkoutSound? sound,
    double volume,
    Future<void> Function() fallback,
  ) async {
    if (sound == null) {
      await fallback();
      return;
    }
    try {
      await _playCustom(sound, volume);
    } catch (_) {
      await fallback();
    }
  }

  static Future<void> _playCustom(
    CustomWorkoutSound sound,
    double volume,
  ) =>
      _playBytes(sound.bytes, sound.mimeType, volume);

  static Future<void> _playBuiltIn(
    SharedWorkoutSound sound,
    double volume,
  ) async {
    final Uint8List bytes = await _builtInSoundBytes.putIfAbsent(
      sound,
      () async {
        final ByteData data =
            await rootBundle.load('assets/audio/${sound.name}.wav');
        return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      },
    );
    await _playBytes(bytes, 'audio/wav', volume);
  }

  static Future<void> _playBytes(
    Uint8List bytes,
    String mimeType,
    double volume,
  ) async {
    final AudioPlayer player = AudioPlayer();
    _players.add(player);
    unawaited(player.onPlayerComplete.first.then((_) => _dispose(player)));
    try {
      await player.play(
        BytesSource(bytes, mimeType: mimeType),
        volume: volume,
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      await _dispose(player);
      rethrow;
    }
  }

  static Future<void> _dispose(AudioPlayer player) async {
    _players.remove(player);
    await player.dispose();
  }

  static Future<void> _play(
    double volume,
    Future<void> Function(double volume) play,
  ) async {
    if (volume <= 0) {
      return;
    }
    await play(volume.clamp(0, 1).toDouble());
  }
}
