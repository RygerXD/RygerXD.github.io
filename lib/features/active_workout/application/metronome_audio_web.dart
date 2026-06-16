import 'dart:js_interop';

import 'package:web/web.dart' as web;
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';

web.AudioContext? _audioContext;

Future<void> playMetronomeClick({
  required MetronomeClickSound sound,
  required double volume,
}) =>
    _playProfile(
      profile: _SoundProfile.forMetronomeClick(sound),
      volume: volume,
    );

Future<void> playGetReadyDing({
  required GetReadyDingSound sound,
  required double volume,
}) =>
    _playProfile(
      profile: _SoundProfile.forGetReadyDing(sound),
      volume: volume,
    );

Future<void> playGetReadyCountdown({
  required CountdownSound sound,
  required double volume,
}) =>
    _playProfile(
      profile: _SoundProfile.forGetReadyCountdown(sound),
      volume: volume,
    );

Future<void> playMoveCountdown({
  required CountdownSound sound,
  required double volume,
}) =>
    _playProfile(
      profile: _SoundProfile.forMoveCountdown(sound),
      volume: volume,
    );

Future<void> playMoveFinishedDing({
  required MoveFinishedDingSound sound,
  required double volume,
}) =>
    _playProfile(
      profile: _SoundProfile.forMoveFinishedDing(sound),
      volume: volume,
    );

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
  const _SoundProfile(this.duration, this.tones);

  final double duration;
  final List<_Tone> tones;

  static _SoundProfile forMetronomeClick(MetronomeClickSound sound) =>
      switch (sound) {
        MetronomeClickSound.classic => const _SoundProfile(0.055, <_Tone>[
            _Tone(1800, 'square'),
            _Tone(3600, 'sine'),
          ]),
        MetronomeClickSound.sharp => const _SoundProfile(0.035, <_Tone>[
            _Tone(3200, 'square'),
            _Tone(6400, 'sine'),
          ]),
        MetronomeClickSound.low => const _SoundProfile(0.075, <_Tone>[
            _Tone(800, 'square'),
            _Tone(1600, 'triangle'),
          ]),
        MetronomeClickSound.bell => const _SoundProfile(0.11, <_Tone>[
            _Tone(1320, 'sine'),
            _Tone(2640, 'sine'),
          ]),
      };

  static _SoundProfile forGetReadyDing(GetReadyDingSound sound) =>
      switch (sound) {
        GetReadyDingSound.classic => const _SoundProfile(0.18, <_Tone>[
            _Tone(1046, 'sine'),
            _Tone(2093, 'sine'),
          ]),
        GetReadyDingSound.bright => const _SoundProfile(0.16, <_Tone>[
            _Tone(1568, 'sine'),
            _Tone(3136, 'sine'),
          ]),
        GetReadyDingSound.soft => const _SoundProfile(0.22, <_Tone>[
            _Tone(740, 'triangle'),
            _Tone(1480, 'sine'),
          ]),
        GetReadyDingSound.bell => const _SoundProfile(0.24, <_Tone>[
            _Tone(1320, 'sine'),
            _Tone(1976, 'sine'),
            _Tone(2637, 'sine'),
          ]),
      };

  static _SoundProfile forGetReadyCountdown(CountdownSound sound) =>
      switch (sound) {
        CountdownSound.click => const _SoundProfile(0.05, <_Tone>[
            _Tone(1200, 'square'),
            _Tone(2400, 'sine'),
          ]),
        CountdownSound.pulse => const _SoundProfile(0.07, <_Tone>[
            _Tone(980, 'triangle'),
            _Tone(1960, 'sine'),
          ]),
        CountdownSound.wood => const _SoundProfile(0.045, <_Tone>[
            _Tone(720, 'square'),
            _Tone(1080, 'triangle'),
          ]),
        CountdownSound.low => const _SoundProfile(0.08, <_Tone>[
            _Tone(520, 'square'),
            _Tone(1040, 'triangle'),
          ]),
      };

  static _SoundProfile forMoveCountdown(CountdownSound sound) =>
      switch (sound) {
        CountdownSound.click => const _SoundProfile(0.06, <_Tone>[
            _Tone(1450, 'square'),
            _Tone(2900, 'sine'),
          ]),
        CountdownSound.pulse => const _SoundProfile(0.09, <_Tone>[
            _Tone(880, 'sawtooth'),
            _Tone(1760, 'triangle'),
          ]),
        CountdownSound.wood => const _SoundProfile(0.055, <_Tone>[
            _Tone(640, 'square'),
            _Tone(960, 'triangle'),
          ]),
        CountdownSound.low => const _SoundProfile(0.09, <_Tone>[
            _Tone(420, 'square'),
            _Tone(840, 'triangle'),
          ]),
      };

  static _SoundProfile forMoveFinishedDing(MoveFinishedDingSound sound) =>
      switch (sound) {
        MoveFinishedDingSound.classic => const _SoundProfile(0.2, <_Tone>[
            _Tone(1175, 'sine'),
            _Tone(2350, 'sine'),
          ]),
        MoveFinishedDingSound.bright => const _SoundProfile(0.18, <_Tone>[
            _Tone(1760, 'sine'),
            _Tone(3520, 'sine'),
          ]),
        MoveFinishedDingSound.soft => const _SoundProfile(0.24, <_Tone>[
            _Tone(660, 'triangle'),
            _Tone(1320, 'sine'),
          ]),
        MoveFinishedDingSound.bell => const _SoundProfile(0.28, <_Tone>[
            _Tone(1480, 'sine'),
            _Tone(2220, 'sine'),
            _Tone(2960, 'sine'),
          ]),
      };
}

class _Tone {
  const _Tone(this.frequency, this.type);

  final double frequency;
  final String type;
}
