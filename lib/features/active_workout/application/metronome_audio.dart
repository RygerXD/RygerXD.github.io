import 'package:flutter/services.dart';

class MetronomeAudio {
  static const MethodChannel _channel =
      MethodChannel('workout_app_rewrite/metronome');

  static Future<void> playClick() async {
    try {
      await _channel.invokeMethod<void>('playClick');
    } on MissingPluginException {
      await SystemSound.play(SystemSoundType.click);
    } on PlatformException {
      await SystemSound.play(SystemSoundType.click);
    }
  }
}
