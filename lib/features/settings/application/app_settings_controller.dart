import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';

enum AppThemePreference {
  system,
  light,
  dark,
}

enum AppUnitSystem {
  metric,
  imperial,
}

enum MetronomeClickSound {
  classic,
  sharp,
  low,
  bell,
}

enum GetReadyDingSound {
  classic,
  bright,
  soft,
  bell,
}

enum CountdownSound {
  click,
  pulse,
  wood,
  low,
}

enum ExerciseFinishedDingSound {
  classic,
  bright,
  soft,
  bell,
}

class AppSettings {
  const AppSettings({
    required this.themePreference,
    required this.unitSystem,
    required this.streakWorkoutsPerWeek,
    required this.audioCuesEnabled,
    required this.metronomeClickSound,
    required this.metronomeVolume,
    required this.getReadyCountdownSound,
    required this.getReadyCountdownVolume,
    required this.getReadyDingSound,
    required this.getReadyDingVolume,
    required this.exerciseCountdownSound,
    required this.exerciseCountdownVolume,
    required this.exerciseFinishedDingSound,
    required this.exerciseFinishedDingVolume,
  });

  final AppThemePreference themePreference;
  final AppUnitSystem unitSystem;
  final int streakWorkoutsPerWeek;
  final bool audioCuesEnabled;
  final MetronomeClickSound metronomeClickSound;
  final double metronomeVolume;
  final CountdownSound getReadyCountdownSound;
  final double getReadyCountdownVolume;
  final GetReadyDingSound getReadyDingSound;
  final double getReadyDingVolume;
  final CountdownSound exerciseCountdownSound;
  final double exerciseCountdownVolume;
  final ExerciseFinishedDingSound exerciseFinishedDingSound;
  final double exerciseFinishedDingVolume;

  AppSettings copyWith({
    AppThemePreference? themePreference,
    AppUnitSystem? unitSystem,
    int? streakWorkoutsPerWeek,
    bool? audioCuesEnabled,
    MetronomeClickSound? metronomeClickSound,
    double? metronomeVolume,
    CountdownSound? getReadyCountdownSound,
    double? getReadyCountdownVolume,
    GetReadyDingSound? getReadyDingSound,
    double? getReadyDingVolume,
    CountdownSound? exerciseCountdownSound,
    double? exerciseCountdownVolume,
    ExerciseFinishedDingSound? exerciseFinishedDingSound,
    double? exerciseFinishedDingVolume,
  }) {
    return AppSettings(
      themePreference: themePreference ?? this.themePreference,
      unitSystem: unitSystem ?? this.unitSystem,
      streakWorkoutsPerWeek:
          streakWorkoutsPerWeek ?? this.streakWorkoutsPerWeek,
      audioCuesEnabled: audioCuesEnabled ?? this.audioCuesEnabled,
      metronomeClickSound: metronomeClickSound ?? this.metronomeClickSound,
      metronomeVolume: metronomeVolume ?? this.metronomeVolume,
      getReadyCountdownSound:
          getReadyCountdownSound ?? this.getReadyCountdownSound,
      getReadyCountdownVolume:
          getReadyCountdownVolume ?? this.getReadyCountdownVolume,
      getReadyDingSound: getReadyDingSound ?? this.getReadyDingSound,
      getReadyDingVolume: getReadyDingVolume ?? this.getReadyDingVolume,
      exerciseCountdownSound:
          exerciseCountdownSound ?? this.exerciseCountdownSound,
      exerciseCountdownVolume:
          exerciseCountdownVolume ?? this.exerciseCountdownVolume,
      exerciseFinishedDingSound:
          exerciseFinishedDingSound ?? this.exerciseFinishedDingSound,
      exerciseFinishedDingVolume:
          exerciseFinishedDingVolume ?? this.exerciseFinishedDingVolume,
    );
  }
}

final NotifierProvider<AppSettingsController, AppSettings> appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
        AppSettingsController.new);

final Provider<ThemeMode> appThemeModeProvider =
    Provider<ThemeMode>((Ref<ThemeMode> ref) {
  final AppThemePreference preference = ref.watch(
      appSettingsProvider.select((AppSettings value) => value.themePreference));
  switch (preference) {
    case AppThemePreference.light:
      return ThemeMode.light;
    case AppThemePreference.dark:
      return ThemeMode.dark;
    case AppThemePreference.system:
      return ThemeMode.system;
  }
});

final Provider<bool> audioCuesEnabledProvider = Provider<bool>((Ref<bool> ref) {
  return ref.watch(appSettingsProvider
      .select((AppSettings value) => value.audioCuesEnabled));
});

final Provider<MetronomeClickSound> metronomeClickSoundProvider =
    Provider<MetronomeClickSound>((Ref<MetronomeClickSound> ref) {
  return ref.watch(appSettingsProvider
      .select((AppSettings value) => value.metronomeClickSound));
});

final Provider<double> metronomeVolumeProvider =
    Provider<double>((Ref<double> ref) {
  return ref.watch(
      appSettingsProvider.select((AppSettings value) => value.metronomeVolume));
});

final Provider<GetReadyDingSound> getReadyDingSoundProvider =
    Provider<GetReadyDingSound>((Ref<GetReadyDingSound> ref) {
  return ref.watch(appSettingsProvider
      .select((AppSettings value) => value.getReadyDingSound));
});

final Provider<double> getReadyDingVolumeProvider =
    Provider<double>((Ref<double> ref) {
  return ref.watch(appSettingsProvider
      .select((AppSettings value) => value.getReadyDingVolume));
});

final Provider<CountdownSound> getReadyCountdownSoundProvider =
    Provider<CountdownSound>((Ref<CountdownSound> ref) {
  return ref.watch(appSettingsProvider
      .select((AppSettings value) => value.getReadyCountdownSound));
});

final Provider<double> getReadyCountdownVolumeProvider =
    Provider<double>((Ref<double> ref) {
  return ref.watch(appSettingsProvider
      .select((AppSettings value) => value.getReadyCountdownVolume));
});

final Provider<CountdownSound> exerciseCountdownSoundProvider =
    Provider<CountdownSound>((Ref<CountdownSound> ref) {
  return ref.watch(appSettingsProvider
      .select((AppSettings value) => value.exerciseCountdownSound));
});

final Provider<double> exerciseCountdownVolumeProvider =
    Provider<double>((Ref<double> ref) {
  return ref.watch(appSettingsProvider
      .select((AppSettings value) => value.exerciseCountdownVolume));
});

final Provider<ExerciseFinishedDingSound> exerciseFinishedDingSoundProvider =
    Provider<ExerciseFinishedDingSound>((Ref<ExerciseFinishedDingSound> ref) {
  return ref.watch(appSettingsProvider
      .select((AppSettings value) => value.exerciseFinishedDingSound));
});

final Provider<double> exerciseFinishedDingVolumeProvider =
    Provider<double>((Ref<double> ref) {
  return ref.watch(appSettingsProvider
      .select((AppSettings value) => value.exerciseFinishedDingVolume));
});

final Provider<AppUnitSystem> appUnitSystemProvider =
    Provider<AppUnitSystem>((Ref<AppUnitSystem> ref) {
  return ref.watch(
      appSettingsProvider.select((AppSettings value) => value.unitSystem));
});

final Provider<int> streakWorkoutsPerWeekProvider =
    Provider<int>((Ref<int> ref) {
  return ref.watch(appSettingsProvider
      .select((AppSettings value) => value.streakWorkoutsPerWeek));
});

class AppSettingsController extends Notifier<AppSettings> {
  static const String _themePreferenceKey = 'settings.theme_preference.v1';
  static const String _unitSystemKey = 'settings.unit_system.v1';
  static const String _streakWorkoutsPerWeekKey =
      'settings.streak_workouts_per_week.v1';
  static const String _audioCuesEnabledKey = 'settings.audio_cues_enabled.v1';
  static const String _metronomeClickSoundKey =
      'settings.metronome_click_sound.v1';
  static const String _metronomeVolumeKey = 'settings.metronome_volume.v1';
  static const String _getReadyCountdownSoundKey =
      'settings.get_ready_countdown_sound.v1';
  static const String _getReadyCountdownVolumeKey =
      'settings.get_ready_countdown_volume.v1';
  static const String _getReadyDingSoundKey =
      'settings.get_ready_ding_sound.v1';
  static const String _getReadyDingVolumeKey =
      'settings.get_ready_ding_volume.v1';
  static const String _exerciseCountdownSoundKey =
      'settings.exercise_countdown_sound.v1';
  static const String _exerciseCountdownVolumeKey =
      'settings.exercise_countdown_volume.v1';
  static const String _exerciseFinishedDingSoundKey =
      'settings.exercise_finished_ding_sound.v1';
  static const String _exerciseFinishedDingVolumeKey =
      'settings.exercise_finished_ding_volume.v1';

  @override
  AppSettings build() {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    return AppSettings(
      themePreference: _readEnum(
        prefs,
        key: _themePreferenceKey,
        values: AppThemePreference.values,
        fallback: AppThemePreference.system,
      ),
      unitSystem: _readEnum(
        prefs,
        key: _unitSystemKey,
        values: AppUnitSystem.values,
        fallback: AppUnitSystem.metric,
      ),
      streakWorkoutsPerWeek: _readStreakWorkoutsPerWeek(prefs),
      audioCuesEnabled: prefs.getBool(_audioCuesEnabledKey) ?? true,
      metronomeClickSound: _readEnum(
        prefs,
        key: _metronomeClickSoundKey,
        values: MetronomeClickSound.values,
        fallback: MetronomeClickSound.classic,
      ),
      metronomeVolume: _readVolume(
        prefs,
        key: _metronomeVolumeKey,
        fallback: 0.8,
      ),
      getReadyCountdownSound: _readEnum(
        prefs,
        key: _getReadyCountdownSoundKey,
        values: CountdownSound.values,
        fallback: CountdownSound.click,
      ),
      getReadyCountdownVolume: _readVolume(
        prefs,
        key: _getReadyCountdownVolumeKey,
        fallback: 0.8,
      ),
      getReadyDingSound: _readEnum(
        prefs,
        key: _getReadyDingSoundKey,
        values: GetReadyDingSound.values,
        fallback: GetReadyDingSound.classic,
      ),
      getReadyDingVolume: _readVolume(
        prefs,
        key: _getReadyDingVolumeKey,
        fallback: 0.8,
      ),
      exerciseCountdownSound: _readEnum(
        prefs,
        key: _exerciseCountdownSoundKey,
        values: CountdownSound.values,
        fallback: CountdownSound.pulse,
      ),
      exerciseCountdownVolume: _readVolume(
        prefs,
        key: _exerciseCountdownVolumeKey,
        fallback: 0.8,
      ),
      exerciseFinishedDingSound: _readEnum(
        prefs,
        key: _exerciseFinishedDingSoundKey,
        values: ExerciseFinishedDingSound.values,
        fallback: ExerciseFinishedDingSound.classic,
      ),
      exerciseFinishedDingVolume: _readVolume(
        prefs,
        key: _exerciseFinishedDingVolumeKey,
        fallback: 0.8,
      ),
    );
  }

  Future<void> setThemePreference(AppThemePreference value) async {
    await _setEnum(
      currentValue: state.themePreference,
      value: value,
      key: _themePreferenceKey,
      update: (AppThemePreference value) =>
          state.copyWith(themePreference: value),
    );
  }

  Future<void> setUnitSystem(AppUnitSystem value) async {
    await _setEnum(
      currentValue: state.unitSystem,
      value: value,
      key: _unitSystemKey,
      update: (AppUnitSystem value) => state.copyWith(unitSystem: value),
    );
  }

  Future<void> setStreakWorkoutsPerWeek(int value) async {
    final int clamped = value.clamp(1, 14);
    if (state.streakWorkoutsPerWeek == clamped) {
      return;
    }
    state = state.copyWith(streakWorkoutsPerWeek: clamped);
    await _prefs.setInt(_streakWorkoutsPerWeekKey, clamped);
  }

  Future<void> setAudioCuesEnabled(bool value) async {
    if (state.audioCuesEnabled == value) {
      return;
    }
    state = state.copyWith(audioCuesEnabled: value);
    await _prefs.setBool(_audioCuesEnabledKey, value);
  }

  Future<void> setMetronomeClickSound(MetronomeClickSound value) async {
    await _setEnum(
      currentValue: state.metronomeClickSound,
      value: value,
      key: _metronomeClickSoundKey,
      update: (MetronomeClickSound value) =>
          state.copyWith(metronomeClickSound: value),
    );
  }

  Future<void> setMetronomeVolume(double value) async {
    await _setVolume(
      currentValue: state.metronomeVolume,
      value: value,
      key: _metronomeVolumeKey,
      update: (double value) => state.copyWith(metronomeVolume: value),
    );
  }

  Future<void> setGetReadyCountdownSound(CountdownSound value) async {
    await _setEnum(
      currentValue: state.getReadyCountdownSound,
      value: value,
      key: _getReadyCountdownSoundKey,
      update: (CountdownSound value) =>
          state.copyWith(getReadyCountdownSound: value),
    );
  }

  Future<void> setGetReadyCountdownVolume(double value) async {
    await _setVolume(
      currentValue: state.getReadyCountdownVolume,
      value: value,
      key: _getReadyCountdownVolumeKey,
      update: (double value) => state.copyWith(getReadyCountdownVolume: value),
    );
  }

  Future<void> setGetReadyDingSound(GetReadyDingSound value) async {
    await _setEnum(
      currentValue: state.getReadyDingSound,
      value: value,
      key: _getReadyDingSoundKey,
      update: (GetReadyDingSound value) =>
          state.copyWith(getReadyDingSound: value),
    );
  }

  Future<void> setGetReadyDingVolume(double value) async {
    await _setVolume(
      currentValue: state.getReadyDingVolume,
      value: value,
      key: _getReadyDingVolumeKey,
      update: (double value) => state.copyWith(getReadyDingVolume: value),
    );
  }

  Future<void> setExerciseCountdownSound(CountdownSound value) async {
    await _setEnum(
      currentValue: state.exerciseCountdownSound,
      value: value,
      key: _exerciseCountdownSoundKey,
      update: (CountdownSound value) =>
          state.copyWith(exerciseCountdownSound: value),
    );
  }

  Future<void> setExerciseCountdownVolume(double value) async {
    await _setVolume(
      currentValue: state.exerciseCountdownVolume,
      value: value,
      key: _exerciseCountdownVolumeKey,
      update: (double value) => state.copyWith(exerciseCountdownVolume: value),
    );
  }

  Future<void> setExerciseFinishedDingSound(
      ExerciseFinishedDingSound value) async {
    await _setEnum(
      currentValue: state.exerciseFinishedDingSound,
      value: value,
      key: _exerciseFinishedDingSoundKey,
      update: (ExerciseFinishedDingSound value) =>
          state.copyWith(exerciseFinishedDingSound: value),
    );
  }

  Future<void> setExerciseFinishedDingVolume(double value) async {
    await _setVolume(
      currentValue: state.exerciseFinishedDingVolume,
      value: value,
      key: _exerciseFinishedDingVolumeKey,
      update: (double value) =>
          state.copyWith(exerciseFinishedDingVolume: value),
    );
  }

  int _readStreakWorkoutsPerWeek(SharedPreferences prefs) {
    final int raw = prefs.getInt(_streakWorkoutsPerWeekKey) ?? 3;
    return raw.clamp(1, 14);
  }

  T _readEnum<T extends Enum>(
    SharedPreferences prefs, {
    required String key,
    required List<T> values,
    required T fallback,
  }) {
    final String? raw = prefs.getString(key);
    if (raw == null) {
      return fallback;
    }
    for (final T value in values) {
      if (value.name == raw) {
        return value;
      }
    }
    return fallback;
  }

  double _readVolume(
    SharedPreferences prefs, {
    required String key,
    required double fallback,
  }) {
    final double? raw = prefs.getDouble(key);
    return (raw ?? fallback).clamp(0, 1).toDouble();
  }

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  Future<void> _setEnum<T extends Enum>({
    required T currentValue,
    required T value,
    required String key,
    required AppSettings Function(T value) update,
  }) async {
    if (currentValue == value) {
      return;
    }
    state = update(value);
    await _prefs.setString(key, value.name);
  }

  Future<void> _setVolume({
    required double currentValue,
    required double value,
    required String key,
    required AppSettings Function(double value) update,
  }) async {
    final double clamped = value.clamp(0, 1).toDouble();
    if (currentValue == clamped) {
      return;
    }
    state = update(clamped);
    await _prefs.setDouble(key, clamped);
  }
}
