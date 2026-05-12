import 'package:workout_app_rewrite/features/active_workout/application/metronome_audio_platform.dart'
    if (dart.library.html) 'package:workout_app_rewrite/features/active_workout/application/metronome_audio_web.dart'
    as platform;
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';

class MetronomeAudio {
  static Future<void> playClick({
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
}
