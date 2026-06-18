import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/features/active_workout/application/metronome_audio.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class CustomSoundField extends StatelessWidget {
  const CustomSoundField({
    super.key,
    required this.title,
    required this.value,
    required this.volume,
    required this.onChanged,
    this.inheritedValue,
    this.onTestDefault,
    this.card = true,
  });

  final String title;
  final CustomWorkoutSound? value;
  final CustomWorkoutSound? inheritedValue;
  final double volume;
  final ValueChanged<CustomWorkoutSound?> onChanged;
  final VoidCallback? onTestDefault;
  final bool card;

  CustomWorkoutSound? get _effectiveValue => value ?? inheritedValue;

  Future<void> _pickSound(BuildContext context) async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Choose $title',
      type: FileType.custom,
      allowedExtensions: const <String>['mp3', 'wav'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !context.mounted) {
      return;
    }

    final PlatformFile file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      _showError(context, 'Could not read the selected sound.');
      return;
    }
    if (bytes.length > maxCustomWorkoutSoundBytes) {
      _showError(context, 'Sound files must be 512 KB or smaller.');
      return;
    }

    final String? mimeType = switch ((file.extension ?? '').toLowerCase()) {
      'mp3' => 'audio/mpeg',
      'wav' => 'audio/wav',
      _ => null,
    };
    if (mimeType == null) {
      _showError(context, 'Choose an MP3 or WAV file.');
      return;
    }

    onChanged(CustomWorkoutSound.fromBytes(
      fileName: file.name,
      mimeType: mimeType,
      bytes: bytes,
    ));
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final CustomWorkoutSound? effectiveValue = _effectiveValue;
    final bool inherits = value == null && inheritedValue != null;
    final String subtitle = effectiveValue == null
        ? 'Built-in sound'
        : inherits
            ? 'Plan sound: ${effectiveValue.fileName}'
            : effectiveValue.fileName;
    final Widget tile = ListTile(
      leading: const Icon(Icons.music_note_outlined),
      title: Text(title),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Wrap(
        spacing: 4,
        children: <Widget>[
          IconButton(
            tooltip: 'Test sound',
            onPressed: effectiveValue == null
                ? onTestDefault
                : () => unawaited(WorkoutAudio.playCustomSound(
                      sound: effectiveValue,
                      volume: volume,
                    )),
            icon: const Icon(Icons.play_arrow),
          ),
          IconButton(
            tooltip: value == null ? 'Choose sound' : 'Replace sound',
            onPressed: () => unawaited(_pickSound(context)),
            icon: const Icon(Icons.audio_file_outlined),
          ),
          if (value != null)
            IconButton(
              tooltip: inheritedValue == null
                  ? 'Use built-in sound'
                  : 'Use plan sound',
              onPressed: () => onChanged(null),
              icon: const Icon(Icons.close),
            ),
        ],
      ),
    );
    return card ? Card(child: tile) : tile;
  }
}
