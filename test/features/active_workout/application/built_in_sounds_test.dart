import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/core/audio/built_in_sound_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every built-in selection has packaged Ogg Vorbis data', () async {
    final List<BuiltInWorkoutSound> sounds = await BuiltInSoundCatalog.load();
    final List<BuiltInWorkoutSound> oggSounds = sounds
        .where((BuiltInWorkoutSound sound) => sound.id.endsWith('.ogg'))
        .toList(growable: false);
    expect(oggSounds, isNotEmpty);

    for (final BuiltInWorkoutSound sound in oggSounds) {
      final ByteData data = await rootBundle.load(sound.assetPath);
      final Uint8List bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      expect(bytes.length, greaterThan(64), reason: sound.id);
      expect(String.fromCharCodes(bytes.take(4)), 'OggS', reason: sound.id);
      expect(String.fromCharCodes(bytes), contains('vorbis'), reason: sound.id);
    }
  });

  test('catalog automatically includes supported audio asset paths', () {
    final List<BuiltInWorkoutSound> sounds =
        BuiltInSoundCatalog.fromAssetPaths(<String>[
      'assets/audio/classic.ogg',
      'assets/audio/new-sound.mp3',
      'assets/audio/readme.txt',
      'assets/images/not-a-sound.ogg',
    ]);

    expect(sounds.map((BuiltInWorkoutSound sound) => sound.id),
        <String>['classic.ogg', 'new-sound.mp3']);
    expect(sounds.last.label, 'New sound');
    expect(sounds.last.mimeType, 'audio/mpeg');
  });
}
