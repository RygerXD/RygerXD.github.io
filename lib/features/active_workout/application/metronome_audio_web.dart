import 'dart:js_interop';

import 'package:web/web.dart' as web;
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';

web.AudioContext? _audioContext;

Future<void> playMetronomeClick({
  required MetronomeClickSound sound,
  required double volume,
}) async {
  await _playProfile(
    profile: _SoundProfile.forMetronomeClick(sound),
    volume: volume,
  );
}

Future<void> playGetReadyDing({
  required GetReadyDingSound sound,
  required double volume,
}) async {
  await _playProfile(
    profile: _SoundProfile.forGetReadyDing(sound),
    volume: volume,
  );
}

Future<void> playGetReadyCountdown({
  required CountdownSound sound,
  required double volume,
}) async {
  await _playProfile(
    profile: _SoundProfile.forGetReadyCountdown(sound),
    volume: volume,
  );
}

Future<void> playExerciseCountdown({
  required CountdownSound sound,
  required double volume,
}) async {
  await _playProfile(
    profile: _SoundProfile.forExerciseCountdown(sound),
    volume: volume,
  );
}

Future<void> playExerciseFinishedDing({
  required ExerciseFinishedDingSound sound,
  required double volume,
}) async {
  await _playProfile(
    profile: _SoundProfile.forExerciseFinishedDing(sound),
    volume: volume,
  );
}

Future<void> _playProfile({
  required _SoundProfile profile,
  required double volume,
}) async {
  final double safeVolume = volume.clamp(0, 1).toDouble();
  if (safeVolume <= 0) {
    return;
  }

  final web.AudioContext context = _audioContext ??= web.AudioContext();
  await context.resume().toDart;

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

class _SoundProfile {
  const _SoundProfile({
    required this.duration,
    required this.tones,
  });

  final double duration;
  final List<_Tone> tones;

  static _SoundProfile forMetronomeClick(MetronomeClickSound sound) {
    switch (sound) {
      case MetronomeClickSound.classic:
        return const _SoundProfile(
          duration: 0.055,
          tones: <_Tone>[
            _Tone(frequency: 1800, type: 'square'),
            _Tone(frequency: 3600, type: 'sine'),
          ],
        );
      case MetronomeClickSound.sharp:
        return const _SoundProfile(
          duration: 0.035,
          tones: <_Tone>[
            _Tone(frequency: 3200, type: 'square'),
            _Tone(frequency: 6400, type: 'sine'),
          ],
        );
      case MetronomeClickSound.low:
        return const _SoundProfile(
          duration: 0.075,
          tones: <_Tone>[
            _Tone(frequency: 800, type: 'square'),
            _Tone(frequency: 1600, type: 'triangle'),
          ],
        );
      case MetronomeClickSound.bell:
        return const _SoundProfile(
          duration: 0.11,
          tones: <_Tone>[
            _Tone(frequency: 1320, type: 'sine'),
            _Tone(frequency: 2640, type: 'sine'),
          ],
        );
    }
  }

  static _SoundProfile forGetReadyDing(GetReadyDingSound sound) {
    switch (sound) {
      case GetReadyDingSound.classic:
        return const _SoundProfile(
          duration: 0.18,
          tones: <_Tone>[
            _Tone(frequency: 1046, type: 'sine'),
            _Tone(frequency: 2093, type: 'sine'),
          ],
        );
      case GetReadyDingSound.bright:
        return const _SoundProfile(
          duration: 0.16,
          tones: <_Tone>[
            _Tone(frequency: 1568, type: 'sine'),
            _Tone(frequency: 3136, type: 'sine'),
          ],
        );
      case GetReadyDingSound.soft:
        return const _SoundProfile(
          duration: 0.22,
          tones: <_Tone>[
            _Tone(frequency: 740, type: 'triangle'),
            _Tone(frequency: 1480, type: 'sine'),
          ],
        );
      case GetReadyDingSound.bell:
        return const _SoundProfile(
          duration: 0.24,
          tones: <_Tone>[
            _Tone(frequency: 1320, type: 'sine'),
            _Tone(frequency: 1976, type: 'sine'),
            _Tone(frequency: 2637, type: 'sine'),
          ],
        );
    }
  }

  static _SoundProfile forGetReadyCountdown(CountdownSound sound) {
    switch (sound) {
      case CountdownSound.click:
        return const _SoundProfile(
          duration: 0.05,
          tones: <_Tone>[
            _Tone(frequency: 1200, type: 'square'),
            _Tone(frequency: 2400, type: 'sine'),
          ],
        );
      case CountdownSound.pulse:
        return const _SoundProfile(
          duration: 0.07,
          tones: <_Tone>[
            _Tone(frequency: 980, type: 'triangle'),
            _Tone(frequency: 1960, type: 'sine'),
          ],
        );
      case CountdownSound.wood:
        return const _SoundProfile(
          duration: 0.045,
          tones: <_Tone>[
            _Tone(frequency: 720, type: 'square'),
            _Tone(frequency: 1080, type: 'triangle'),
          ],
        );
      case CountdownSound.low:
        return const _SoundProfile(
          duration: 0.08,
          tones: <_Tone>[
            _Tone(frequency: 520, type: 'square'),
            _Tone(frequency: 1040, type: 'triangle'),
          ],
        );
    }
  }

  static _SoundProfile forExerciseCountdown(CountdownSound sound) {
    switch (sound) {
      case CountdownSound.click:
        return const _SoundProfile(
          duration: 0.06,
          tones: <_Tone>[
            _Tone(frequency: 1450, type: 'square'),
            _Tone(frequency: 2900, type: 'sine'),
          ],
        );
      case CountdownSound.pulse:
        return const _SoundProfile(
          duration: 0.09,
          tones: <_Tone>[
            _Tone(frequency: 880, type: 'sawtooth'),
            _Tone(frequency: 1760, type: 'triangle'),
          ],
        );
      case CountdownSound.wood:
        return const _SoundProfile(
          duration: 0.055,
          tones: <_Tone>[
            _Tone(frequency: 640, type: 'square'),
            _Tone(frequency: 960, type: 'triangle'),
          ],
        );
      case CountdownSound.low:
        return const _SoundProfile(
          duration: 0.09,
          tones: <_Tone>[
            _Tone(frequency: 420, type: 'square'),
            _Tone(frequency: 840, type: 'triangle'),
          ],
        );
    }
  }

  static _SoundProfile forExerciseFinishedDing(
      ExerciseFinishedDingSound sound) {
    switch (sound) {
      case ExerciseFinishedDingSound.classic:
        return const _SoundProfile(
          duration: 0.2,
          tones: <_Tone>[
            _Tone(frequency: 1175, type: 'sine'),
            _Tone(frequency: 2350, type: 'sine'),
          ],
        );
      case ExerciseFinishedDingSound.bright:
        return const _SoundProfile(
          duration: 0.18,
          tones: <_Tone>[
            _Tone(frequency: 1760, type: 'sine'),
            _Tone(frequency: 3520, type: 'sine'),
          ],
        );
      case ExerciseFinishedDingSound.soft:
        return const _SoundProfile(
          duration: 0.24,
          tones: <_Tone>[
            _Tone(frequency: 660, type: 'triangle'),
            _Tone(frequency: 1320, type: 'sine'),
          ],
        );
      case ExerciseFinishedDingSound.bell:
        return const _SoundProfile(
          duration: 0.28,
          tones: <_Tone>[
            _Tone(frequency: 1480, type: 'sine'),
            _Tone(frequency: 2220, type: 'sine'),
            _Tone(frequency: 2960, type: 'sine'),
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
