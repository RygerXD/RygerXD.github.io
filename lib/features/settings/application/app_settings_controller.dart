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
      themePreference: _readThemePreference(prefs),
      unitSystem: _readUnitSystem(prefs),
      streakWorkoutsPerWeek: _readStreakWorkoutsPerWeek(prefs),
      audioCuesEnabled: prefs.getBool(_audioCuesEnabledKey) ?? true,
      metronomeClickSound: _readMetronomeClickSound(prefs),
      metronomeVolume: _readMetronomeVolume(prefs),
      getReadyCountdownSound: _readCountdownSound(
        prefs,
        key: _getReadyCountdownSoundKey,
        fallback: CountdownSound.click,
      ),
      getReadyCountdownVolume: _readVolume(
        prefs,
        key: _getReadyCountdownVolumeKey,
        fallback: 0.8,
      ),
      getReadyDingSound: _readGetReadyDingSound(prefs),
      getReadyDingVolume: _readGetReadyDingVolume(prefs),
      exerciseCountdownSound: _readCountdownSound(
        prefs,
        key: _exerciseCountdownSoundKey,
        fallback: CountdownSound.pulse,
      ),
      exerciseCountdownVolume: _readVolume(
        prefs,
        key: _exerciseCountdownVolumeKey,
        fallback: 0.8,
      ),
      exerciseFinishedDingSound: _readExerciseFinishedDingSound(prefs),
      exerciseFinishedDingVolume: _readVolume(
        prefs,
        key: _exerciseFinishedDingVolumeKey,
        fallback: 0.8,
      ),
    );
  }

  Future<void> setThemePreference(AppThemePreference value) async {
    if (state.themePreference == value) {
      return;
    }
    state = state.copyWith(themePreference: value);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_themePreferenceKey, value.name);
  }

  Future<void> setUnitSystem(AppUnitSystem value) async {
    if (state.unitSystem == value) {
      return;
    }
    state = state.copyWith(unitSystem: value);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_unitSystemKey, value.name);
  }

  Future<void> setStreakWorkoutsPerWeek(int value) async {
    final int clamped = value.clamp(1, 14);
    if (state.streakWorkoutsPerWeek == clamped) {
      return;
    }
    state = state.copyWith(streakWorkoutsPerWeek: clamped);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setInt(_streakWorkoutsPerWeekKey, clamped);
  }

  Future<void> setAudioCuesEnabled(bool value) async {
    if (state.audioCuesEnabled == value) {
      return;
    }
    state = state.copyWith(audioCuesEnabled: value);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_audioCuesEnabledKey, value);
  }

  Future<void> setMetronomeClickSound(MetronomeClickSound value) async {
    if (state.metronomeClickSound == value) {
      return;
    }
    state = state.copyWith(metronomeClickSound: value);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_metronomeClickSoundKey, value.name);
  }

  Future<void> setMetronomeVolume(double value) async {
    final double clamped = value.clamp(0, 1).toDouble();
    if (state.metronomeVolume == clamped) {
      return;
    }
    state = state.copyWith(metronomeVolume: clamped);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_metronomeVolumeKey, clamped);
  }

  Future<void> setGetReadyCountdownSound(CountdownSound value) async {
    if (state.getReadyCountdownSound == value) {
      return;
    }
    state = state.copyWith(getReadyCountdownSound: value);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_getReadyCountdownSoundKey, value.name);
  }

  Future<void> setGetReadyCountdownVolume(double value) async {
    final double clamped = value.clamp(0, 1).toDouble();
    if (state.getReadyCountdownVolume == clamped) {
      return;
    }
    state = state.copyWith(getReadyCountdownVolume: clamped);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_getReadyCountdownVolumeKey, clamped);
  }

  Future<void> setGetReadyDingSound(GetReadyDingSound value) async {
    if (state.getReadyDingSound == value) {
      return;
    }
    state = state.copyWith(getReadyDingSound: value);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_getReadyDingSoundKey, value.name);
  }

  Future<void> setGetReadyDingVolume(double value) async {
    final double clamped = value.clamp(0, 1).toDouble();
    if (state.getReadyDingVolume == clamped) {
      return;
    }
    state = state.copyWith(getReadyDingVolume: clamped);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_getReadyDingVolumeKey, clamped);
  }

  Future<void> setExerciseCountdownSound(CountdownSound value) async {
    if (state.exerciseCountdownSound == value) {
      return;
    }
    state = state.copyWith(exerciseCountdownSound: value);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_exerciseCountdownSoundKey, value.name);
  }

  Future<void> setExerciseCountdownVolume(double value) async {
    final double clamped = value.clamp(0, 1).toDouble();
    if (state.exerciseCountdownVolume == clamped) {
      return;
    }
    state = state.copyWith(exerciseCountdownVolume: clamped);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_exerciseCountdownVolumeKey, clamped);
  }

  Future<void> setExerciseFinishedDingSound(
      ExerciseFinishedDingSound value) async {
    if (state.exerciseFinishedDingSound == value) {
      return;
    }
    state = state.copyWith(exerciseFinishedDingSound: value);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setString(_exerciseFinishedDingSoundKey, value.name);
  }

  Future<void> setExerciseFinishedDingVolume(double value) async {
    final double clamped = value.clamp(0, 1).toDouble();
    if (state.exerciseFinishedDingVolume == clamped) {
      return;
    }
    state = state.copyWith(exerciseFinishedDingVolume: clamped);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setDouble(_exerciseFinishedDingVolumeKey, clamped);
  }

  AppThemePreference _readThemePreference(SharedPreferences prefs) {
    final String? raw = prefs.getString(_themePreferenceKey);
    if (raw == null) {
      return AppThemePreference.system;
    }
    for (final AppThemePreference value in AppThemePreference.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return AppThemePreference.system;
  }

  AppUnitSystem _readUnitSystem(SharedPreferences prefs) {
    final String? raw = prefs.getString(_unitSystemKey);
    if (raw == null) {
      return AppUnitSystem.metric;
    }
    for (final AppUnitSystem value in AppUnitSystem.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return AppUnitSystem.metric;
  }

  int _readStreakWorkoutsPerWeek(SharedPreferences prefs) {
    final int raw = prefs.getInt(_streakWorkoutsPerWeekKey) ?? 3;
    return raw.clamp(1, 14);
  }

  MetronomeClickSound _readMetronomeClickSound(SharedPreferences prefs) {
    final String? raw = prefs.getString(_metronomeClickSoundKey);
    if (raw == null) {
      return MetronomeClickSound.classic;
    }
    for (final MetronomeClickSound value in MetronomeClickSound.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return MetronomeClickSound.classic;
  }

  double _readMetronomeVolume(SharedPreferences prefs) {
    return _readVolume(prefs, key: _metronomeVolumeKey, fallback: 0.8);
  }

  GetReadyDingSound _readGetReadyDingSound(SharedPreferences prefs) {
    final String? raw = prefs.getString(_getReadyDingSoundKey);
    if (raw == null) {
      return GetReadyDingSound.classic;
    }
    for (final GetReadyDingSound value in GetReadyDingSound.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return GetReadyDingSound.classic;
  }

  double _readGetReadyDingVolume(SharedPreferences prefs) {
    return _readVolume(prefs, key: _getReadyDingVolumeKey, fallback: 0.8);
  }

  CountdownSound _readCountdownSound(
    SharedPreferences prefs, {
    required String key,
    required CountdownSound fallback,
  }) {
    final String? raw = prefs.getString(key);
    if (raw == null) {
      return fallback;
    }
    for (final CountdownSound value in CountdownSound.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return fallback;
  }

  ExerciseFinishedDingSound _readExerciseFinishedDingSound(
      SharedPreferences prefs) {
    final String? raw = prefs.getString(_exerciseFinishedDingSoundKey);
    if (raw == null) {
      return ExerciseFinishedDingSound.classic;
    }
    for (final ExerciseFinishedDingSound value
        in ExerciseFinishedDingSound.values) {
      if (value.name == raw) {
        return value;
      }
    }
    return ExerciseFinishedDingSound.classic;
  }

  double _readVolume(
    SharedPreferences prefs, {
    required String key,
    required double fallback,
  }) {
    final double? raw = prefs.getDouble(key);
    return (raw ?? fallback).clamp(0, 1).toDouble();
  }
}
