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
        ListTile(
          title: const Text('Streak goal'),
          subtitle: Text(_streakGoalLabel(settings.streakWorkoutsPerWeek)),
          trailing: SizedBox(
            width: 132,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                IconButton.filledTonal(
                  tooltip: 'Decrease streak goal',
                  onPressed: settings.streakWorkoutsPerWeek <= 1
                      ? null
                      : () {
                          controller.setStreakWorkoutsPerWeek(
                            settings.streakWorkoutsPerWeek - 1,
                          );
                        },
                  icon: const Icon(Icons.remove),
                ),
                SizedBox(
                  width: 36,
                  child: Text(
                    '${settings.streakWorkoutsPerWeek}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Increase streak goal',
                  onPressed: settings.streakWorkoutsPerWeek >= 14
                      ? null
                      : () {
                          controller.setStreakWorkoutsPerWeek(
                            settings.streakWorkoutsPerWeek + 1,
                          );
                        },
                  icon: const Icon(Icons.add),
                ),
              ],
            ),
          ),
        ),
        Divider(),
        SwitchListTile(
          title: Text('Audio cues'),
          subtitle: Text(settings.audioCuesEnabled ? 'Enabled' : 'Disabled'),
          value: settings.audioCuesEnabled,
          onChanged: controller.setAudioCuesEnabled,
        ),
        const SizedBox(height: AppSpacing.md),
        _SoundSetting<MetronomeClickSound>(
          title: 'Metronome click',
          dropdownLabel: 'Click sound',
          value: settings.metronomeClickSound,
          values: MetronomeClickSound.values,
          labelFor: _metronomeClickLabel,
          onChanged: controller.setMetronomeClickSound,
          onTest: () => unawaited(
            WorkoutAudio.playMetronomeClick(
              sound: settings.metronomeClickSound,
              volume: settings.metronomeVolume,
            ),
          ),
        ),
        _VolumeSetting(
          title: 'Metronome volume',
          value: settings.metronomeVolume,
          onChanged: controller.setMetronomeVolume,
        ),
        const SizedBox(height: AppSpacing.md),
        _SoundSetting<CountdownSound>(
          title: 'Get ready countdown',
          dropdownLabel: 'Countdown sound',
          value: settings.getReadyCountdownSound,
          values: CountdownSound.values,
          labelFor: _countdownLabel,
          onChanged: controller.setGetReadyCountdownSound,
          onTest: () => unawaited(
            WorkoutAudio.playGetReadyCountdown(
              sound: settings.getReadyCountdownSound,
              volume: settings.getReadyCountdownVolume,
            ),
          ),
        ),
        _VolumeSetting(
          title: 'Get ready countdown volume',
          value: settings.getReadyCountdownVolume,
          onChanged: controller.setGetReadyCountdownVolume,
        ),
        const SizedBox(height: AppSpacing.md),
        _SoundSetting<GetReadyDingSound>(
          title: 'Get ready ding',
          dropdownLabel: 'Ding sound',
          value: settings.getReadyDingSound,
          values: GetReadyDingSound.values,
          labelFor: _getReadyDingLabel,
          onChanged: controller.setGetReadyDingSound,
          onTest: () => unawaited(
            WorkoutAudio.playGetReadyDing(
              sound: settings.getReadyDingSound,
              volume: settings.getReadyDingVolume,
            ),
          ),
        ),
        _VolumeSetting(
          title: 'Get ready volume',
          value: settings.getReadyDingVolume,
          onChanged: controller.setGetReadyDingVolume,
        ),
        const SizedBox(height: AppSpacing.md),
        _SoundSetting<CountdownSound>(
          title: 'Exercise countdown',
          dropdownLabel: 'Exercise countdown sound',
          value: settings.exerciseCountdownSound,
          values: CountdownSound.values,
          labelFor: _countdownLabel,
          onChanged: controller.setExerciseCountdownSound,
          onTest: () => unawaited(
            WorkoutAudio.playExerciseCountdown(
              sound: settings.exerciseCountdownSound,
              volume: settings.exerciseCountdownVolume,
            ),
          ),
        ),
        _VolumeSetting(
          title: 'Exercise countdown volume',
          value: settings.exerciseCountdownVolume,
          onChanged: controller.setExerciseCountdownVolume,
        ),
        const SizedBox(height: AppSpacing.md),
        _SoundSetting<ExerciseFinishedDingSound>(
          title: 'Exercise finished ding',
          dropdownLabel: 'Finished ding sound',
          value: settings.exerciseFinishedDingSound,
          values: ExerciseFinishedDingSound.values,
          labelFor: _exerciseFinishedDingLabel,
          onChanged: controller.setExerciseFinishedDingSound,
          onTest: () => unawaited(
            WorkoutAudio.playExerciseFinishedDing(
              sound: settings.exerciseFinishedDingSound,
              volume: settings.exerciseFinishedDingVolume,
            ),
          ),
        ),
        _VolumeSetting(
          title: 'Exercise finished volume',
          value: settings.exerciseFinishedDingVolume,
          onChanged: controller.setExerciseFinishedDingVolume,
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

  static String _streakGoalLabel(int workoutsPerWeek) {
    final String workoutLabel = workoutsPerWeek == 1 ? 'workout' : 'workouts';
    return '$workoutsPerWeek $workoutLabel per week';
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

class _SoundSetting<T> extends StatelessWidget {
  const _SoundSetting({
    required this.title,
    required this.dropdownLabel,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
    required this.onTest,
  });

  final String title;
  final String dropdownLabel;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;
  final VoidCallback onTest;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        ListTile(
          title: Text(title),
          subtitle: Text(labelFor(value)),
          trailing: FilledButton.icon(
            onPressed: onTest,
            icon: const Icon(Icons.volume_up),
            label: const Text('Test'),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        DropdownButtonFormField<T>(
          initialValue: value,
          decoration: InputDecoration(
            labelText: dropdownLabel,
            border: const OutlineInputBorder(),
          ),
          items: values
              .map(
                (T value) => DropdownMenuItem<T>(
                  value: value,
                  child: Text(labelFor(value)),
                ),
              )
              .toList(growable: false),
          onChanged: (T? value) {
            if (value != null) {
              onChanged(value);
            }
          },
        ),
        const SizedBox(height: AppSpacing.md),
      ],
    );
  }
}

class _VolumeSetting extends StatelessWidget {
  const _VolumeSetting({
    required this.title,
    required this.value,
    required this.onChanged,
  });

  final String title;
  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final int percent = (value * 100).round();

    return ListTile(
      title: Text(title),
      subtitle: Slider(
        value: value,
        min: 0,
        max: 1,
        divisions: 20,
        label: '$percent%',
        onChanged: onChanged,
      ),
      trailing: SizedBox(
        width: 48,
        child: Text(
          '$percent%',
          textAlign: TextAlign.end,
        ),
      ),
    );
  }
}
