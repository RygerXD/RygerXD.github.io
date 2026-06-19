import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:workout_app_rewrite/features/active_workout/application/metronome_audio_platform.dart'
    if (dart.library.html) 'package:workout_app_rewrite/features/active_workout/application/metronome_audio_web.dart'
    as platform;
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class WorkoutAudio {
  static final Set<AudioPlayer> _customSoundPlayers = <AudioPlayer>{};

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
          () => switch (sound) {
            SharedWorkoutSound.classic => platform.playMoveFinishedDing(
                sound: MoveFinishedDingSound.classic, volume: volume),
            SharedWorkoutSound.sharp => platform.playMetronomeClick(
                sound: MetronomeClickSound.sharp, volume: volume),
            SharedWorkoutSound.low => platform.playMoveCountdown(
                sound: CountdownSound.low, volume: volume),
            SharedWorkoutSound.bell => platform.playMoveFinishedDing(
                sound: MoveFinishedDingSound.bell, volume: volume),
            SharedWorkoutSound.bright => platform.playMoveFinishedDing(
                sound: MoveFinishedDingSound.bright, volume: volume),
            SharedWorkoutSound.soft => platform.playMoveFinishedDing(
                sound: MoveFinishedDingSound.soft, volume: volume),
            SharedWorkoutSound.click => platform.playMoveCountdown(
                sound: CountdownSound.click, volume: volume),
            SharedWorkoutSound.pulse => platform.playMoveCountdown(
                sound: CountdownSound.pulse, volume: volume),
            SharedWorkoutSound.wood => platform.playMoveCountdown(
                sound: CountdownSound.wood, volume: volume),
          },
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
          () => platform.playMetronomeClick(sound: sound, volume: volume),
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
          () => platform.playGetReadyDing(sound: sound, volume: volume),
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
          () => platform.playGetReadyCountdown(sound: sound, volume: volume),
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
          () => platform.playMoveCountdown(sound: sound, volume: volume),
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
          () => platform.playMoveFinishedDing(sound: sound, volume: volume),
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
          () => platform.playMoveFinishedDing(
            sound: MoveFinishedDingSound.soft,
            volume: volume,
          ),
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
          () => platform.playWorkoutComplete(volume: volume),
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
          () => platform.playRestFinished(volume: volume),
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
          () => platform.playWorkoutEndedEarly(volume: volume),
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
  ) async {
    final AudioPlayer player = AudioPlayer();
    _customSoundPlayers.add(player);
    unawaited(player.onPlayerComplete.first.then((_) => _dispose(player)));
    try {
      await player.play(
        BytesSource(sound.bytes, mimeType: sound.mimeType),
        volume: volume,
        mode: PlayerMode.lowLatency,
      );
    } catch (_) {
      await _dispose(player);
      rethrow;
    }
  }

  static Future<void> _dispose(AudioPlayer player) async {
    _customSoundPlayers.remove(player);
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
