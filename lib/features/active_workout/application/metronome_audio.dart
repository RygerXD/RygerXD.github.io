import 'package:workout_app_rewrite/features/active_workout/application/metronome_audio_platform.dart'
    if (dart.library.html) 'package:workout_app_rewrite/features/active_workout/application/metronome_audio_web.dart'
    as platform;
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';

class WorkoutAudio {
  static Future<void> playMetronomeClick({
    required MetronomeClickSound sound,
    required double volume,
  }) async {
    await _play(
        volume,
        (double volume) =>
            platform.playMetronomeClick(sound: sound, volume: volume));
  }

  static Future<void> playGetReadyDing({
    required GetReadyDingSound sound,
    required double volume,
  }) async {
    await _play(
        volume,
        (double volume) =>
            platform.playGetReadyDing(sound: sound, volume: volume));
  }

  static Future<void> playGetReadyCountdown({
    required CountdownSound sound,
    required double volume,
  }) async {
    await _play(
        volume,
        (double volume) =>
            platform.playGetReadyCountdown(sound: sound, volume: volume));
  }

  static Future<void> playExerciseCountdown({
    required CountdownSound sound,
    required double volume,
  }) async {
    await _play(
        volume,
        (double volume) =>
            platform.playExerciseCountdown(sound: sound, volume: volume));
  }

  static Future<void> playExerciseFinishedDing({
    required ExerciseFinishedDingSound sound,
    required double volume,
  }) async {
    await _play(
        volume,
        (double volume) =>
            platform.playExerciseFinishedDing(sound: sound, volume: volume));
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
