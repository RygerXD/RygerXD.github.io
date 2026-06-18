import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_app_rewrite/core/audio/custom_sound_field.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/features/active_workout/application/metronome_audio.dart';
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class SoundsScreen extends ConsumerWidget {
  const SoundsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(appSettingsProvider);
    final AppSettingsController controller =
        ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Sounds')),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: <Widget>[
          SwitchListTile(
            title: const Text('Audio cues'),
            subtitle: const Text('Master control for all workout sounds'),
            value: settings.audioCuesEnabled,
            onChanged: controller.setAudioCuesEnabled,
          ),
          _VolumeSetting(
            value: settings.audioVolume,
            onChanged: controller.setAudioVolume,
          ),
          const SizedBox(height: AppSpacing.md),
          _BuiltInSoundSetting<MetronomeClickSound>(
            title: 'Metronome click',
            enabled: settings.metronomeClickEnabled,
            onEnabledChanged: controller.setMetronomeClickEnabled,
            dropdownLabel: 'Built-in click',
            value: settings.metronomeClickSound,
            values: MetronomeClickSound.values,
            labelFor: _metronomeClickLabel,
            onChanged: controller.setMetronomeClickSound,
            customSound: settings.metronomeClickCustomSound,
            onCustomSoundChanged: controller.setMetronomeClickCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playMetronomeClick(
              sound: settings.metronomeClickSound,
              volume: settings.audioVolume,
            )),
          ),
          _BuiltInSoundSetting<CountdownSound>(
            title: 'Get ready countdown',
            enabled: settings.getReadyCountdownEnabled,
            onEnabledChanged: controller.setGetReadyCountdownEnabled,
            dropdownLabel: 'Built-in countdown',
            value: settings.getReadyCountdownSound,
            values: CountdownSound.values,
            labelFor: _countdownLabel,
            onChanged: controller.setGetReadyCountdownSound,
            customSound: settings.getReadyCountdownCustomSound,
            onCustomSoundChanged: controller.setGetReadyCountdownCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playGetReadyCountdown(
              sound: settings.getReadyCountdownSound,
              volume: settings.audioVolume,
            )),
          ),
          _BuiltInSoundSetting<GetReadyDingSound>(
            title: 'Get ready ding',
            enabled: settings.getReadyDingEnabled,
            onEnabledChanged: controller.setGetReadyDingEnabled,
            dropdownLabel: 'Built-in ding',
            value: settings.getReadyDingSound,
            values: GetReadyDingSound.values,
            labelFor: _getReadyDingLabel,
            onChanged: controller.setGetReadyDingSound,
            customSound: settings.getReadyDingCustomSound,
            onCustomSoundChanged: controller.setGetReadyDingCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playGetReadyDing(
              sound: settings.getReadyDingSound,
              volume: settings.audioVolume,
            )),
          ),
          _BuiltInSoundSetting<CountdownSound>(
            title: 'Move countdown',
            enabled: settings.moveCountdownEnabled,
            onEnabledChanged: controller.setMoveCountdownEnabled,
            dropdownLabel: 'Built-in countdown',
            value: settings.moveCountdownSound,
            values: CountdownSound.values,
            labelFor: _countdownLabel,
            onChanged: controller.setMoveCountdownSound,
            customSound: settings.moveCountdownCustomSound,
            onCustomSoundChanged: controller.setMoveCountdownCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playMoveCountdown(
              sound: settings.moveCountdownSound,
              volume: settings.audioVolume,
            )),
          ),
          _BuiltInSoundSetting<MoveFinishedDingSound>(
            title: 'Move finished ding',
            enabled: settings.moveFinishedDingEnabled,
            onEnabledChanged: controller.setMoveFinishedDingEnabled,
            dropdownLabel: 'Built-in finish',
            value: settings.moveFinishedDingSound,
            values: MoveFinishedDingSound.values,
            labelFor: _moveFinishedDingLabel,
            onChanged: controller.setMoveFinishedDingSound,
            customSound: settings.moveFinishedDingCustomSound,
            onCustomSoundChanged: controller.setMoveFinishedDingCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playMoveFinishedDing(
              sound: settings.moveFinishedDingSound,
              volume: settings.audioVolume,
            )),
          ),
          _TerminalSoundSetting(
            title: 'Rest finished',
            enabled: settings.restFinishedEnabled,
            onEnabledChanged: controller.setRestFinishedEnabled,
            customSound: settings.restFinishedCustomSound,
            onCustomSoundChanged: controller.setRestFinishedCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playRestFinished(
              volume: settings.audioVolume,
            )),
          ),
          _TerminalSoundSetting(
            title: 'Workout complete',
            enabled: settings.workoutCompleteEnabled,
            onEnabledChanged: controller.setWorkoutCompleteEnabled,
            customSound: settings.workoutCompleteCustomSound,
            onCustomSoundChanged: controller.setWorkoutCompleteCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playWorkoutComplete(
              volume: settings.audioVolume,
            )),
          ),
          _TerminalSoundSetting(
            title: 'Workout ended early',
            enabled: settings.workoutEndedEarlyEnabled,
            onEnabledChanged: controller.setWorkoutEndedEarlyEnabled,
            customSound: settings.workoutEndedEarlyCustomSound,
            onCustomSoundChanged: controller.setWorkoutEndedEarlyCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playWorkoutEndedEarly(
              volume: settings.audioVolume,
            )),
          ),
        ],
      ),
    );
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
}

class _BuiltInSoundSetting<T> extends StatelessWidget {
  const _BuiltInSoundSetting({
    required this.title,
    required this.enabled,
    required this.onEnabledChanged,
    required this.dropdownLabel,
    required this.value,
    required this.values,
    required this.labelFor,
    required this.onChanged,
    required this.customSound,
    required this.onCustomSoundChanged,
    required this.volume,
    required this.onTestDefault,
  });

  final String title;
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final String dropdownLabel;
  final T value;
  final List<T> values;
  final String Function(T value) labelFor;
  final ValueChanged<T> onChanged;
  final CustomWorkoutSound? customSound;
  final ValueChanged<CustomWorkoutSound?> onCustomSoundChanged;
  final double volume;
  final VoidCallback onTestDefault;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: <Widget>[
          SwitchListTile(
            title: Text(title),
            value: enabled,
            onChanged: onEnabledChanged,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: DropdownButtonFormField<T>(
              initialValue: value,
              decoration: InputDecoration(
                labelText: dropdownLabel,
                border: const OutlineInputBorder(),
              ),
              items: values
                  .map((T item) => DropdownMenuItem<T>(
                        value: item,
                        child: Text(labelFor(item)),
                      ))
                  .toList(growable: false),
              onChanged: (T? next) {
                if (next != null) onChanged(next);
              },
            ),
          ),
          CustomSoundField(
            title: 'Custom override',
            value: customSound,
            volume: volume,
            onChanged: onCustomSoundChanged,
            onTestDefault: onTestDefault,
            card: false,
          ),
        ],
      ),
    );
  }
}

class _TerminalSoundSetting extends StatelessWidget {
  const _TerminalSoundSetting({
    required this.title,
    required this.enabled,
    required this.onEnabledChanged,
    required this.customSound,
    required this.onCustomSoundChanged,
    required this.volume,
    required this.onTestDefault,
  });

  final String title;
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final CustomWorkoutSound? customSound;
  final ValueChanged<CustomWorkoutSound?> onCustomSoundChanged;
  final double volume;
  final VoidCallback onTestDefault;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        children: <Widget>[
          SwitchListTile(
            title: Text(title),
            value: enabled,
            onChanged: onEnabledChanged,
          ),
          CustomSoundField(
            title: 'Sound',
            value: customSound,
            volume: volume,
            onChanged: onCustomSoundChanged,
            onTestDefault: onTestDefault,
            card: false,
          ),
        ],
      ),
    );
  }
}

class _VolumeSetting extends StatelessWidget {
  const _VolumeSetting({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: const Text('Sound volume'),
      subtitle: Slider(value: value, onChanged: onChanged),
      trailing: Text('${(value * 100).round()}%'),
    );
  }
}
