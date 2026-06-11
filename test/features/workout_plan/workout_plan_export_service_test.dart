import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_export_service.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeFilePicker fakeFilePicker;

  setUp(() {
    fakeFilePicker = _FakeFilePicker();
    FilePicker.platform = fakeFilePicker;
  });

  group('WorkoutPlanExportService', () {
    test('exports one plan as formatted JSON', () async {
      const WorkoutPlanExportService service = WorkoutPlanExportService();

      final WorkoutPlanExportResult? result =
          await service.exportPlan(_samplePlan);

      expect(result, isNotNull);
      expect(result!.fileName, 'plan-1-upper-lower.plan.json');
      expect(fakeFilePicker.savedFileName, result.fileName);
      expect(fakeFilePicker.savedBytes, isNotNull);

      final Map<String, dynamic> json = jsonDecode(
        utf8.decode(fakeFilePicker.savedBytes!),
      ) as Map<String, dynamic>;
      expect(json['planId'], 'plan-1');
      expect(json['name'], 'Plan 1: Upper/Lower');
      expect(json['workouts'], hasLength(1));
      expect(json['exercises'], hasLength(1));
    });
  });
}

const WorkoutPlan _samplePlan = WorkoutPlan(
  schemaVersion: 1,
  planId: 'plan-1',
  name: 'Plan 1: Upper/Lower',
  workouts: <Workout>[
    Workout(
      workoutId: 'workout-1',
      title: 'Workout A',
      sets: <WorkoutSet>[
        WorkoutSet(
          setId: 'set-1',
          loopCount: 1,
          restBetweenLoopsSeconds: 30,
          moves: <Move>[
            Move(
              moveId: 'move-1',
              exerciseId: 'exercise-1',
              type: MoveType.reps,
              repCount: 10,
            ),
          ],
        ),
      ],
    ),
  ],
  exercises: <Exercise>[
    Exercise(
      exerciseId: 'exercise-1',
      name: 'Squat',
    ),
  ],
);

class _FakeFilePicker extends FilePicker {
  Uint8List? savedBytes;
  String? savedFileName;

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    savedBytes = bytes;
    savedFileName = fileName;
    return 'C:\\plan.plan.json';
  }
}
