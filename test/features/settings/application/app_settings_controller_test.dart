import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppSettingsController', () {
    test('loads defaults when no saved preferences exist', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final AppSettings settings = container.read(appSettingsProvider);

      expect(settings.themePreference, AppThemePreference.system);
      expect(settings.unitSystem, AppUnitSystem.metric);
      expect(settings.streakWorkoutsPerWeek, 3);
      expect(settings.audioCuesEnabled, isTrue);
      expect(settings.metronomeClickSound, MetronomeClickSound.classic);
      expect(settings.audioVolume, 0.8);
      expect(settings.getReadyCountdownSound, CountdownSound.click);
      expect(settings.getReadyDingSound, GetReadyDingSound.classic);
      expect(settings.exerciseCountdownSound, CountdownSound.pulse);
      expect(settings.exerciseFinishedDingSound,
          ExerciseFinishedDingSound.classic);
      expect(container.read(appThemeModeProvider), ThemeMode.system);
    });

    test('persists changes across container instances', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final AppSettingsController controller =
          container.read(appSettingsProvider.notifier);
      await controller.setThemePreference(AppThemePreference.dark);
      await controller.setUnitSystem(AppUnitSystem.imperial);
      await controller.setStreakWorkoutsPerWeek(4);
      await controller.setAudioCuesEnabled(false);
      await controller.setMetronomeClickSound(MetronomeClickSound.bell);
      await controller.setAudioVolume(0.35);
      await controller.setGetReadyCountdownSound(CountdownSound.wood);
      await controller.setGetReadyDingSound(GetReadyDingSound.bright);
      await controller.setExerciseCountdownSound(CountdownSound.low);
      await controller
          .setExerciseFinishedDingSound(ExerciseFinishedDingSound.bell);

      final ProviderContainer reloadedContainer = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(reloadedContainer.dispose);

      final AppSettings reloadedSettings =
          reloadedContainer.read(appSettingsProvider);
      expect(reloadedSettings.themePreference, AppThemePreference.dark);
      expect(reloadedSettings.unitSystem, AppUnitSystem.imperial);
      expect(reloadedSettings.streakWorkoutsPerWeek, 4);
      expect(reloadedSettings.audioCuesEnabled, isFalse);
      expect(reloadedSettings.metronomeClickSound, MetronomeClickSound.bell);
      expect(reloadedSettings.audioVolume, 0.35);
      expect(reloadedSettings.getReadyCountdownSound, CountdownSound.wood);
      expect(reloadedSettings.getReadyDingSound, GetReadyDingSound.bright);
      expect(reloadedSettings.exerciseCountdownSound, CountdownSound.low);
      expect(reloadedSettings.exerciseFinishedDingSound,
          ExerciseFinishedDingSound.bell);
      expect(reloadedContainer.read(appThemeModeProvider), ThemeMode.dark);
    });

    test('clamps saved audio volume', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final AppSettingsController controller =
          container.read(appSettingsProvider.notifier);
      await controller.setAudioVolume(1.5);

      expect(container.read(appSettingsProvider).audioVolume, 1);

      await controller.setAudioVolume(-0.5);
      expect(container.read(appSettingsProvider).audioVolume, 0);
    });

    test('clamps saved streak workout goal', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      final AppSettingsController controller =
          container.read(appSettingsProvider.notifier);
      await controller.setStreakWorkoutsPerWeek(20);
      expect(container.read(appSettingsProvider).streakWorkoutsPerWeek, 14);

      await controller.setStreakWorkoutsPerWeek(-2);
      expect(container.read(appSettingsProvider).streakWorkoutsPerWeek, 1);
    });

    test('loads legacy metronome volume as shared audio volume', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'settings.metronome_volume.v1': 0.45,
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(appSettingsProvider).audioVolume, 0.45);
    });
  });
}
