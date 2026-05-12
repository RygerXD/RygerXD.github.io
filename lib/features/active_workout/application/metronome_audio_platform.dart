import 'package:flutter/services.dart';
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';

const MethodChannel _channel = MethodChannel('workout_app_rewrite/metronome');

Future<void> playMetronomeClick({
  required MetronomeClickSound sound,
  required double volume,
}) async {
  try {
    await _channel.invokeMethod<void>(
      'playClick',
      <String, Object>{
        'sound': sound.name,
        'volume': volume,
      },
    );
  } on MissingPluginException {
    await SystemSound.play(SystemSoundType.click);
  } on PlatformException {
    await SystemSound.play(SystemSoundType.click);
  }
}
