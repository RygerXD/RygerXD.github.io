import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_export_service.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_import_service.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_parser.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';
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
      expect(json['schemaVersion'], 1);
      expect(json['planId'], 'plan-1');
      expect(json['name'], 'Plan 1: Upper/Lower');
      expect(json['workouts'], hasLength(1));
      expect(json['moves'], hasLength(1));
      expect(json.containsKey('description'), isFalse);
      expect(json.containsKey('tags'), isFalse);

      final Map<String, dynamic> workout =
          (json['workouts'] as List<dynamic>).single as Map<String, dynamic>;
      expect(workout.containsKey('imageUrl'), isFalse);
      expect(workout.containsKey('archivedAt'), isFalse);

      final Map<String, dynamic> set =
          (workout['sets'] as List<dynamic>).single as Map<String, dynamic>;
      expect(set.containsKey('lapCount'), isFalse);

      final Map<String, dynamic> move =
          (set['moves'] as List<dynamic>).single as Map<String, dynamic>;
      expect(move.containsKey('durationSeconds'), isFalse);
      expect(move.containsKey('finishTimeSeconds'), isFalse);
      expect(move.containsKey('setCount'), isFalse);
      expect(move.containsKey('repeatEachSide'), isFalse);
    });

    test('exports JSON that can be imported again', () async {
      const WorkoutPlanExportService exportService = WorkoutPlanExportService();
      final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
      final WorkoutPlanImportService importService = WorkoutPlanImportService(
        parser: const WorkoutPlanParser(),
        repository: repository,
      );

      await exportService.exportPlan(_samplePlan);
      final String exportedJson = utf8.decode(fakeFilePicker.savedBytes!);
      await importService.importFromJsonString(exportedJson);

      final List<WorkoutPlan> plans = await repository.getAllPlans();
      expect(plans, hasLength(1));
      expect(plans.single.schemaVersion, 1);
      expect(plans.single.planId, 'plan-1');
      expect(plans.single.workouts, hasLength(1));
      expect(plans.single.workouts.single.workoutId, 'workout-1');
      expect(plans.single.workouts.single.sets.single.lapCount, 1);
      expect(
        plans.single.workouts.single.sets.single.restBetweenLapsSeconds,
        0,
      );
      expect(
          plans.single.workouts.single.sets.single.moves.single.repCount, 10);
    });
  });
}

const WorkoutPlan _samplePlan = WorkoutPlan(
  schemaVersion: workoutPlanSchemaVersion,
  planId: 'plan-1',
  name: 'Plan 1: Upper/Lower',
  workouts: <Workout>[
    Workout(
      workoutId: 'workout-1',
      title: 'Workout A',
      sets: <WorkoutSet>[
        WorkoutSet(
          setId: 'set-1',
          lapCount: 1,
          restBetweenLapsSeconds: 0,
          moves: <WorkoutMove>[
            WorkoutMove(
              workoutMoveId: 'move-1',
              moveId: 'move-1',
              type: MoveType.reps,
              repCount: 10,
            ),
          ],
        ),
      ],
    ),
    Workout(
      workoutId: 'archived-workout',
      title: 'Archived Workout',
      archivedAt: 1,
      sets: <WorkoutSet>[
        WorkoutSet(
          setId: 'archived-set',
          moves: <WorkoutMove>[
            WorkoutMove(
              workoutMoveId: 'archived-move',
              moveId: 'move-1',
              type: MoveType.reps,
              repCount: 10,
            ),
          ],
        ),
      ],
    ),
  ],
  moves: <Move>[
    Move(
      moveId: 'move-1',
      name: 'Squat',
    ),
    Move(
      moveId: 'unused-move',
      name: 'Unused',
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
