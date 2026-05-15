import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/features/active_workout/application/metronome_audio.dart';
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(appSettingsProvider);
    final AppSettingsController controller =
        ref.read(appSettingsProvider.notifier);
    final int metronomeVolumePercent = (settings.metronomeVolume * 100).round();
    final int getReadyCountdownVolumePercent =
        (settings.getReadyCountdownVolume * 100).round();
    final int getReadyVolumePercent =
        (settings.getReadyDingVolume * 100).round();
    final int exerciseCountdownVolumePercent =
        (settings.exerciseCountdownVolume * 100).round();
    final int exerciseFinishedVolumePercent =
        (settings.exerciseFinishedDingVolume * 100).round();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: <Widget>[
        ListTile(
          title: Text('Theme'),
          subtitle: Text(_themeLabel(settings.themePreference)),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<AppThemePreference>(
          segments: const <ButtonSegment<AppThemePreference>>[
            ButtonSegment<AppThemePreference>(
              value: AppThemePreference.system,
              label: Text('System'),
              icon: Icon(Icons.phone_android),
            ),
            ButtonSegment<AppThemePreference>(
              value: AppThemePreference.light,
              label: Text('Light'),
              icon: Icon(Icons.light_mode_outlined),
            ),
            ButtonSegment<AppThemePreference>(
              value: AppThemePreference.dark,
              label: Text('Dark'),
              icon: Icon(Icons.dark_mode_outlined),
            ),
          ],
          selected: <AppThemePreference>{settings.themePreference},
          onSelectionChanged: (Set<AppThemePreference> selected) {
            controller.setThemePreference(selected.first);
          },
        ),
        Divider(),
        ListTile(
          title: Text('Units'),
          subtitle: Text(_unitLabel(settings.unitSystem)),
        ),
        const SizedBox(height: AppSpacing.sm),
        SegmentedButton<AppUnitSystem>(
          segments: const <ButtonSegment<AppUnitSystem>>[
            ButtonSegment<AppUnitSystem>(
              value: AppUnitSystem.metric,
              label: Text('Metric'),
            ),
            ButtonSegment<AppUnitSystem>(
              value: AppUnitSystem.imperial,
              label: Text('Imperial'),
            ),
          ],
          selected: <AppUnitSystem>{settings.unitSystem},
          onSelectionChanged: (Set<AppUnitSystem> selected) {
            controller.setUnitSystem(selected.first);
          },
        ),
        Divider(),
        SwitchListTile(
          title: Text('Audio cues'),
          subtitle: Text(settings.audioCuesEnabled ? 'Enabled' : 'Disabled'),
          value: settings.audioCuesEnabled,
          onChanged: controller.setAudioCuesEnabled,
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          title: const Text('Metronome click'),
          subtitle: Text(_metronomeClickLabel(settings.metronomeClickSound)),
          trailing: FilledButton.icon(
            onPressed: () {
              unawaited(
                WorkoutAudio.playMetronomeClick(
                  sound: settings.metronomeClickSound,
                  volume: settings.metronomeVolume,
                ),
              );
            },
            icon: const Icon(Icons.volume_up),
            label: const Text('Test'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<MetronomeClickSound>(
          initialValue: settings.metronomeClickSound,
          decoration: const InputDecoration(
            labelText: 'Click sound',
            border: OutlineInputBorder(),
          ),
          items: MetronomeClickSound.values
              .map(
                (MetronomeClickSound sound) =>
                    DropdownMenuItem<MetronomeClickSound>(
                  value: sound,
                  child: Text(_metronomeClickLabel(sound)),
                ),
              )
              .toList(growable: false),
          onChanged: (MetronomeClickSound? value) {
            if (value != null) {
              controller.setMetronomeClickSound(value);
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          title: const Text('Metronome volume'),
          subtitle: Slider(
            value: settings.metronomeVolume,
            min: 0,
            max: 1,
            divisions: 20,
            label: '$metronomeVolumePercent%',
            onChanged: controller.setMetronomeVolume,
          ),
          trailing: SizedBox(
            width: 48,
            child: Text(
              '$metronomeVolumePercent%',
              textAlign: TextAlign.end,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          title: const Text('Get ready countdown'),
          subtitle: Text(_countdownLabel(settings.getReadyCountdownSound)),
          trailing: FilledButton.icon(
            onPressed: () {
              unawaited(
                WorkoutAudio.playGetReadyCountdown(
                  sound: settings.getReadyCountdownSound,
                  volume: settings.getReadyCountdownVolume,
                ),
              );
            },
            icon: const Icon(Icons.volume_up),
            label: const Text('Test'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<CountdownSound>(
          initialValue: settings.getReadyCountdownSound,
          decoration: const InputDecoration(
            labelText: 'Countdown sound',
            border: OutlineInputBorder(),
          ),
          items: CountdownSound.values
              .map(
                (CountdownSound sound) => DropdownMenuItem<CountdownSound>(
                  value: sound,
                  child: Text(_countdownLabel(sound)),
                ),
              )
              .toList(growable: false),
          onChanged: (CountdownSound? value) {
            if (value != null) {
              controller.setGetReadyCountdownSound(value);
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          title: const Text('Get ready countdown volume'),
          subtitle: Slider(
            value: settings.getReadyCountdownVolume,
            min: 0,
            max: 1,
            divisions: 20,
            label: '$getReadyCountdownVolumePercent%',
            onChanged: controller.setGetReadyCountdownVolume,
          ),
          trailing: SizedBox(
            width: 48,
            child: Text(
              '$getReadyCountdownVolumePercent%',
              textAlign: TextAlign.end,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          title: const Text('Get ready ding'),
          subtitle: Text(_getReadyDingLabel(settings.getReadyDingSound)),
          trailing: FilledButton.icon(
            onPressed: () {
              unawaited(
                WorkoutAudio.playGetReadyDing(
                  sound: settings.getReadyDingSound,
                  volume: settings.getReadyDingVolume,
                ),
              );
            },
            icon: const Icon(Icons.volume_up),
            label: const Text('Test'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<GetReadyDingSound>(
          initialValue: settings.getReadyDingSound,
          decoration: const InputDecoration(
            labelText: 'Ding sound',
            border: OutlineInputBorder(),
          ),
          items: GetReadyDingSound.values
              .map(
                (GetReadyDingSound sound) =>
                    DropdownMenuItem<GetReadyDingSound>(
                  value: sound,
                  child: Text(_getReadyDingLabel(sound)),
                ),
              )
              .toList(growable: false),
          onChanged: (GetReadyDingSound? value) {
            if (value != null) {
              controller.setGetReadyDingSound(value);
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          title: const Text('Get ready volume'),
          subtitle: Slider(
            value: settings.getReadyDingVolume,
            min: 0,
            max: 1,
            divisions: 20,
            label: '$getReadyVolumePercent%',
            onChanged: controller.setGetReadyDingVolume,
          ),
          trailing: SizedBox(
            width: 48,
            child: Text(
              '$getReadyVolumePercent%',
              textAlign: TextAlign.end,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          title: const Text('Exercise countdown'),
          subtitle: Text(_countdownLabel(settings.exerciseCountdownSound)),
          trailing: FilledButton.icon(
            onPressed: () {
              unawaited(
                WorkoutAudio.playExerciseCountdown(
                  sound: settings.exerciseCountdownSound,
                  volume: settings.exerciseCountdownVolume,
                ),
              );
            },
            icon: const Icon(Icons.volume_up),
            label: const Text('Test'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<CountdownSound>(
          initialValue: settings.exerciseCountdownSound,
          decoration: const InputDecoration(
            labelText: 'Exercise countdown sound',
            border: OutlineInputBorder(),
          ),
          items: CountdownSound.values
              .map(
                (CountdownSound sound) => DropdownMenuItem<CountdownSound>(
                  value: sound,
                  child: Text(_countdownLabel(sound)),
                ),
              )
              .toList(growable: false),
          onChanged: (CountdownSound? value) {
            if (value != null) {
              controller.setExerciseCountdownSound(value);
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          title: const Text('Exercise countdown volume'),
          subtitle: Slider(
            value: settings.exerciseCountdownVolume,
            min: 0,
            max: 1,
            divisions: 20,
            label: '$exerciseCountdownVolumePercent%',
            onChanged: controller.setExerciseCountdownVolume,
          ),
          trailing: SizedBox(
            width: 48,
            child: Text(
              '$exerciseCountdownVolumePercent%',
              textAlign: TextAlign.end,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          title: const Text('Exercise finished ding'),
          subtitle: Text(
            _exerciseFinishedDingLabel(settings.exerciseFinishedDingSound),
          ),
          trailing: FilledButton.icon(
            onPressed: () {
              unawaited(
                WorkoutAudio.playExerciseFinishedDing(
                  sound: settings.exerciseFinishedDingSound,
                  volume: settings.exerciseFinishedDingVolume,
                ),
              );
            },
            icon: const Icon(Icons.volume_up),
            label: const Text('Test'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<ExerciseFinishedDingSound>(
          initialValue: settings.exerciseFinishedDingSound,
          decoration: const InputDecoration(
            labelText: 'Finished ding sound',
            border: OutlineInputBorder(),
          ),
          items: ExerciseFinishedDingSound.values
              .map(
                (ExerciseFinishedDingSound sound) =>
                    DropdownMenuItem<ExerciseFinishedDingSound>(
                  value: sound,
                  child: Text(_exerciseFinishedDingLabel(sound)),
                ),
              )
              .toList(growable: false),
          onChanged: (ExerciseFinishedDingSound? value) {
            if (value != null) {
              controller.setExerciseFinishedDingSound(value);
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
        ListTile(
          title: const Text('Exercise finished volume'),
          subtitle: Slider(
            value: settings.exerciseFinishedDingVolume,
            min: 0,
            max: 1,
            divisions: 20,
            label: '$exerciseFinishedVolumePercent%',
            onChanged: controller.setExerciseFinishedDingVolume,
          ),
          trailing: SizedBox(
            width: 48,
            child: Text(
              '$exerciseFinishedVolumePercent%',
              textAlign: TextAlign.end,
            ),
          ),
        ),
      ],
    );
  }

  static String _themeLabel(AppThemePreference preference) {
    switch (preference) {
      case AppThemePreference.system:
        return 'System';
      case AppThemePreference.light:
        return 'Light';
      case AppThemePreference.dark:
        return 'Dark';
    }
  }

  static String _unitLabel(AppUnitSystem unitSystem) {
    switch (unitSystem) {
      case AppUnitSystem.metric:
        return 'Metric (kg)';
      case AppUnitSystem.imperial:
        return 'Imperial (lb)';
    }
  }

  static String _metronomeClickLabel(MetronomeClickSound sound) {
    switch (sound) {
      case MetronomeClickSound.classic:
        return 'Classic';
      case MetronomeClickSound.sharp:
        return 'Sharp';
      case MetronomeClickSound.low:
        return 'Low';
      case MetronomeClickSound.bell:
        return 'Bell';
    }
  }

  static String _getReadyDingLabel(GetReadyDingSound sound) {
    switch (sound) {
      case GetReadyDingSound.classic:
        return 'Classic ding';
      case GetReadyDingSound.bright:
        return 'Bright chime';
      case GetReadyDingSound.soft:
        return 'Soft ding';
      case GetReadyDingSound.bell:
        return 'Bell';
    }
  }

  static String _countdownLabel(CountdownSound sound) {
    switch (sound) {
      case CountdownSound.click:
        return 'Click';
      case CountdownSound.pulse:
        return 'Pulse';
      case CountdownSound.wood:
        return 'Wood';
      case CountdownSound.low:
        return 'Low';
    }
  }

  static String _exerciseFinishedDingLabel(ExerciseFinishedDingSound sound) {
    switch (sound) {
      case ExerciseFinishedDingSound.classic:
        return 'Classic finish';
      case ExerciseFinishedDingSound.bright:
        return 'Bright finish';
      case ExerciseFinishedDingSound.soft:
        return 'Soft finish';
      case ExerciseFinishedDingSound.bell:
        return 'Bell';
    }
  }
}
