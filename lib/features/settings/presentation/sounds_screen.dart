import 'dart:async';
import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_app_rewrite/core/audio/custom_sound_field.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/features/active_workout/application/metronome_audio.dart';
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';
import 'package:workout_app_rewrite/features/settings/application/sound_settings_transfer.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class SoundsScreen extends ConsumerWidget {
  const SoundsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppSettings settings = ref.watch(appSettingsProvider);
    final AppSettingsController controller =
        ref.read(appSettingsProvider.notifier);
    final List<CustomWorkoutSound> library = _soundPool(settings);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sounds'),
        actions: <Widget>[
          PopupMenuButton<String>(
            tooltip: 'Import or export sounds',
            onSelected: (String value) => unawaited(value == 'import'
                ? _importSounds(context, ref)
                : _exportSounds(context, settings)),
            itemBuilder: (BuildContext context) =>
                const <PopupMenuEntry<String>>[
              PopupMenuItem<String>(
                value: 'import',
                child: ListTile(
                  leading: Icon(Icons.file_download_outlined),
                  title: Text('Import sounds'),
                ),
              ),
              PopupMenuItem<String>(
                value: 'export',
                child: ListTile(
                  leading: Icon(Icons.file_upload_outlined),
                  title: Text('Export sounds'),
                ),
              ),
            ],
          ),
        ],
      ),
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
          ListTile(
            title: const Text('Custom sound pool'),
            subtitle: Text(library.isEmpty
                ? 'Imported sounds will be available for every cue.'
                : '${library.length} sound${library.length == 1 ? '' : 's'} available for every cue.'),
            trailing: FilledButton.icon(
              onPressed: () => unawaited(_addSound(context, controller)),
              icon: const Icon(Icons.add),
              label: const Text('Add sound'),
            ),
          ),
          if (library.isNotEmpty)
            Card(
              margin: const EdgeInsets.only(bottom: AppSpacing.md),
              child: Column(
                children: library
                    .map((CustomWorkoutSound sound) => ListTile(
                          leading: IconButton(
                            tooltip: 'Test ${sound.fileName}',
                            icon: const Icon(Icons.play_arrow),
                            onPressed: () =>
                                unawaited(WorkoutAudio.playCustomSound(
                              sound: sound,
                              volume: settings.audioVolume,
                            )),
                          ),
                          title: Text(sound.fileName),
                          trailing: IconButton(
                            tooltip: 'Remove ${sound.fileName}',
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () =>
                                unawaited(controller.removeCustomSound(sound)),
                          ),
                        ))
                    .toList(growable: false),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          _SoundSetting(
            title: 'Metronome click',
            builtInSound: settings.soundFor(WorkoutSoundCue.metronome),
            onBuiltInChanged: (SharedWorkoutSound sound) =>
                controller.setSoundSelection(WorkoutSoundCue.metronome, sound),
            enabled: settings.metronomeClickEnabled,
            onEnabledChanged: controller.setMetronomeClickEnabled,
            value: settings.metronomeClickCustomSound,
            library: library,
            onChanged: controller.setMetronomeClickCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playMetronomeClick(
              sound: settings.metronomeClickSound,
              volume: settings.audioVolume,
            )),
          ),
          _SoundSetting(
            title: 'Get ready countdown',
            builtInSound: settings.soundFor(WorkoutSoundCue.getReadyCountdown),
            onBuiltInChanged: (SharedWorkoutSound sound) => controller
                .setSoundSelection(WorkoutSoundCue.getReadyCountdown, sound),
            enabled: settings.getReadyCountdownEnabled,
            onEnabledChanged: controller.setGetReadyCountdownEnabled,
            value: settings.getReadyCountdownCustomSound,
            library: library,
            onChanged: controller.setGetReadyCountdownCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playGetReadyCountdown(
              sound: settings.getReadyCountdownSound,
              volume: settings.audioVolume,
            )),
          ),
          _SoundSetting(
            title: 'Get ready ding',
            builtInSound: settings.soundFor(WorkoutSoundCue.getReadyDing),
            onBuiltInChanged: (SharedWorkoutSound sound) => controller
                .setSoundSelection(WorkoutSoundCue.getReadyDing, sound),
            enabled: settings.getReadyDingEnabled,
            onEnabledChanged: controller.setGetReadyDingEnabled,
            value: settings.getReadyDingCustomSound,
            library: library,
            onChanged: controller.setGetReadyDingCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playGetReadyDing(
              sound: settings.getReadyDingSound,
              volume: settings.audioVolume,
            )),
          ),
          _SoundSetting(
            title: 'Move countdown',
            builtInSound: settings.soundFor(WorkoutSoundCue.moveCountdown),
            onBuiltInChanged: (SharedWorkoutSound sound) => controller
                .setSoundSelection(WorkoutSoundCue.moveCountdown, sound),
            enabled: settings.moveCountdownEnabled,
            onEnabledChanged: controller.setMoveCountdownEnabled,
            value: settings.moveCountdownCustomSound,
            library: library,
            onChanged: controller.setMoveCountdownCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playMoveCountdown(
              sound: settings.moveCountdownSound,
              volume: settings.audioVolume,
            )),
          ),
          _SoundSetting(
            title: 'Move halfway done',
            builtInSound: settings.soundFor(WorkoutSoundCue.moveHalfway),
            onBuiltInChanged: (SharedWorkoutSound sound) => controller
                .setSoundSelection(WorkoutSoundCue.moveHalfway, sound),
            enabled: settings.moveHalfwayEnabled,
            onEnabledChanged: controller.setMoveHalfwayEnabled,
            value: settings.moveHalfwayCustomSound,
            library: library,
            onChanged: controller.setMoveHalfwayCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playMoveHalfway(
              volume: settings.audioVolume,
            )),
          ),
          _SoundSetting(
            title: 'Move finished ding',
            builtInSound: settings.soundFor(WorkoutSoundCue.moveFinished),
            onBuiltInChanged: (SharedWorkoutSound sound) => controller
                .setSoundSelection(WorkoutSoundCue.moveFinished, sound),
            enabled: settings.moveFinishedDingEnabled,
            onEnabledChanged: controller.setMoveFinishedDingEnabled,
            value: settings.moveFinishedDingCustomSound,
            library: library,
            onChanged: controller.setMoveFinishedDingCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playMoveFinishedDing(
              sound: settings.moveFinishedDingSound,
              volume: settings.audioVolume,
            )),
          ),
          _SoundSetting(
            title: 'Rest finished',
            builtInSound: settings.soundFor(WorkoutSoundCue.restFinished),
            onBuiltInChanged: (SharedWorkoutSound sound) => controller
                .setSoundSelection(WorkoutSoundCue.restFinished, sound),
            enabled: settings.restFinishedEnabled,
            onEnabledChanged: controller.setRestFinishedEnabled,
            value: settings.restFinishedCustomSound,
            library: library,
            onChanged: controller.setRestFinishedCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playRestFinished(
              volume: settings.audioVolume,
            )),
          ),
          _SoundSetting(
            title: 'Workout complete',
            builtInSound: settings.soundFor(WorkoutSoundCue.workoutComplete),
            onBuiltInChanged: (SharedWorkoutSound sound) => controller
                .setSoundSelection(WorkoutSoundCue.workoutComplete, sound),
            enabled: settings.workoutCompleteEnabled,
            onEnabledChanged: controller.setWorkoutCompleteEnabled,
            value: settings.workoutCompleteCustomSound,
            library: library,
            onChanged: controller.setWorkoutCompleteCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playWorkoutComplete(
              volume: settings.audioVolume,
            )),
          ),
          _SoundSetting(
            title: 'Workout ended early',
            builtInSound: settings.soundFor(WorkoutSoundCue.workoutEndedEarly),
            onBuiltInChanged: (SharedWorkoutSound sound) => controller
                .setSoundSelection(WorkoutSoundCue.workoutEndedEarly, sound),
            enabled: settings.workoutEndedEarlyEnabled,
            onEnabledChanged: controller.setWorkoutEndedEarlyEnabled,
            value: settings.workoutEndedEarlyCustomSound,
            library: library,
            onChanged: controller.setWorkoutEndedEarlyCustomSound,
            volume: settings.audioVolume,
            onTestDefault: () => unawaited(WorkoutAudio.playWorkoutEndedEarly(
              volume: settings.audioVolume,
            )),
          ),
        ],
      ),
    );
  }

  static List<CustomWorkoutSound> _soundPool(AppSettings settings) {
    final List<CustomWorkoutSound> result = <CustomWorkoutSound>[
      ...settings.customSoundLibrary,
    ];
    for (final CustomWorkoutSound? sound in <CustomWorkoutSound?>[
      settings.metronomeClickCustomSound,
      settings.getReadyCountdownCustomSound,
      settings.getReadyDingCustomSound,
      settings.moveCountdownCustomSound,
      settings.moveHalfwayCustomSound,
      settings.moveFinishedDingCustomSound,
      settings.restFinishedCustomSound,
      settings.workoutCompleteCustomSound,
      settings.workoutEndedEarlyCustomSound,
    ]) {
      if (sound != null && !_containsSound(result, sound)) result.add(sound);
    }
    return result;
  }

  static bool _containsSound(
          List<CustomWorkoutSound> sounds, CustomWorkoutSound sound) =>
      sounds.any((CustomWorkoutSound item) =>
          item.mimeType == sound.mimeType &&
          item.base64Data == sound.base64Data);

  static Future<void> _addSound(
    BuildContext context,
    AppSettingsController controller,
  ) async {
    final CustomWorkoutSound? sound =
        await pickCustomWorkoutSound(context, title: 'custom sound');
    if (sound != null) await controller.addCustomSound(sound);
  }

  static Future<void> _exportSounds(
    BuildContext context,
    AppSettings settings,
  ) async {
    try {
      final Uint8List bytes =
          Uint8List.fromList(utf8.encode(encodeSoundSettingsJson(settings)));
      final String? path = await FilePicker.platform.saveFile(
        dialogTitle: 'Export sounds',
        fileName: 'workout-sounds.json',
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
        bytes: bytes,
      );
      if (!context.mounted || (!kIsWeb && path == null)) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sounds exported.')),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not export sounds: $error')),
        );
      }
    }
  }

  static Future<void> _importSounds(BuildContext context, WidgetRef ref) async {
    try {
      final FilePickerResult? result = await FilePicker.platform.pickFiles(
        dialogTitle: 'Import sounds',
        type: FileType.custom,
        allowedExtensions: const <String>['json'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final Uint8List? bytes = result.files.single.bytes;
      if (bytes == null) throw const FormatException('Could not read file.');
      final Object? decoded = jsonDecode(utf8.decode(bytes));
      final AppSettings imported = decodeSoundSettings(decoded);
      await ref.read(appSettingsProvider.notifier).applyAudioSettings(imported);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sounds imported.')),
      );
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not import sounds: $error')),
        );
      }
    }
  }
}

class _SoundSetting extends StatelessWidget {
  const _SoundSetting({
    required this.title,
    required this.builtInSound,
    required this.onBuiltInChanged,
    required this.enabled,
    required this.onEnabledChanged,
    required this.value,
    required this.library,
    required this.onChanged,
    required this.volume,
    required this.onTestDefault,
  });

  final String title;
  final SharedWorkoutSound builtInSound;
  final ValueChanged<SharedWorkoutSound> onBuiltInChanged;
  final bool enabled;
  final ValueChanged<bool> onEnabledChanged;
  final CustomWorkoutSound? value;
  final List<CustomWorkoutSound> library;
  final ValueChanged<CustomWorkoutSound?> onChanged;
  final double volume;
  final VoidCallback onTestDefault;

  @override
  Widget build(BuildContext context) {
    final int builtInCount = SharedWorkoutSound.values.length;
    final int customIndex = value == null
        ? -1
        : library.indexWhere((CustomWorkoutSound item) =>
            item.mimeType == value!.mimeType &&
            item.base64Data == value!.base64Data);
    final int selected =
        value == null ? builtInSound.index : builtInCount + customIndex;
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
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: DropdownButtonFormField<int>(
                    initialValue: selected < builtInCount
                        ? selected
                        : customIndex < 0
                            ? builtInSound.index
                            : selected,
                    decoration: const InputDecoration(
                      labelText: 'Sound',
                      border: OutlineInputBorder(),
                    ),
                    items: <DropdownMenuItem<int>>[
                      ...SharedWorkoutSound.values.map(
                        (SharedWorkoutSound sound) => DropdownMenuItem<int>(
                          value: sound.index,
                          child: Text(_builtInLabel(sound)),
                        ),
                      ),
                      ...library.indexed.map(
                          ((int, CustomWorkoutSound) entry) =>
                              DropdownMenuItem<int>(
                                value: builtInCount + entry.$1,
                                child: Text(
                                  entry.$2.fileName,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )),
                    ],
                    onChanged: (int? index) {
                      if (index == null) return;
                      if (index < builtInCount) {
                        onBuiltInChanged(SharedWorkoutSound.values[index]);
                        onChanged(null);
                      } else {
                        onChanged(library[index - builtInCount]);
                      }
                    },
                  ),
                ),
                IconButton(
                  tooltip: 'Test sound',
                  onPressed: value == null
                      ? () => unawaited(WorkoutAudio.playSharedSound(
                            sound: builtInSound,
                            volume: volume,
                          ))
                      : () => unawaited(WorkoutAudio.playCustomSound(
                            sound: value!,
                            volume: volume,
                          )),
                  icon: const Icon(Icons.play_arrow),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _builtInLabel(SharedWorkoutSound sound) => switch (sound) {
        SharedWorkoutSound.classic => 'Classic',
        SharedWorkoutSound.sharp => 'Sharp',
        SharedWorkoutSound.low => 'Low',
        SharedWorkoutSound.bell => 'Bell',
        SharedWorkoutSound.bright => 'Bright',
        SharedWorkoutSound.soft => 'Soft',
        SharedWorkoutSound.click => 'Click',
        SharedWorkoutSound.pulse => 'Pulse',
        SharedWorkoutSound.wood => 'Wood',
      };
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
