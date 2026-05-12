import 'dart:js_interop';

import 'package:web/web.dart' as web;
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';

web.AudioContext? _audioContext;

Future<void> playMetronomeClick({
  required MetronomeClickSound sound,
  required double volume,
}) async {
  final double safeVolume = volume.clamp(0, 1).toDouble();
  if (safeVolume <= 0) {
    return;
  }

  final web.AudioContext context = _audioContext ??= web.AudioContext();
  await context.resume().toDart;

  final _ClickProfile profile = _ClickProfile.forSound(sound);
  final double now = context.currentTime;
  final web.GainNode gain = context.createGain();
  gain.gain.setValueAtTime(safeVolume, now);
  gain.gain.exponentialRampToValueAtTime(0.001, now + profile.duration);
  gain.connect(context.destination);

  for (final _Tone tone in profile.tones) {
    final web.OscillatorNode oscillator = context.createOscillator();
    oscillator.type = tone.type;
    oscillator.frequency.setValueAtTime(tone.frequency, now);
    oscillator.connect(gain);
    oscillator.start(now);
    oscillator.stop(now + profile.duration);
  }
}

class _ClickProfile {
  const _ClickProfile({
    required this.duration,
    required this.tones,
  });

  final double duration;
  final List<_Tone> tones;

  static _ClickProfile forSound(MetronomeClickSound sound) {
    switch (sound) {
      case MetronomeClickSound.classic:
        return const _ClickProfile(
          duration: 0.055,
          tones: <_Tone>[
            _Tone(frequency: 1800, type: 'square'),
            _Tone(frequency: 3600, type: 'sine'),
          ],
        );
      case MetronomeClickSound.sharp:
        return const _ClickProfile(
          duration: 0.035,
          tones: <_Tone>[
            _Tone(frequency: 3200, type: 'square'),
            _Tone(frequency: 6400, type: 'sine'),
          ],
        );
      case MetronomeClickSound.low:
        return const _ClickProfile(
          duration: 0.075,
          tones: <_Tone>[
            _Tone(frequency: 800, type: 'square'),
            _Tone(frequency: 1600, type: 'triangle'),
          ],
        );
      case MetronomeClickSound.bell:
        return const _ClickProfile(
          duration: 0.11,
          tones: <_Tone>[
            _Tone(frequency: 1320, type: 'sine'),
            _Tone(frequency: 2640, type: 'sine'),
          ],
        );
    }
  }
}

class _Tone {
  const _Tone({
    required this.frequency,
    required this.type,
  });

  final double frequency;
  final String type;
}
