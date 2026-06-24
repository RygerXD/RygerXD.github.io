import 'dart:convert';

import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

const String soundSettingsFormat = 'workout_app_rewrite.sounds';
const int soundSettingsFormatVersion = 1;

const Map<String, String> _customSoundKeys = <String, String>{
  WorkoutSoundCue.metronome: 'metronomeClickCustomSound',
  WorkoutSoundCue.getReadyCountdown: 'getReadyCountdownCustomSound',
  WorkoutSoundCue.getReadyDing: 'getReadyDingCustomSound',
  WorkoutSoundCue.moveHalfway: 'moveHalfwayCustomSound',
  WorkoutSoundCue.moveFinished: 'moveFinishedDingCustomSound',
  WorkoutSoundCue.workoutComplete: 'workoutCompleteCustomSound',
  WorkoutSoundCue.workoutEndedEarly: 'workoutEndedEarlyCustomSound',
};

Map<String, dynamic> encodeSoundSettings(AppSettings settings) {
  final List<CustomWorkoutSound> sounds = <CustomWorkoutSound>[];
  final Map<String, String> soundIds = <String, String>{};

  String addSound(CustomWorkoutSound sound) {
    return soundIds.putIfAbsent(sound.audioIdentity, () {
      sounds.add(sound);
      return 'sound-${sounds.length}';
    });
  }

  for (final CustomWorkoutSound sound in settings.customSoundLibrary) {
    addSound(sound);
  }

  final Map<String, String> selections = <String, String>{};
  for (final MapEntry<String, CustomWorkoutSound?> entry
      in settings.customSoundsByCue.entries) {
    if (entry.value != null) selections[entry.key] = addSound(entry.value!);
  }

  return <String, dynamic>{
    'format': soundSettingsFormat,
    'formatVersion': soundSettingsFormatVersion,
    'createdAt': DateTime.now().toUtc().toIso8601String(),
    'settings': <String, dynamic>{
      'audioCuesEnabled': settings.audioCuesEnabled,
      'audioVolume': settings.audioVolume,
      'soundSelections': settings.soundSelections,
      'metronomeClickEnabled': settings.metronomeClickEnabled,
      'getReadyCountdownEnabled': settings.getReadyCountdownEnabled,
      'getReadyDingEnabled': settings.getReadyDingEnabled,
      'moveHalfwayEnabled': settings.moveHalfwayEnabled,
      'moveFinishedDingEnabled': settings.moveFinishedDingEnabled,
      'workoutCompleteEnabled': settings.workoutCompleteEnabled,
      'workoutEndedEarlyEnabled': settings.workoutEndedEarlyEnabled,
    },
    'sounds': <Map<String, dynamic>>[
      for (int index = 0; index < sounds.length; index++)
        <String, dynamic>{
          'id': 'sound-${index + 1}',
          ...sounds[index].toJson(),
        },
    ],
    'customSoundSelections': selections,
  };
}

AppSettings decodeSoundSettings(Object? decoded) {
  if (decoded is! Map<String, dynamic> ||
      decoded['format'] != soundSettingsFormat) {
    throw const FormatException('Not a valid sounds export.');
  }
  final Object? version = decoded['formatVersion'];
  final Object? rawSettings = decoded['settings'];
  if (rawSettings is! Map<String, dynamic>) {
    throw const FormatException('Sounds settings are missing.');
  }
  if (version != soundSettingsFormatVersion) {
    throw const FormatException('Unsupported sounds export version.');
  }

  final Map<String, CustomWorkoutSound> soundsById =
      <String, CustomWorkoutSound>{};
  final Object? rawSounds = decoded['sounds'];
  if (rawSounds is! List<dynamic>) {
    throw const FormatException('Sound library is missing.');
  }
  for (final Object? rawSound in rawSounds) {
    if (rawSound is! Map<String, dynamic> || rawSound['id'] is! String) {
      throw const FormatException('Invalid sound library entry.');
    }
    soundsById[rawSound['id'] as String] =
        CustomWorkoutSound.fromJson(rawSound);
  }

  final Map<String, dynamic> settingsJson = <String, dynamic>{
    ...rawSettings,
    'customSoundLibrary': soundsById.values
        .map((CustomWorkoutSound sound) => sound.toJson())
        .toList(growable: false),
  };
  final Object? rawSelections = decoded['customSoundSelections'];
  if (rawSelections is Map<String, dynamic>) {
    for (final MapEntry<String, dynamic> entry in rawSelections.entries) {
      final String? settingsKey = _customSoundKeys[entry.key];
      final CustomWorkoutSound? sound = soundsById[entry.value];
      if (settingsKey == null || sound == null) {
        throw const FormatException('Invalid custom sound selection.');
      }
      settingsJson[settingsKey] = sound.toJson();
    }
  }
  return AppSettings.fromJson(settingsJson);
}

String encodeSoundSettingsJson(AppSettings settings) =>
    const JsonEncoder.withIndent('  ').convert(encodeSoundSettings(settings));
