import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';
import 'package:workout_app_rewrite/features/settings/application/sound_settings_transfer.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('stores shared custom audio once and restores cue references', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    addTearDown(container.dispose);

    final CustomWorkoutSound sound = CustomWorkoutSound.fromBytes(
      fileName: 'shared.mp3',
      mimeType: 'audio/mpeg',
      bytes: Uint8List.fromList(<int>[1, 2, 3, 4]),
    );
    final AppSettingsController controller =
        container.read(appSettingsProvider.notifier);
    await controller.addCustomSound(sound);
    await controller.setMetronomeClickCustomSound(sound);
    await controller.setMoveHalfwayCustomSound(sound);

    final Map<String, dynamic> encoded =
        encodeSoundSettings(container.read(appSettingsProvider));
    final List<dynamic> sounds = encoded['sounds'] as List<dynamic>;
    final Map<String, dynamic> selections =
        encoded['customSoundSelections'] as Map<String, dynamic>;

    expect(sounds, hasLength(1));
    expect(selections[WorkoutSoundCue.metronome], 'sound-1');
    expect(selections[WorkoutSoundCue.moveHalfway], 'sound-1');
    expect(
        encodeSoundSettingsJson(container.read(appSettingsProvider))
            .split(sound.base64Data),
        hasLength(2));

    final AppSettings restored = decodeSoundSettings(encoded);
    expect(restored.customSoundLibrary, hasLength(1));
    expect(restored.metronomeClickCustomSound?.base64Data, sound.base64Data);
    expect(restored.moveHalfwayCustomSound?.base64Data, sound.base64Data);
  });
}
