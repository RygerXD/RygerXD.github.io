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
    required this.audioVolume,
    required this.getReadyCountdownSound,
    required this.getReadyDingSound,
    required this.exerciseCountdownSound,
    required this.exerciseFinishedDingSound,
  });

  final AppThemePreference themePreference;
  final AppUnitSystem unitSystem;
  final int streakWorkoutsPerWeek;
  final bool audioCuesEnabled;
  final MetronomeClickSound metronomeClickSound;
  final double audioVolume;
  final CountdownSound getReadyCountdownSound;
  final GetReadyDingSound getReadyDingSound;
  final CountdownSound exerciseCountdownSound;
  final ExerciseFinishedDingSound exerciseFinishedDingSound;

  AppSettings copyWith({
    AppThemePreference? themePreference,
    AppUnitSystem? unitSystem,
    int? streakWorkoutsPerWeek,
    bool? audioCuesEnabled,
    MetronomeClickSound? metronomeClickSound,
    double? audioVolume,
    CountdownSound? getReadyCountdownSound,
    GetReadyDingSound? getReadyDingSound,
    CountdownSound? exerciseCountdownSound,
    ExerciseFinishedDingSound? exerciseFinishedDingSound,
  }) {
    return AppSettings(
      themePreference: themePreference ?? this.themePreference,
      unitSystem: unitSystem ?? this.unitSystem,
      streakWorkoutsPerWeek:
          streakWorkoutsPerWeek ?? this.streakWorkoutsPerWeek,
      audioCuesEnabled: audioCuesEnabled ?? this.audioCuesEnabled,
      metronomeClickSound: metronomeClickSound ?? this.metronomeClickSound,
      audioVolume: audioVolume ?? this.audioVolume,
      getReadyCountdownSound:
          getReadyCountdownSound ?? this.getReadyCountdownSound,
      getReadyDingSound: getReadyDingSound ?? this.getReadyDingSound,
      exerciseCountdownSound:
          exerciseCountdownSound ?? this.exerciseCountdownSound,
      exerciseFinishedDingSound:
          exerciseFinishedDingSound ?? this.exerciseFinishedDingSound,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      themePreference: _readEnum(
        json,
        key: 'themePreference',
        values: AppThemePreference.values,
        fallback: AppThemePreference.system,
      ),
      unitSystem: _readEnum(
        json,
        key: 'unitSystem',
        values: AppUnitSystem.values,
        fallback: AppUnitSystem.metric,
      ),
      streakWorkoutsPerWeek:
          _readInt(json, key: 'streakWorkoutsPerWeek', fallback: 3)
              .clamp(1, 14),
      audioCuesEnabled:
          _readBool(json, key: 'audioCuesEnabled', fallback: true),
      metronomeClickSound: _readEnum(
        json,
        key: 'metronomeClickSound',
        values: MetronomeClickSound.values,
        fallback: MetronomeClickSound.classic,
      ),
      audioVolume: _readDouble(
        json,
        key: 'audioVolume',
        fallback: _readDouble(json, key: 'metronomeVolume', fallback: 0.8),
      ),
      getReadyCountdownSound: _readEnum(
        json,
        key: 'getReadyCountdownSound',
        values: CountdownSound.values,
        fallback: CountdownSound.click,
      ),
      getReadyDingSound: _readEnum(
        json,
        key: 'getReadyDingSound',
        values: GetReadyDingSound.values,
        fallback: GetReadyDingSound.classic,
      ),
      exerciseCountdownSound: _readEnum(
        json,
        key: 'exerciseCountdownSound',
        values: CountdownSound.values,
        fallback: CountdownSound.pulse,
      ),
      exerciseFinishedDingSound: _readEnum(
        json,
        key: 'exerciseFinishedDingSound',
        values: ExerciseFinishedDingSound.values,
        fallback: ExerciseFinishedDingSound.classic,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'themePreference': themePreference.name,
      'unitSystem': unitSystem.name,
      'streakWorkoutsPerWeek': streakWorkoutsPerWeek,
      'audioCuesEnabled': audioCuesEnabled,
      'metronomeClickSound': metronomeClickSound.name,
      'audioVolume': audioVolume,
      'getReadyCountdownSound': getReadyCountdownSound.name,
      'getReadyDingSound': getReadyDingSound.name,
      'exerciseCountdownSound': exerciseCountdownSound.name,
      'exerciseFinishedDingSound': exerciseFinishedDingSound.name,
    };
  }

  static T _readEnum<T extends Enum>(
    Map<String, dynamic> json, {
    required String key,
    required List<T> values,
    required T fallback,
  }) {
    final Object? raw = json[key];
    if (raw is String) {
      for (final T value in values) {
        if (value.name == raw) {
          return value;
        }
      }
    }
    return fallback;
  }

  static int _readInt(
    Map<String, dynamic> json, {
    required String key,
    required int fallback,
  }) {
    final Object? raw = json[key];
    return raw is num ? raw.toInt() : fallback;
  }

  static double _readDouble(
    Map<String, dynamic> json, {
    required String key,
    required double fallback,
  }) {
    final Object? raw = json[key];
    final double value = raw is num ? raw.toDouble() : fallback;
    return value.clamp(0, 1).toDouble();
  }

  static bool _readBool(
    Map<String, dynamic> json, {
    required String key,
    required bool fallback,
  }) {
    final Object? raw = json[key];
    return raw is bool ? raw : fallback;
  }
}

final NotifierProvider<AppSettingsController, AppSettings> appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(
        AppSettingsController.new);

Provider<T> _settingsSelector<T>(T Function(AppSettings settings) select) {
  return Provider<T>((Ref<T> ref) {
    return ref.watch(appSettingsProvider.select(select));
  });
}

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

final Provider<bool> audioCuesEnabledProvider =
    _settingsSelector<bool>((AppSettings value) => value.audioCuesEnabled);

final Provider<MetronomeClickSound> metronomeClickSoundProvider =
    _settingsSelector<MetronomeClickSound>(
        (AppSettings value) => value.metronomeClickSound);

final Provider<double> audioVolumeProvider =
    _settingsSelector<double>((AppSettings value) => value.audioVolume);

final Provider<GetReadyDingSound> getReadyDingSoundProvider =
    _settingsSelector<GetReadyDingSound>(
        (AppSettings value) => value.getReadyDingSound);

final Provider<CountdownSound> getReadyCountdownSoundProvider =
    _settingsSelector<CountdownSound>(
        (AppSettings value) => value.getReadyCountdownSound);

final Provider<CountdownSound> exerciseCountdownSoundProvider =
    _settingsSelector<CountdownSound>(
        (AppSettings value) => value.exerciseCountdownSound);

final Provider<ExerciseFinishedDingSound> exerciseFinishedDingSoundProvider =
    _settingsSelector<ExerciseFinishedDingSound>(
        (AppSettings value) => value.exerciseFinishedDingSound);

final Provider<AppUnitSystem> appUnitSystemProvider =
    _settingsSelector<AppUnitSystem>((AppSettings value) => value.unitSystem);

final Provider<int> streakWorkoutsPerWeekProvider =
    _settingsSelector<int>((AppSettings value) => value.streakWorkoutsPerWeek);

class AppSettingsController extends Notifier<AppSettings> {
  static const String _themePreferenceKey = 'settings.theme_preference.v1';
  static const String _unitSystemKey = 'settings.unit_system.v1';
  static const String _streakWorkoutsPerWeekKey =
      'settings.streak_workouts_per_week.v1';
  static const String _audioCuesEnabledKey = 'settings.audio_cues_enabled.v1';
  static const String _metronomeClickSoundKey =
      'settings.metronome_click_sound.v1';
  static const String _audioVolumeKey = 'settings.audio_volume.v1';
  static const String _legacyMetronomeVolumeKey =
      'settings.metronome_volume.v1';
  static const String _getReadyCountdownSoundKey =
      'settings.get_ready_countdown_sound.v1';
  static const String _getReadyDingSoundKey =
      'settings.get_ready_ding_sound.v1';
  static const String _exerciseCountdownSoundKey =
      'settings.exercise_countdown_sound.v1';
  static const String _exerciseFinishedDingSoundKey =
      'settings.exercise_finished_ding_sound.v1';

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
      audioVolume: _readAudioVolume(prefs),
      getReadyCountdownSound: _readEnum(
        prefs,
        key: _getReadyCountdownSoundKey,
        values: CountdownSound.values,
        fallback: CountdownSound.click,
      ),
      getReadyDingSound: _readEnum(
        prefs,
        key: _getReadyDingSoundKey,
        values: GetReadyDingSound.values,
        fallback: GetReadyDingSound.classic,
      ),
      exerciseCountdownSound: _readEnum(
        prefs,
        key: _exerciseCountdownSoundKey,
        values: CountdownSound.values,
        fallback: CountdownSound.pulse,
      ),
      exerciseFinishedDingSound: _readEnum(
        prefs,
        key: _exerciseFinishedDingSoundKey,
        values: ExerciseFinishedDingSound.values,
        fallback: ExerciseFinishedDingSound.classic,
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
    await _setInt(
      currentValue: state.streakWorkoutsPerWeek,
      value: value,
      key: _streakWorkoutsPerWeekKey,
      normalize: (int value) => value.clamp(1, 14).toInt(),
      update: (int value) => state.copyWith(streakWorkoutsPerWeek: value),
    );
  }

  Future<void> setAudioCuesEnabled(bool value) async {
    await _setBool(
      currentValue: state.audioCuesEnabled,
      value: value,
      key: _audioCuesEnabledKey,
      update: (bool value) => state.copyWith(audioCuesEnabled: value),
    );
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

  Future<void> setAudioVolume(double value) async {
    await _setVolume(
      currentValue: state.audioVolume,
      value: value,
      key: _audioVolumeKey,
      update: (double value) => state.copyWith(audioVolume: value),
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

  Future<void> setGetReadyDingSound(GetReadyDingSound value) async {
    await _setEnum(
      currentValue: state.getReadyDingSound,
      value: value,
      key: _getReadyDingSoundKey,
      update: (GetReadyDingSound value) =>
          state.copyWith(getReadyDingSound: value),
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

  Future<void> applySettings(AppSettings settings) async {
    await setThemePreference(settings.themePreference);
    await setUnitSystem(settings.unitSystem);
    await setStreakWorkoutsPerWeek(settings.streakWorkoutsPerWeek);
    await setAudioCuesEnabled(settings.audioCuesEnabled);
    await setMetronomeClickSound(settings.metronomeClickSound);
    await setAudioVolume(settings.audioVolume);
    await setGetReadyCountdownSound(settings.getReadyCountdownSound);
    await setGetReadyDingSound(settings.getReadyDingSound);
    await setExerciseCountdownSound(settings.exerciseCountdownSound);
    await setExerciseFinishedDingSound(settings.exerciseFinishedDingSound);
  }

  int _readStreakWorkoutsPerWeek(SharedPreferences prefs) {
    final int raw = prefs.getInt(_streakWorkoutsPerWeekKey) ?? 3;
    return raw.clamp(1, 14);
  }

  double _readAudioVolume(SharedPreferences prefs) {
    final double? raw = prefs.getDouble(_audioVolumeKey) ??
        prefs.getDouble(_legacyMetronomeVolumeKey);
    return (raw ?? 0.8).clamp(0, 1).toDouble();
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

  Future<void> _setBool({
    required bool currentValue,
    required bool value,
    required String key,
    required AppSettings Function(bool value) update,
  }) async {
    if (currentValue == value) {
      return;
    }
    state = update(value);
    await _prefs.setBool(key, value);
  }

  Future<void> _setInt({
    required int currentValue,
    required int value,
    required String key,
    required int Function(int value) normalize,
    required AppSettings Function(int value) update,
  }) async {
    final int normalized = normalize(value);
    if (currentValue == normalized) {
      return;
    }
    state = update(normalized);
    await _prefs.setInt(key, normalized);
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
