import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

const Object _settingsUnset = Object();

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

enum MoveFinishedDingSound {
  classic,
  bright,
  soft,
  bell,
}

abstract final class WorkoutSoundCue {
  static const String metronome = 'metronome';
  static const String getReadyCountdown = 'getReadyCountdown';
  static const String getReadyDing = 'getReadyDing';
  static const String moveHalfway = 'moveHalfway';
  static const String moveFinished = 'moveFinished';
  static const String workoutComplete = 'workoutComplete';
  static const String workoutEndedEarly = 'workoutEndedEarly';
}

const Map<String, String> defaultSoundSelections = <String, String>{
  WorkoutSoundCue.metronome: 'classic',
  WorkoutSoundCue.getReadyCountdown: 'click',
  WorkoutSoundCue.getReadyDing: 'classic',
  WorkoutSoundCue.moveHalfway: 'soft',
  WorkoutSoundCue.moveFinished: 'classic',
  WorkoutSoundCue.workoutComplete: 'bright',
  WorkoutSoundCue.workoutEndedEarly: 'low',
};

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
    required this.moveFinishedDingSound,
    this.keepScreenOnDuringWorkout = false,
    this.soundSelections = defaultSoundSelections,
    this.customSoundLibrary = const <CustomWorkoutSound>[],
    this.metronomeClickCustomSound,
    this.getReadyCountdownCustomSound,
    this.getReadyDingCustomSound,
    this.moveFinishedDingCustomSound,
    this.moveHalfwayCustomSound,
    this.workoutCompleteCustomSound,
    this.workoutEndedEarlyCustomSound,
    this.metronomeClickEnabled = true,
    this.getReadyCountdownEnabled = true,
    this.getReadyDingEnabled = true,
    this.moveFinishedDingEnabled = true,
    this.moveHalfwayEnabled = true,
    this.workoutCompleteEnabled = true,
    this.workoutEndedEarlyEnabled = true,
  });

  final AppThemePreference themePreference;
  final AppUnitSystem unitSystem;
  final int streakWorkoutsPerWeek;
  final bool audioCuesEnabled;
  final MetronomeClickSound metronomeClickSound;
  final double audioVolume;
  final CountdownSound getReadyCountdownSound;
  final GetReadyDingSound getReadyDingSound;
  final MoveFinishedDingSound moveFinishedDingSound;
  final bool keepScreenOnDuringWorkout;
  final Map<String, String> soundSelections;
  final List<CustomWorkoutSound> customSoundLibrary;
  final CustomWorkoutSound? metronomeClickCustomSound;
  final CustomWorkoutSound? getReadyCountdownCustomSound;
  final CustomWorkoutSound? getReadyDingCustomSound;
  final CustomWorkoutSound? moveFinishedDingCustomSound;
  final CustomWorkoutSound? moveHalfwayCustomSound;
  final CustomWorkoutSound? workoutCompleteCustomSound;
  final CustomWorkoutSound? workoutEndedEarlyCustomSound;
  final bool metronomeClickEnabled;
  final bool getReadyCountdownEnabled;
  final bool getReadyDingEnabled;
  final bool moveFinishedDingEnabled;
  final bool moveHalfwayEnabled;
  final bool workoutCompleteEnabled;
  final bool workoutEndedEarlyEnabled;

  AppSettings copyWith({
    AppThemePreference? themePreference,
    AppUnitSystem? unitSystem,
    int? streakWorkoutsPerWeek,
    bool? audioCuesEnabled,
    MetronomeClickSound? metronomeClickSound,
    double? audioVolume,
    CountdownSound? getReadyCountdownSound,
    GetReadyDingSound? getReadyDingSound,
    MoveFinishedDingSound? moveFinishedDingSound,
    bool? keepScreenOnDuringWorkout,
    Map<String, String>? soundSelections,
    List<CustomWorkoutSound>? customSoundLibrary,
    Object? metronomeClickCustomSound = _settingsUnset,
    Object? getReadyCountdownCustomSound = _settingsUnset,
    Object? getReadyDingCustomSound = _settingsUnset,
    Object? moveFinishedDingCustomSound = _settingsUnset,
    Object? moveHalfwayCustomSound = _settingsUnset,
    Object? workoutCompleteCustomSound = _settingsUnset,
    Object? workoutEndedEarlyCustomSound = _settingsUnset,
    bool? metronomeClickEnabled,
    bool? getReadyCountdownEnabled,
    bool? getReadyDingEnabled,
    bool? moveFinishedDingEnabled,
    bool? moveHalfwayEnabled,
    bool? workoutCompleteEnabled,
    bool? workoutEndedEarlyEnabled,
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
      moveFinishedDingSound:
          moveFinishedDingSound ?? this.moveFinishedDingSound,
      keepScreenOnDuringWorkout:
          keepScreenOnDuringWorkout ?? this.keepScreenOnDuringWorkout,
      soundSelections: soundSelections ?? this.soundSelections,
      customSoundLibrary: customSoundLibrary ?? this.customSoundLibrary,
      metronomeClickCustomSound:
          identical(metronomeClickCustomSound, _settingsUnset)
              ? this.metronomeClickCustomSound
              : metronomeClickCustomSound as CustomWorkoutSound?,
      getReadyCountdownCustomSound:
          identical(getReadyCountdownCustomSound, _settingsUnset)
              ? this.getReadyCountdownCustomSound
              : getReadyCountdownCustomSound as CustomWorkoutSound?,
      getReadyDingCustomSound:
          identical(getReadyDingCustomSound, _settingsUnset)
              ? this.getReadyDingCustomSound
              : getReadyDingCustomSound as CustomWorkoutSound?,
      moveFinishedDingCustomSound:
          identical(moveFinishedDingCustomSound, _settingsUnset)
              ? this.moveFinishedDingCustomSound
              : moveFinishedDingCustomSound as CustomWorkoutSound?,
      moveHalfwayCustomSound: identical(moveHalfwayCustomSound, _settingsUnset)
          ? this.moveHalfwayCustomSound
          : moveHalfwayCustomSound as CustomWorkoutSound?,
      workoutCompleteCustomSound:
          identical(workoutCompleteCustomSound, _settingsUnset)
              ? this.workoutCompleteCustomSound
              : workoutCompleteCustomSound as CustomWorkoutSound?,
      workoutEndedEarlyCustomSound:
          identical(workoutEndedEarlyCustomSound, _settingsUnset)
              ? this.workoutEndedEarlyCustomSound
              : workoutEndedEarlyCustomSound as CustomWorkoutSound?,
      metronomeClickEnabled:
          metronomeClickEnabled ?? this.metronomeClickEnabled,
      getReadyCountdownEnabled:
          getReadyCountdownEnabled ?? this.getReadyCountdownEnabled,
      getReadyDingEnabled: getReadyDingEnabled ?? this.getReadyDingEnabled,
      moveFinishedDingEnabled:
          moveFinishedDingEnabled ?? this.moveFinishedDingEnabled,
      moveHalfwayEnabled: moveHalfwayEnabled ?? this.moveHalfwayEnabled,
      workoutCompleteEnabled:
          workoutCompleteEnabled ?? this.workoutCompleteEnabled,
      workoutEndedEarlyEnabled:
          workoutEndedEarlyEnabled ?? this.workoutEndedEarlyEnabled,
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
      moveFinishedDingSound: _readEnum(
        json,
        key: 'moveFinishedDingSound',
        values: MoveFinishedDingSound.values,
        fallback: MoveFinishedDingSound.classic,
      ),
      keepScreenOnDuringWorkout:
          _readBool(json, key: 'keepScreenOnDuringWorkout', fallback: false),
      soundSelections: _readSoundSelections(json['soundSelections']),
      customSoundLibrary: _readCustomSoundList(json, 'customSoundLibrary'),
      metronomeClickCustomSound:
          _readCustomSound(json, 'metronomeClickCustomSound'),
      getReadyCountdownCustomSound:
          _readCustomSound(json, 'getReadyCountdownCustomSound'),
      getReadyDingCustomSound:
          _readCustomSound(json, 'getReadyDingCustomSound'),
      moveFinishedDingCustomSound:
          _readCustomSound(json, 'moveFinishedDingCustomSound'),
      moveHalfwayCustomSound: _readCustomSound(json, 'moveHalfwayCustomSound'),
      workoutCompleteCustomSound:
          _readCustomSound(json, 'workoutCompleteCustomSound'),
      workoutEndedEarlyCustomSound:
          _readCustomSound(json, 'workoutEndedEarlyCustomSound'),
      metronomeClickEnabled:
          _readBool(json, key: 'metronomeClickEnabled', fallback: true),
      getReadyCountdownEnabled:
          _readBool(json, key: 'getReadyCountdownEnabled', fallback: true),
      getReadyDingEnabled:
          _readBool(json, key: 'getReadyDingEnabled', fallback: true),
      moveFinishedDingEnabled:
          _readBool(json, key: 'moveFinishedDingEnabled', fallback: true),
      moveHalfwayEnabled:
          _readBool(json, key: 'moveHalfwayEnabled', fallback: true),
      workoutCompleteEnabled:
          _readBool(json, key: 'workoutCompleteEnabled', fallback: true),
      workoutEndedEarlyEnabled:
          _readBool(json, key: 'workoutEndedEarlyEnabled', fallback: true),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'themePreference': themePreference.name,
      'unitSystem': unitSystem.name,
      'streakWorkoutsPerWeek': streakWorkoutsPerWeek,
      'audioCuesEnabled': audioCuesEnabled,
      'metronomeClickSound': metronomeClickSound.name,
      'audioVolume': audioVolume,
      'getReadyCountdownSound': getReadyCountdownSound.name,
      'getReadyDingSound': getReadyDingSound.name,
      'moveFinishedDingSound': moveFinishedDingSound.name,
      'keepScreenOnDuringWorkout': keepScreenOnDuringWorkout,
      'soundSelections': soundSelections,
      'customSoundLibrary': customSoundLibrary
          .map((CustomWorkoutSound sound) => sound.toJson())
          .toList(growable: false),
      'metronomeClickEnabled': metronomeClickEnabled,
      'getReadyCountdownEnabled': getReadyCountdownEnabled,
      'getReadyDingEnabled': getReadyDingEnabled,
      'moveFinishedDingEnabled': moveFinishedDingEnabled,
      'moveHalfwayEnabled': moveHalfwayEnabled,
      'workoutCompleteEnabled': workoutCompleteEnabled,
      'workoutEndedEarlyEnabled': workoutEndedEarlyEnabled,
    };
    _putCustomSound(
        json, 'metronomeClickCustomSound', metronomeClickCustomSound);
    _putCustomSound(
        json, 'getReadyCountdownCustomSound', getReadyCountdownCustomSound);
    _putCustomSound(json, 'getReadyDingCustomSound', getReadyDingCustomSound);
    _putCustomSound(
        json, 'moveFinishedDingCustomSound', moveFinishedDingCustomSound);
    _putCustomSound(json, 'moveHalfwayCustomSound', moveHalfwayCustomSound);
    _putCustomSound(
        json, 'workoutCompleteCustomSound', workoutCompleteCustomSound);
    _putCustomSound(
        json, 'workoutEndedEarlyCustomSound', workoutEndedEarlyCustomSound);
    return json;
  }

  static CustomWorkoutSound? _readCustomSound(
    Map<String, dynamic> json,
    String key,
  ) {
    final Object? value = json[key];
    return value is Map<String, dynamic>
        ? CustomWorkoutSound.fromJson(value)
        : null;
  }

  static List<CustomWorkoutSound> _readCustomSoundList(
    Map<String, dynamic> json,
    String key,
  ) {
    final Object? value = json[key];
    if (value is! List<dynamic>) return const <CustomWorkoutSound>[];
    return value
        .whereType<Map<String, dynamic>>()
        .map(CustomWorkoutSound.fromJson)
        .toList(growable: false);
  }

  static Map<String, String> _readSoundSelections(Object? value) {
    final Map<String, String> result = <String, String>{
      ...defaultSoundSelections
    };
    if (value is Map<String, dynamic>) {
      for (final MapEntry<String, dynamic> entry in value.entries) {
        if (entry.value case final String sound when sound.trim().isNotEmpty) {
          result[entry.key] = sound;
        }
      }
    }
    return Map<String, String>.unmodifiable(result);
  }

  String soundFor(String cue) =>
      soundSelections[cue] ?? defaultSoundSelections[cue]!;

  Map<String, CustomWorkoutSound?> get customSoundsByCue =>
      <String, CustomWorkoutSound?>{
        WorkoutSoundCue.metronome: metronomeClickCustomSound,
        WorkoutSoundCue.getReadyCountdown: getReadyCountdownCustomSound,
        WorkoutSoundCue.getReadyDing: getReadyDingCustomSound,
        WorkoutSoundCue.moveHalfway: moveHalfwayCustomSound,
        WorkoutSoundCue.moveFinished: moveFinishedDingCustomSound,
        WorkoutSoundCue.workoutComplete: workoutCompleteCustomSound,
        WorkoutSoundCue.workoutEndedEarly: workoutEndedEarlyCustomSound,
      };

  static void _putCustomSound(
    Map<String, dynamic> json,
    String key,
    CustomWorkoutSound? sound,
  ) {
    if (sound != null) {
      json[key] = sound.toJson();
    }
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

final Provider<MoveFinishedDingSound> moveFinishedDingSoundProvider =
    _settingsSelector<MoveFinishedDingSound>(
        (AppSettings value) => value.moveFinishedDingSound);

final Provider<AppUnitSystem> appUnitSystemProvider =
    _settingsSelector<AppUnitSystem>((AppSettings value) => value.unitSystem);

final Provider<int> streakWorkoutsPerWeekProvider =
    _settingsSelector<int>((AppSettings value) => value.streakWorkoutsPerWeek);

final Provider<bool> keepScreenOnDuringWorkoutProvider =
    _settingsSelector<bool>(
        (AppSettings value) => value.keepScreenOnDuringWorkout);

class AppSettingsController extends Notifier<AppSettings> {
  static const String _themePreferenceKey = 'settings.theme_preference.v1';
  static const String _unitSystemKey = 'settings.unit_system.v1';
  static const String _streakWorkoutsPerWeekKey =
      'settings.streak_workouts_per_week.v1';
  static const String _audioCuesEnabledKey = 'settings.audio_cues_enabled.v1';
  static const String _metronomeClickSoundKey =
      'settings.metronome_click_sound.v1';
  static const String _audioVolumeKey = 'settings.audio_volume.v1';
  static const String _getReadyCountdownSoundKey =
      'settings.get_ready_countdown_sound.v1';
  static const String _getReadyDingSoundKey =
      'settings.get_ready_ding_sound.v1';
  static const String _moveFinishedDingSoundKey =
      'settings.move_finished_ding_sound.v1';
  static const String _keepScreenOnDuringWorkoutKey =
      'settings.keep_screen_on_during_workout.v1';
  static const String _metronomeClickCustomSoundKey =
      'settings.metronome_click_custom_sound.v1';
  static const String _getReadyCountdownCustomSoundKey =
      'settings.get_ready_countdown_custom_sound.v1';
  static const String _getReadyDingCustomSoundKey =
      'settings.get_ready_ding_custom_sound.v1';
  static const String _moveFinishedDingCustomSoundKey =
      'settings.move_finished_ding_custom_sound.v1';
  static const String _moveHalfwayCustomSoundKey =
      'settings.move_halfway_custom_sound.v1';
  static const String _customSoundLibraryKey =
      'settings.custom_sound_library.v1';
  static const String _soundSelectionsKey = 'settings.sound_selections.v1';
  static const String _workoutCompleteCustomSoundKey =
      'settings.workout_complete_custom_sound.v1';
  static const String _workoutEndedEarlyCustomSoundKey =
      'settings.workout_ended_early_custom_sound.v1';
  static const String _metronomeClickEnabledKey =
      'settings.metronome_click_enabled.v1';
  static const String _getReadyCountdownEnabledKey =
      'settings.get_ready_countdown_enabled.v1';
  static const String _getReadyDingEnabledKey =
      'settings.get_ready_ding_enabled.v1';
  static const String _moveFinishedDingEnabledKey =
      'settings.move_finished_ding_enabled.v1';
  static const String _moveHalfwayEnabledKey =
      'settings.move_halfway_enabled.v1';
  static const String _workoutCompleteEnabledKey =
      'settings.workout_complete_enabled.v1';
  static const String _workoutEndedEarlyEnabledKey =
      'settings.workout_ended_early_enabled.v1';

  static const Map<String, String> _customSoundKeys = <String, String>{
    WorkoutSoundCue.metronome: _metronomeClickCustomSoundKey,
    WorkoutSoundCue.getReadyCountdown: _getReadyCountdownCustomSoundKey,
    WorkoutSoundCue.getReadyDing: _getReadyDingCustomSoundKey,
    WorkoutSoundCue.moveFinished: _moveFinishedDingCustomSoundKey,
    WorkoutSoundCue.moveHalfway: _moveHalfwayCustomSoundKey,
    WorkoutSoundCue.workoutComplete: _workoutCompleteCustomSoundKey,
    WorkoutSoundCue.workoutEndedEarly: _workoutEndedEarlyCustomSoundKey,
  };

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
      moveFinishedDingSound: _readEnum(
        prefs,
        key: _moveFinishedDingSoundKey,
        values: MoveFinishedDingSound.values,
        fallback: MoveFinishedDingSound.classic,
      ),
      keepScreenOnDuringWorkout:
          prefs.getBool(_keepScreenOnDuringWorkoutKey) ?? false,
      soundSelections: _readSoundSelectionsPreference(prefs),
      customSoundLibrary: _readCustomSoundLibrary(prefs),
      metronomeClickCustomSound:
          _readCustomSoundPreference(prefs, _metronomeClickCustomSoundKey),
      getReadyCountdownCustomSound:
          _readCustomSoundPreference(prefs, _getReadyCountdownCustomSoundKey),
      getReadyDingCustomSound:
          _readCustomSoundPreference(prefs, _getReadyDingCustomSoundKey),
      moveFinishedDingCustomSound:
          _readCustomSoundPreference(prefs, _moveFinishedDingCustomSoundKey),
      moveHalfwayCustomSound:
          _readCustomSoundPreference(prefs, _moveHalfwayCustomSoundKey),
      workoutCompleteCustomSound:
          _readCustomSoundPreference(prefs, _workoutCompleteCustomSoundKey),
      workoutEndedEarlyCustomSound:
          _readCustomSoundPreference(prefs, _workoutEndedEarlyCustomSoundKey),
      metronomeClickEnabled: prefs.getBool(_metronomeClickEnabledKey) ?? true,
      getReadyCountdownEnabled:
          prefs.getBool(_getReadyCountdownEnabledKey) ?? true,
      getReadyDingEnabled: prefs.getBool(_getReadyDingEnabledKey) ?? true,
      moveFinishedDingEnabled:
          prefs.getBool(_moveFinishedDingEnabledKey) ?? true,
      moveHalfwayEnabled: prefs.getBool(_moveHalfwayEnabledKey) ?? true,
      workoutCompleteEnabled: prefs.getBool(_workoutCompleteEnabledKey) ?? true,
      workoutEndedEarlyEnabled:
          prefs.getBool(_workoutEndedEarlyEnabledKey) ?? true,
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

  Future<void> setMoveFinishedDingSound(MoveFinishedDingSound value) async {
    await _setEnum(
      currentValue: state.moveFinishedDingSound,
      value: value,
      key: _moveFinishedDingSoundKey,
      update: (MoveFinishedDingSound value) =>
          state.copyWith(moveFinishedDingSound: value),
    );
  }

  Future<void> setKeepScreenOnDuringWorkout(bool value) async {
    await _setBool(
      currentValue: state.keepScreenOnDuringWorkout,
      value: value,
      key: _keepScreenOnDuringWorkoutKey,
      update: (bool value) => state.copyWith(keepScreenOnDuringWorkout: value),
    );
  }

  Future<void> setSoundSelection(String cue, String sound) async {
    final Map<String, String> selections = <String, String>{
      ...state.soundSelections,
      cue: sound,
    };
    state = state.copyWith(
      soundSelections: Map<String, String>.unmodifiable(selections),
    );
    await _prefs.setString(_soundSelectionsKey, jsonEncode(selections));
  }

  Future<void> setMetronomeClickCustomSound(CustomWorkoutSound? value) =>
      _setCustomSoundForCue(WorkoutSoundCue.metronome, value);

  Future<void> setGetReadyCountdownCustomSound(CustomWorkoutSound? value) =>
      _setCustomSoundForCue(WorkoutSoundCue.getReadyCountdown, value);

  Future<void> setGetReadyDingCustomSound(CustomWorkoutSound? value) =>
      _setCustomSoundForCue(WorkoutSoundCue.getReadyDing, value);

  Future<void> setMoveFinishedDingCustomSound(CustomWorkoutSound? value) =>
      _setCustomSoundForCue(WorkoutSoundCue.moveFinished, value);

  Future<void> setMoveHalfwayCustomSound(CustomWorkoutSound? value) =>
      _setCustomSoundForCue(WorkoutSoundCue.moveHalfway, value);

  Future<void> addCustomSound(CustomWorkoutSound sound) async {
    if (state.customSoundLibrary.any(sound.hasSameAudio)) {
      return;
    }
    await _setCustomSoundLibrary(<CustomWorkoutSound>[
      ...state.customSoundLibrary,
      sound,
    ]);
  }

  Future<void> removeCustomSound(CustomWorkoutSound sound) async {
    bool matches(CustomWorkoutSound? value) =>
        value != null && sound.hasSameAudio(value);
    for (final MapEntry<String, CustomWorkoutSound?> entry
        in state.customSoundsByCue.entries) {
      if (matches(entry.value)) {
        await _setCustomSoundForCue(entry.key, null);
      }
    }
    await _setCustomSoundLibrary(state.customSoundLibrary
        .where((CustomWorkoutSound existing) => !matches(existing))
        .toList(growable: false));
  }

  Future<void> setWorkoutCompleteCustomSound(CustomWorkoutSound? value) =>
      _setCustomSoundForCue(WorkoutSoundCue.workoutComplete, value);

  Future<void> setWorkoutEndedEarlyCustomSound(CustomWorkoutSound? value) =>
      _setCustomSoundForCue(WorkoutSoundCue.workoutEndedEarly, value);

  Future<void> setMetronomeClickEnabled(bool value) => _setBool(
        currentValue: state.metronomeClickEnabled,
        value: value,
        key: _metronomeClickEnabledKey,
        update: (bool value) => state.copyWith(metronomeClickEnabled: value),
      );

  Future<void> setGetReadyCountdownEnabled(bool value) => _setBool(
        currentValue: state.getReadyCountdownEnabled,
        value: value,
        key: _getReadyCountdownEnabledKey,
        update: (bool value) => state.copyWith(getReadyCountdownEnabled: value),
      );

  Future<void> setGetReadyDingEnabled(bool value) => _setBool(
        currentValue: state.getReadyDingEnabled,
        value: value,
        key: _getReadyDingEnabledKey,
        update: (bool value) => state.copyWith(getReadyDingEnabled: value),
      );

  Future<void> setMoveFinishedDingEnabled(bool value) => _setBool(
        currentValue: state.moveFinishedDingEnabled,
        value: value,
        key: _moveFinishedDingEnabledKey,
        update: (bool value) => state.copyWith(moveFinishedDingEnabled: value),
      );

  Future<void> setMoveHalfwayEnabled(bool value) => _setBool(
        currentValue: state.moveHalfwayEnabled,
        value: value,
        key: _moveHalfwayEnabledKey,
        update: (bool value) => state.copyWith(moveHalfwayEnabled: value),
      );

  Future<void> setWorkoutCompleteEnabled(bool value) => _setBool(
        currentValue: state.workoutCompleteEnabled,
        value: value,
        key: _workoutCompleteEnabledKey,
        update: (bool value) => state.copyWith(workoutCompleteEnabled: value),
      );

  Future<void> setWorkoutEndedEarlyEnabled(bool value) => _setBool(
        currentValue: state.workoutEndedEarlyEnabled,
        value: value,
        key: _workoutEndedEarlyEnabledKey,
        update: (bool value) => state.copyWith(workoutEndedEarlyEnabled: value),
      );

  Future<void> applySettings(AppSettings settings) async {
    await setThemePreference(settings.themePreference);
    await setUnitSystem(settings.unitSystem);
    await setStreakWorkoutsPerWeek(settings.streakWorkoutsPerWeek);
    await setAudioCuesEnabled(settings.audioCuesEnabled);
    await setMetronomeClickSound(settings.metronomeClickSound);
    await setAudioVolume(settings.audioVolume);
    await setKeepScreenOnDuringWorkout(settings.keepScreenOnDuringWorkout);
    await _applyAudioCueSettings(settings);
  }

  Future<void> applyAudioSettings(AppSettings settings) async {
    await setAudioCuesEnabled(settings.audioCuesEnabled);
    await setAudioVolume(settings.audioVolume);
    await setMetronomeClickSound(settings.metronomeClickSound);
    await _applyAudioCueSettings(settings);
  }

  Future<void> _applyAudioCueSettings(AppSettings settings) async {
    await setGetReadyCountdownSound(settings.getReadyCountdownSound);
    await setGetReadyDingSound(settings.getReadyDingSound);
    await setMoveFinishedDingSound(settings.moveFinishedDingSound);
    for (final MapEntry<String, String> entry
        in settings.soundSelections.entries) {
      await setSoundSelection(
        entry.key,
        entry.value,
      );
    }
    for (final MapEntry<String, CustomWorkoutSound?> entry
        in settings.customSoundsByCue.entries) {
      await _setCustomSoundForCue(entry.key, entry.value);
    }
    await setMetronomeClickEnabled(settings.metronomeClickEnabled);
    await setGetReadyCountdownEnabled(settings.getReadyCountdownEnabled);
    await setGetReadyDingEnabled(settings.getReadyDingEnabled);
    await setMoveFinishedDingEnabled(settings.moveFinishedDingEnabled);
    await setMoveHalfwayEnabled(settings.moveHalfwayEnabled);
    await setWorkoutCompleteEnabled(settings.workoutCompleteEnabled);
    await setWorkoutEndedEarlyEnabled(settings.workoutEndedEarlyEnabled);
    await _setCustomSoundLibrary(settings.customSoundLibrary);
  }

  int _readStreakWorkoutsPerWeek(SharedPreferences prefs) {
    final int raw = prefs.getInt(_streakWorkoutsPerWeekKey) ?? 3;
    return raw.clamp(1, 14);
  }

  double _readAudioVolume(SharedPreferences prefs) {
    final double? raw = prefs.getDouble(_audioVolumeKey);
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

  CustomWorkoutSound? _readCustomSoundPreference(
    SharedPreferences prefs,
    String key,
  ) {
    final String? raw = prefs.getString(key);
    if (raw == null) {
      return null;
    }
    try {
      final Object? decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic>
          ? CustomWorkoutSound.fromJson(decoded)
          : null;
    } catch (_) {
      return null;
    }
  }

  List<CustomWorkoutSound> _readCustomSoundLibrary(SharedPreferences prefs) {
    final List<CustomWorkoutSound> sounds = <CustomWorkoutSound>[];
    final String? raw = prefs.getString(_customSoundLibraryKey);
    if (raw != null) {
      try {
        final Object? decoded = jsonDecode(raw);
        if (decoded is List<dynamic>) {
          sounds.addAll(decoded
              .whereType<Map<String, dynamic>>()
              .map(CustomWorkoutSound.fromJson));
        }
      } catch (_) {
        // Ignore a malformed library while preserving the rest of settings.
      }
    }
    for (final String key in <String>[
      _metronomeClickCustomSoundKey,
      _getReadyCountdownCustomSoundKey,
      _getReadyDingCustomSoundKey,
      _moveFinishedDingCustomSoundKey,
      _moveHalfwayCustomSoundKey,
      _workoutCompleteCustomSoundKey,
      _workoutEndedEarlyCustomSoundKey,
    ]) {
      final CustomWorkoutSound? sound = _readCustomSoundPreference(prefs, key);
      if (sound != null && !sounds.any(sound.hasSameAudio)) {
        sounds.add(sound);
      }
    }
    return List<CustomWorkoutSound>.unmodifiable(sounds);
  }

  Map<String, String> _readSoundSelectionsPreference(SharedPreferences prefs) {
    final String? raw = prefs.getString(_soundSelectionsKey);
    if (raw == null) return defaultSoundSelections;
    try {
      return AppSettings._readSoundSelections(jsonDecode(raw));
    } catch (_) {
      return defaultSoundSelections;
    }
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

  Future<void> _setCustomSound({
    required CustomWorkoutSound? value,
    required String key,
    required AppSettings Function(CustomWorkoutSound? value) update,
  }) async {
    state = update(value);
    if (value == null) {
      await _prefs.remove(key);
      return;
    }
    if (!state.customSoundLibrary
        .any((CustomWorkoutSound existing) => existing.hasSameAudio(value))) {
      await _setCustomSoundLibrary(<CustomWorkoutSound>[
        ...state.customSoundLibrary,
        value,
      ]);
    }
    await _prefs.setString(key, jsonEncode(value.toJson()));
  }

  Future<void> _setCustomSoundForCue(
    String cue,
    CustomWorkoutSound? value,
  ) {
    return _setCustomSound(
      value: value,
      key: _customSoundKeys[cue]!,
      update: (CustomWorkoutSound? sound) => switch (cue) {
        WorkoutSoundCue.metronome =>
          state.copyWith(metronomeClickCustomSound: sound),
        WorkoutSoundCue.getReadyCountdown =>
          state.copyWith(getReadyCountdownCustomSound: sound),
        WorkoutSoundCue.getReadyDing =>
          state.copyWith(getReadyDingCustomSound: sound),
        WorkoutSoundCue.moveHalfway =>
          state.copyWith(moveHalfwayCustomSound: sound),
        WorkoutSoundCue.moveFinished =>
          state.copyWith(moveFinishedDingCustomSound: sound),
        WorkoutSoundCue.workoutComplete =>
          state.copyWith(workoutCompleteCustomSound: sound),
        WorkoutSoundCue.workoutEndedEarly =>
          state.copyWith(workoutEndedEarlyCustomSound: sound),
        _ => state,
      },
    );
  }

  Future<void> _setCustomSoundLibrary(List<CustomWorkoutSound> sounds) async {
    final List<CustomWorkoutSound> merged = <CustomWorkoutSound>[...sounds];
    for (final CustomWorkoutSound? selected in state.customSoundsByCue.values) {
      if (selected != null && !merged.any(selected.hasSameAudio)) {
        merged.add(selected);
      }
    }
    final List<CustomWorkoutSound> value =
        List<CustomWorkoutSound>.unmodifiable(merged);
    state = state.copyWith(customSoundLibrary: value);
    await _prefs.setString(
      _customSoundLibraryKey,
      jsonEncode(
          value.map((CustomWorkoutSound sound) => sound.toJson()).toList()),
    );
  }
}
