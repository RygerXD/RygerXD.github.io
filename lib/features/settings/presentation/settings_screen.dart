import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(appSettingsProvider);
    final AppSettingsController controller = ref.read(appSettingsProvider.notifier);

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
}
