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

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          const _SettingsSectionHeading('Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(settings.themePreference)),
            trailing: DropdownButton<AppThemePreference>(
              value: settings.themePreference,
              underline: const SizedBox.shrink(),
              items: AppThemePreference.values
                  .map((AppThemePreference value) => DropdownMenuItem(
                        value: value,
                        child: Text(_themeLabel(value)),
                      ))
                  .toList(growable: false),
              onChanged: (AppThemePreference? value) {
                if (value != null) controller.setThemePreference(value);
              },
            ),
          ),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('Units'),
            subtitle: Text(_unitLabel(settings.unitSystem)),
            trailing: DropdownButton<AppUnitSystem>(
              value: settings.unitSystem,
              underline: const SizedBox.shrink(),
              items: AppUnitSystem.values
                  .map((AppUnitSystem value) => DropdownMenuItem(
                        value: value,
                        child: Text(_unitLabel(value)),
                      ))
                  .toList(growable: false),
              onChanged: (AppUnitSystem? value) {
                if (value != null) controller.setUnitSystem(value);
              },
            ),
          ),
          const Divider(),
          const _SettingsSectionHeading('Workout'),
          ListTile(
            leading: const Icon(Icons.flag_outlined),
            title: const Text('Weekly workout goal'),
            subtitle: Text(_streakGoalLabel(settings.streakWorkoutsPerWeek)),
            trailing: SizedBox(
              width: 132,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  IconButton.filledTonal(
                    tooltip: 'Decrease weekly workout goal',
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
                    tooltip: 'Increase weekly workout goal',
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
          SwitchListTile(
            secondary: const Icon(Icons.phone_android_outlined),
            title: const Text('Keep screen on during workout'),
            subtitle:
                const Text('Prevent screen sleep while the workout is open'),
            value: settings.keepScreenOnDuringWorkout,
            onChanged: controller.setKeepScreenOnDuringWorkout,
          ),
          const Divider(),
          const _SettingsSectionHeading('Audio'),
          ListTile(
            leading: const Icon(Icons.volume_up_outlined),
            title: const Text('Sounds'),
            subtitle: Text(
              settings.audioCuesEnabled ? 'Audio cues enabled' : 'Muted',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/settings/sounds'),
          ),
          const Divider(),
          const _SettingsSectionHeading('Data'),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('Backup and restore'),
            subtitle: const Text('Plans, history, and settings'),
          ),
          Row(
            children: <Widget>[
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => unawaited(_backUpData(context, ref)),
                  icon: const Icon(Icons.backup_outlined),
                  label: const Text('Back up'),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => unawaited(_restoreData(context, ref)),
                  icon: const Icon(Icons.restore_outlined),
                  label: const Text('Restore'),
                ),
              ),
            ],
          ),
        ],
      ),
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

class _SettingsSectionHeading extends StatelessWidget {
  const _SettingsSectionHeading(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
      ),
    );
  }
}
