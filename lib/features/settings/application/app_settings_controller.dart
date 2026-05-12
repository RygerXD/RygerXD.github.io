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

class AppSettings {
  const AppSettings({
    required this.themePreference,
    required this.unitSystem,
    required this.audioCuesEnabled,
    required this.metronomeClickSound,
    required this.metronomeVolume,
  });

  final AppThemePreference themePreference;
  final AppUnitSystem unitSystem;
  final bool audioCuesEnabled;
  final MetronomeClickSound metronomeClickSound;
  final double metronomeVolume;

  AppSettings copyWith({
    AppThemePreference? themePreference,
    AppUnitSystem? unitSystem,
    bool? audioCuesEnabled,
    MetronomeClickSound? metronomeClickSound,
    double? metronomeVolume,
  }) {
    return AppSettings(
      themePreference: themePreference ?? this.themePreference,
      unitSystem: unitSystem ?? this.unitSystem,
      audioCuesEnabled: audioCuesEnabled ?? this.audioCuesEnabled,
      metronomeClickSound: metronomeClickSound ?? this.metronomeClickSound,
      metronomeVolume: metronomeVolume ?? this.metronomeVolume,
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

final Provider<AppUnitSystem> appUnitSystemProvider =
    Provider<AppUnitSystem>((Ref<AppUnitSystem> ref) {
  return ref.watch(
      appSettingsProvider.select((AppSettings value) => value.unitSystem));
});

class AppSettingsController extends Notifier<AppSettings> {
  static const String _themePreferenceKey = 'settings.theme_preference.v1';
  static const String _unitSystemKey = 'settings.unit_system.v1';
  static const String _audioCuesEnabledKey = 'settings.audio_cues_enabled.v1';
  static const String _metronomeClickSoundKey =
      'settings.metronome_click_sound.v1';
  static const String _metronomeVolumeKey = 'settings.metronome_volume.v1';

  @override
  AppSettings build() {
    final SharedPreferences prefs = ref.read(sharedPreferencesProvider);
    return AppSettings(
      themePreference: _readThemePreference(prefs),
      unitSystem: _readUnitSystem(prefs),
      audioCuesEnabled: prefs.getBool(_audioCuesEnabledKey) ?? true,
      metronomeClickSound: _readMetronomeClickSound(prefs),
      metronomeVolume: _readMetronomeVolume(prefs),
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
    final double? raw = prefs.getDouble(_metronomeVolumeKey);
    return (raw ?? 0.8).clamp(0, 1).toDouble();
  }
}
