import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

Future<CustomWorkoutSound?> pickCustomWorkoutSound(
  BuildContext context, {
  String title = 'sound',
}) async {
  final FilePickerResult? result = await FilePicker.platform.pickFiles(
    dialogTitle: 'Choose $title',
    type: FileType.custom,
    allowedExtensions: const <String>['mp3', 'ogg', 'wav'],
    withData: true,
  );
  if (result == null || result.files.isEmpty || !context.mounted) return null;
  final PlatformFile file = result.files.single;
  final bytes = file.bytes;
  if (bytes == null || bytes.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not read the selected sound.')),
    );
    return null;
  }
  if (bytes.length > maxCustomWorkoutSoundBytes) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sound files must be 512 KB or smaller.')),
    );
    return null;
  }
  final String? mimeType = switch ((file.extension ?? '').toLowerCase()) {
    'mp3' => 'audio/mpeg',
    'ogg' => 'audio/ogg',
    'wav' => 'audio/wav',
    _ => null,
  };
  if (mimeType == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Choose an MP3, OGG, or WAV file.')),
    );
    return null;
  }
  return CustomWorkoutSound.fromBytes(
    fileName: file.name,
    mimeType: mimeType,
    bytes: bytes,
  );
}
