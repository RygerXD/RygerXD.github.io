import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/core/audio/custom_sound_field.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  testWidgets('imports an MP3 as a portable custom sound',
      (WidgetTester tester) async {
    final _FakeFilePicker picker = _FakeFilePicker()
      ..pickResult = FilePickerResult(<PlatformFile>[
        PlatformFile(
          name: 'celebrate.mp3',
          size: 3,
          bytes: Uint8List.fromList(<int>[1, 2, 3]),
        ),
      ]);
    FilePicker.platform = picker;
    CustomWorkoutSound? selected;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: CustomSoundField(
          title: 'Workout complete',
          value: null,
          volume: 0.8,
          onChanged: (CustomWorkoutSound? sound) => selected = sound,
        ),
      ),
    ));

    await tester.tap(find.byTooltip('Choose sound'));
    await tester.pump();

    expect(selected?.fileName, 'celebrate.mp3');
    expect(selected?.mimeType, 'audio/mpeg');
    expect(selected?.bytes, <int>[1, 2, 3]);
  });
}

class _FakeFilePicker extends FilePicker {
  FilePickerResult? pickResult;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    void Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async =>
      pickResult;
}
