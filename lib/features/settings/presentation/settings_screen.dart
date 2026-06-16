import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/widgets/confirm_destructive_action.dart';
import 'package:workout_app_rewrite/features/active_workout/application/metronome_audio.dart';
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';
import 'package:workout_app_rewrite/features/settings/application/data_backup_service.dart';

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
        _VolumeSetting(
          title: 'Sound volume',
          value: settings.audioVolume,
          onChanged: controller.setAudioVolume,
        ),
        Divider(),
        ListTile(
          title: const Text('Backup and restore'),
          subtitle: const Text('Plans, history, and settings'),
        ),
        Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.sm,
          children: <Widget>[
            FilledButton.icon(
              onPressed: () => unawaited(_backUpData(context, ref)),
              icon: const Icon(Icons.backup_outlined),
              label: const Text('Back up data'),
            ),
            OutlinedButton.icon(
              onPressed: () => unawaited(_restoreData(context, ref)),
              icon: const Icon(Icons.restore_outlined),
              label: const Text('Restore backup'),
            ),
          ],
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
              volume: settings.audioVolume,
            ),
          ),
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
              volume: settings.audioVolume,
            ),
          ),
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
              volume: settings.audioVolume,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SoundSetting<CountdownSound>(
          title: 'Move countdown',
          dropdownLabel: 'Move countdown sound',
          value: settings.moveCountdownSound,
          values: CountdownSound.values,
          labelFor: _countdownLabel,
          onChanged: controller.setMoveCountdownSound,
          onTest: () => unawaited(
            WorkoutAudio.playMoveCountdown(
              sound: settings.moveCountdownSound,
              volume: settings.audioVolume,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _SoundSetting<MoveFinishedDingSound>(
          title: 'Move finished ding',
          dropdownLabel: 'Finished ding sound',
          value: settings.moveFinishedDingSound,
          values: MoveFinishedDingSound.values,
          labelFor: _moveFinishedDingLabel,
          onChanged: controller.setMoveFinishedDingSound,
          onTest: () => unawaited(
            WorkoutAudio.playMoveFinishedDing(
              sound: settings.moveFinishedDingSound,
              volume: settings.audioVolume,
            ),
          ),
        ),
      ],
    );
  }

  static String _themeLabel(AppThemePreference preference) =>
      switch (preference) {
        AppThemePreference.system => 'System',
        AppThemePreference.light => 'Light',
        AppThemePreference.dark => 'Dark',
      };

  static String _unitLabel(AppUnitSystem unitSystem) => switch (unitSystem) {
        AppUnitSystem.metric => 'Metric (kg)',
        AppUnitSystem.imperial => 'Imperial (lb)',
      };

  static String _streakGoalLabel(int workoutsPerWeek) {
    final String workoutLabel = workoutsPerWeek == 1 ? 'workout' : 'workouts';
    return '$workoutsPerWeek $workoutLabel per week';
  }

  static String _metronomeClickLabel(MetronomeClickSound sound) =>
      switch (sound) {
        MetronomeClickSound.classic => 'Classic',
        MetronomeClickSound.sharp => 'Sharp',
        MetronomeClickSound.low => 'Low',
        MetronomeClickSound.bell => 'Bell',
      };

  static String _getReadyDingLabel(GetReadyDingSound sound) => switch (sound) {
        GetReadyDingSound.classic => 'Classic ding',
        GetReadyDingSound.bright => 'Bright chime',
        GetReadyDingSound.soft => 'Soft ding',
        GetReadyDingSound.bell => 'Bell',
      };

  static String _countdownLabel(CountdownSound sound) => switch (sound) {
        CountdownSound.click => 'Click',
        CountdownSound.pulse => 'Pulse',
        CountdownSound.wood => 'Wood',
        CountdownSound.low => 'Low',
      };

  static String _moveFinishedDingLabel(MoveFinishedDingSound sound) =>
      switch (sound) {
        MoveFinishedDingSound.classic => 'Classic finish',
        MoveFinishedDingSound.bright => 'Bright finish',
        MoveFinishedDingSound.soft => 'Soft finish',
        MoveFinishedDingSound.bell => 'Bell',
      };

  static Future<void> _backUpData(BuildContext context, WidgetRef ref) async {
    try {
      final BackupExportResult? result =
          await ref.read(dataBackupServiceProvider).exportBackup();
      if (!context.mounted) {
        return;
      }
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      if (result == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Backup canceled.')),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Backup saved: ${result.planCount} plans, '
            '${result.sessionCount} sessions.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Backup failed: $error')),
      );
    }
  }

  static Future<void> _restoreData(BuildContext context, WidgetRef ref) async {
    final bool confirmed = await _confirmRestore(context);
    if (!confirmed || !context.mounted) {
      return;
    }

    try {
      final BackupRestoreResult? result =
          await ref.read(dataBackupServiceProvider).restoreBackup();
      if (!context.mounted) {
        return;
      }
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      if (result == null) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Restore canceled.')),
        );
        return;
      }
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'Backup restored: ${result.planCount} plans, '
            '${result.sessionCount} sessions.',
          ),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Restore failed: $error')),
      );
    }
  }

  static Future<bool> _confirmRestore(BuildContext context) async {
    return confirmDestructiveAction(
      context,
      title: 'Restore backup?',
      message:
          'This will replace current plans, workout history, and settings.',
      confirmLabel: 'Restore',
    );
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
