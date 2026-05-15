import 'package:workout_app_rewrite/features/active_workout/application/metronome_audio_platform.dart'
    if (dart.library.html) 'package:workout_app_rewrite/features/active_workout/application/metronome_audio_web.dart'
    as platform;
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';

class WorkoutAudio {
  static Future<void> playMetronomeClick({
    required MetronomeClickSound sound,
    required double volume,
  }) async {
    if (volume <= 0) {
      return;
    }

    await platform.playMetronomeClick(
      sound: sound,
      volume: volume.clamp(0, 1).toDouble(),
    );
  }

  static Future<void> playGetReadyDing({
    required GetReadyDingSound sound,
    required double volume,
  }) async {
    if (volume <= 0) {
      return;
    }

    await platform.playGetReadyDing(
      sound: sound,
      volume: volume.clamp(0, 1).toDouble(),
    );
  }

  static Future<void> playGetReadyCountdown({
    required CountdownSound sound,
    required double volume,
  }) async {
    if (volume <= 0) {
      return;
    }

    await platform.playGetReadyCountdown(
      sound: sound,
      volume: volume.clamp(0, 1).toDouble(),
    );
  }

  static Future<void> playExerciseCountdown({
    required CountdownSound sound,
    required double volume,
  }) async {
    if (volume <= 0) {
      return;
    }

    await platform.playExerciseCountdown(
      sound: sound,
      volume: volume.clamp(0, 1).toDouble(),
    );
  }

  static Future<void> playExerciseFinishedDing({
    required ExerciseFinishedDingSound sound,
    required double volume,
  }) async {
    if (volume <= 0) {
      return;
    }

    await platform.playExerciseFinishedDing(
      sound: sound,
      volume: volume.clamp(0, 1).toDouble(),
    );
  }
}

class MetronomeAudio {
  static Future<void> playClick({
    required MetronomeClickSound sound,
    required double volume,
  }) async {
    await WorkoutAudio.playMetronomeClick(
      sound: sound,
      volume: volume,
    );
  }
}
