import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

const int _sampleRate = 44100;

const Map<String, _SoundProfile> _sounds = <String, _SoundProfile>{
  'classic': _SoundProfile(200, 5.2, 0.70, <_Tone>[
    _Tone(1175, 1),
    _Tone(2350, 0.5),
  ]),
  'sharp': _SoundProfile(28, 24, 0.75, <_Tone>[
    _Tone(3600, 1),
    _Tone(6200, 0.45),
  ]),
  'low': _SoundProfile(90, 12, 0.65, <_Tone>[
    _Tone(420, 1),
    _Tone(840, 0.4),
  ]),
  'bell': _SoundProfile(280, 4.2, 0.70, <_Tone>[
    _Tone(1480, 1),
    _Tone(2220, 0.45),
    _Tone(2960, 0.35),
  ]),
  'bright': _SoundProfile(180, 5.5, 0.70, <_Tone>[
    _Tone(1760, 1),
    _Tone(3520, 0.5),
  ]),
  'soft': _SoundProfile(240, 4.8, 0.70, <_Tone>[
    _Tone(660, 1),
    _Tone(1320, 0.4),
  ]),
  'click': _SoundProfile(60, 16, 0.65, <_Tone>[
    _Tone(1450, 1),
    _Tone(2900, 0.45),
  ]),
  'pulse': _SoundProfile(90, 10, 0.65, <_Tone>[
    _Tone(880, 1),
    _Tone(1760, 0.45),
  ]),
  'wood': _SoundProfile(55, 18, 0.65, <_Tone>[
    _Tone(640, 1),
    _Tone(960, 0.55),
  ]),
};

void main() {
  final Directory output = Directory('assets/audio')
    ..createSync(recursive: true);
  final Directory temporary = Directory.systemTemp.createTempSync(
    'workout-sounds-',
  );
  final String ffmpeg = Platform.environment['FFMPEG'] ?? 'ffmpeg';
  try {
    for (final MapEntry<String, _SoundProfile> entry in _sounds.entries) {
      final File wave = File('${temporary.path}/${entry.key}.wav')
        ..writeAsBytesSync(_buildWave(entry.value));
      final ProcessResult result = Process.runSync(ffmpeg, <String>[
        '-y',
        '-loglevel',
        'error',
        '-i',
        wave.path,
        '-c:a',
        'libvorbis',
        '-q:a',
        '5',
        '${output.path}/${entry.key}.ogg',
      ]);
      if (result.exitCode != 0) {
        throw StateError('Could not encode ${entry.key}.ogg: ${result.stderr}');
      }
    }
  } finally {
    temporary.deleteSync(recursive: true);
  }
}

Uint8List _buildWave(_SoundProfile profile) {
  final int frameCount = _sampleRate * profile.durationMs ~/ 1000;
  final int dataLength = frameCount * 2;
  final ByteData wave = ByteData(44 + dataLength);

  void ascii(int offset, String value) {
    for (int index = 0; index < value.length; index++) {
      wave.setUint8(offset + index, value.codeUnitAt(index));
    }
  }

  ascii(0, 'RIFF');
  wave.setUint32(4, 36 + dataLength, Endian.little);
  ascii(8, 'WAVE');
  ascii(12, 'fmt ');
  wave.setUint32(16, 16, Endian.little);
  wave.setUint16(20, 1, Endian.little);
  wave.setUint16(22, 1, Endian.little);
  wave.setUint32(24, _sampleRate, Endian.little);
  wave.setUint32(28, _sampleRate * 2, Endian.little);
  wave.setUint16(32, 2, Endian.little);
  wave.setUint16(34, 16, Endian.little);
  ascii(36, 'data');
  wave.setUint32(40, dataLength, Endian.little);

  for (int frame = 0; frame < frameCount; frame++) {
    final double time = frame / _sampleRate;
    final double normalized = frame / frameCount;
    final double envelope = exp(-normalized * profile.decay);
    double sample = 0;
    for (final _Tone tone in profile.tones) {
      sample += tone.amplitude * sin(2 * pi * tone.frequency * time);
    }
    final int value =
        (sample.clamp(-1.0, 1.0) * envelope * profile.gain * 32767).round();
    wave.setInt16(44 + frame * 2, value, Endian.little);
  }
  return wave.buffer.asUint8List();
}

class _SoundProfile {
  const _SoundProfile(this.durationMs, this.decay, this.gain, this.tones);

  final int durationMs;
  final double decay;
  final double gain;
  final List<_Tone> tones;
}

class _Tone {
  const _Tone(this.frequency, this.amplitude);

  final double frequency;
  final double amplitude;
}
