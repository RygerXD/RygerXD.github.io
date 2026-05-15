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
      expect(settings.audioCuesEnabled, isTrue);
      expect(settings.metronomeClickSound, MetronomeClickSound.classic);
      expect(settings.metronomeVolume, 0.8);
      expect(settings.getReadyCountdownSound, CountdownSound.click);
      expect(settings.getReadyCountdownVolume, 0.8);
      expect(settings.getReadyDingSound, GetReadyDingSound.classic);
      expect(settings.getReadyDingVolume, 0.8);
      expect(settings.exerciseCountdownSound, CountdownSound.pulse);
      expect(settings.exerciseCountdownVolume, 0.8);
      expect(settings.exerciseFinishedDingSound,
          ExerciseFinishedDingSound.classic);
      expect(settings.exerciseFinishedDingVolume, 0.8);
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
      await controller.setAudioCuesEnabled(false);
      await controller.setMetronomeClickSound(MetronomeClickSound.bell);
      await controller.setMetronomeVolume(0.35);
      await controller.setGetReadyCountdownSound(CountdownSound.wood);
      await controller.setGetReadyCountdownVolume(0.25);
      await controller.setGetReadyDingSound(GetReadyDingSound.bright);
      await controller.setGetReadyDingVolume(0.45);
      await controller.setExerciseCountdownSound(CountdownSound.low);
      await controller.setExerciseCountdownVolume(0.55);
      await controller
          .setExerciseFinishedDingSound(ExerciseFinishedDingSound.bell);
      await controller.setExerciseFinishedDingVolume(0.65);

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
      expect(reloadedSettings.audioCuesEnabled, isFalse);
      expect(reloadedSettings.metronomeClickSound, MetronomeClickSound.bell);
      expect(reloadedSettings.metronomeVolume, 0.35);
      expect(reloadedSettings.getReadyCountdownSound, CountdownSound.wood);
      expect(reloadedSettings.getReadyCountdownVolume, 0.25);
      expect(reloadedSettings.getReadyDingSound, GetReadyDingSound.bright);
      expect(reloadedSettings.getReadyDingVolume, 0.45);
      expect(reloadedSettings.exerciseCountdownSound, CountdownSound.low);
      expect(reloadedSettings.exerciseCountdownVolume, 0.55);
      expect(reloadedSettings.exerciseFinishedDingSound,
          ExerciseFinishedDingSound.bell);
      expect(reloadedSettings.exerciseFinishedDingVolume, 0.65);
      expect(reloadedContainer.read(appThemeModeProvider), ThemeMode.dark);
    });

    test('clamps saved metronome volume', () async {
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
      await controller.setMetronomeVolume(1.5);

      expect(container.read(appSettingsProvider).metronomeVolume, 1);
    });

    test('clamps saved get ready volume', () async {
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
      await controller.setGetReadyDingVolume(-0.5);

      expect(container.read(appSettingsProvider).getReadyDingVolume, 0);
    });

    test('clamps saved countdown and exercise finish volumes', () async {
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
      await controller.setGetReadyCountdownVolume(1.5);
      await controller.setExerciseCountdownVolume(-0.5);
      await controller.setExerciseFinishedDingVolume(1.25);

      final AppSettings settings = container.read(appSettingsProvider);
      expect(settings.getReadyCountdownVolume, 1);
      expect(settings.exerciseCountdownVolume, 0);
      expect(settings.exerciseFinishedDingVolume, 1);
    });
  });
}
