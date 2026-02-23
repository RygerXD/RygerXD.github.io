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

class AppSettings {
  const AppSettings({
    required this.themePreference,
    required this.unitSystem,
    required this.audioCuesEnabled,
  });

  final AppThemePreference themePreference;
  final AppUnitSystem unitSystem;
  final bool audioCuesEnabled;

  AppSettings copyWith({
    AppThemePreference? themePreference,
    AppUnitSystem? unitSystem,
    bool? audioCuesEnabled,
  }) {
    return AppSettings(
      themePreference: themePreference ?? this.themePreference,
      unitSystem: unitSystem ?? this.unitSystem,
      audioCuesEnabled: audioCuesEnabled ?? this.audioCuesEnabled,
    );
  }
}

final NotifierProvider<AppSettingsController, AppSettings> appSettingsProvider =
    NotifierProvider<AppSettingsController, AppSettings>(AppSettingsController.new);

final Provider<ThemeMode> appThemeModeProvider = Provider<ThemeMode>((Ref<ThemeMode> ref) {
  final AppThemePreference preference = ref.watch(appSettingsProvider.select((AppSettings value) => value.themePreference));
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
  return ref.watch(appSettingsProvider.select((AppSettings value) => value.audioCuesEnabled));
});

final Provider<AppUnitSystem> appUnitSystemProvider = Provider<AppUnitSystem>((Ref<AppUnitSystem> ref) {
  return ref.watch(appSettingsProvider.select((AppSettings value) => value.unitSystem));
});

class AppSettingsController extends Notifier<AppSettings> {
  static const String _themePreferenceKey = 'settings.theme_preference.v1';
  static const String _unitSystemKey = 'settings.unit_system.v1';
  static const String _audioCuesEnabledKey = 'settings.audio_cues_enabled.v1';

  @override
  AppSettings build() {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    return AppSettings(
      themePreference: _readThemePreference(prefs),
      unitSystem: _readUnitSystem(prefs),
      audioCuesEnabled: prefs.getBool(_audioCuesEnabledKey) ?? true,
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

  Future<void> setAudioCuesEnabled(bool value) async {
    if (state.audioCuesEnabled == value) {
      return;
    }
    state = state.copyWith(audioCuesEnabled: value);
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    await prefs.setBool(_audioCuesEnabledKey, value);
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
}
