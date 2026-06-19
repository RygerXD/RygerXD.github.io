import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every built-in selection has packaged WAV data', () async {
    for (final SharedWorkoutSound sound in SharedWorkoutSound.values) {
      final ByteData data =
          await rootBundle.load('assets/audio/${sound.name}.wav');
      final Uint8List bytes = data.buffer.asUint8List(
        data.offsetInBytes,
        data.lengthInBytes,
      );

      expect(bytes.length, greaterThan(44), reason: sound.name);
      expect(String.fromCharCodes(bytes.take(4)), 'RIFF', reason: sound.name);
      expect(String.fromCharCodes(bytes.skip(8).take(4)), 'WAVE',
          reason: sound.name);
    }
  });
}
