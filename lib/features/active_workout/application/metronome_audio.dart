import 'package:flutter/services.dart';
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';

class MetronomeAudio {
  static const MethodChannel _channel =
      MethodChannel('workout_app_rewrite/metronome');

  static Future<void> playClick({
    required MetronomeClickSound sound,
    required double volume,
  }) async {
    if (volume <= 0) {
      return;
    }

    try {
      await _channel.invokeMethod<void>(
        'playClick',
        <String, Object>{
          'sound': sound.name,
          'volume': volume.clamp(0, 1).toDouble(),
        },
      );
    } on MissingPluginException {
      await SystemSound.play(SystemSoundType.click);
    } on PlatformException {
      await SystemSound.play(SystemSoundType.click);
    }
  }
}
