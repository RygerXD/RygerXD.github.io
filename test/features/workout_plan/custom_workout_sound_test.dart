import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  test('keeps legacy custom WAV data readable', () {
    expect(
      CustomWorkoutSound.fromBytes(
        fileName: 'legacy.wav',
        mimeType: 'audio/wav',
        bytes: Uint8List.fromList(<int>[1]),
      ).mimeType,
      'audio/wav',
    );
  });

  test('rejects custom sounds larger than the configured size limit', () {
    expect(
      () => CustomWorkoutSound.fromBytes(
        fileName: 'too-large.mp3',
        mimeType: 'audio/mpeg',
        bytes: Uint8List(maxCustomWorkoutSoundBytes + 1),
      ),
      throwsArgumentError,
    );
  });
}
