import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/widgets/confirm_destructive_action.dart';
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
        ListTile(
          leading: const Icon(Icons.volume_up_outlined),
          title: const Text('Sounds'),
          subtitle: Text(
            settings.audioCuesEnabled ? 'Audio cues enabled' : 'Muted',
          ),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => context.push('/settings/sounds'),
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
