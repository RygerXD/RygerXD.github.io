import 'package:flutter/services.dart';
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';

const MethodChannel _channel = MethodChannel('workout_app_rewrite/metronome');

Future<void> playMetronomeClick({
  required MetronomeClickSound sound,
  required double volume,
}) =>
    _invokeSound('playClick', sound, volume, SystemSoundType.click);

Future<void> playGetReadyDing({
  required GetReadyDingSound sound,
  required double volume,
}) =>
    _invokeSound('playGetReadyDing', sound, volume, SystemSoundType.alert);

Future<void> playGetReadyCountdown({
  required CountdownSound sound,
  required double volume,
}) =>
    _invokeSound('playGetReadyCountdown', sound, volume, SystemSoundType.click);

Future<void> playMoveCountdown({
  required CountdownSound sound,
  required double volume,
}) =>
    _invokeSound('playMoveCountdown', sound, volume, SystemSoundType.click);

Future<void> playMoveFinishedDing({
  required MoveFinishedDingSound sound,
  required double volume,
}) =>
    _invokeSound('playMoveFinishedDing', sound, volume, SystemSoundType.alert);

Future<void> playWorkoutComplete({required double volume}) => _invokeSound(
    'playWorkoutComplete',
    _TerminalSound.complete,
    volume,
    SystemSoundType.alert);

Future<void> playWorkoutEndedEarly({required double volume}) => _invokeSound(
    'playWorkoutEndedEarly',
    _TerminalSound.endedEarly,
    volume,
    SystemSoundType.alert);

Future<void> playRestFinished({required double volume}) => _invokeSound(
    'playRestFinished',
    _TerminalSound.restFinished,
    volume,
    SystemSoundType.alert);

enum _TerminalSound { complete, endedEarly, restFinished }

Future<void> _invokeSound(
  String method,
  Enum sound,
  double volume,
  SystemSoundType fallback,
) async {
  try {
    await _channel.invokeMethod<void>(
      method,
      <String, Object>{
        'sound': sound.name,
        'volume': volume,
      },
    );
  } on MissingPluginException {
    await SystemSound.play(fallback);
  } on PlatformException {
    await SystemSound.play(fallback);
  }
}
