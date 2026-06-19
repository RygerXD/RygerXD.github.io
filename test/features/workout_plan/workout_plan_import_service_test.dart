import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_import_service.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_parser.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';

void main() {
  group('WorkoutPlanImportService', () {
    WorkoutPlanImportService buildService(
        InMemoryWorkoutRepository repository) {
      return WorkoutPlanImportService(
        parser: const WorkoutPlanParser(),
        repository: repository,
      );
    }

    test('validates https URLs', () {
      final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
      final WorkoutPlanImportService service = buildService(repository);

      service
          .validateRemoteImportUri(Uri.parse('https://example.com/plan.json'));
      expect(
        () => service
            .validateRemoteImportUri(Uri.parse('http://example.com/plan.json')),
        throwsA(isA<ImportPolicyException>()),
      );
    });

    test('enforces max payload size', () async {
      final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
      final WorkoutPlanImportService smallLimitService =
          WorkoutPlanImportService(
        parser: const WorkoutPlanParser(),
        repository: repository,
        maxImportBytes: 10,
      );

      await expectLater(
        () => smallLimitService.importFromJsonString('01234567890123456789'),
        throwsA(isA<ImportPolicyException>()),
      );
    });

    test('saves imported plans to the repository', () async {
      final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
      final WorkoutPlanImportService service = buildService(repository);
      final String validPayload = jsonEncode(<String, dynamic>{
        'schemaVersion': 1,
        'planId': 'plan-1',
        'name': 'Plan 1',
        'moves': <Map<String, dynamic>>[
          <String, dynamic>{
            'moveId': 'ex-1',
            'name': 'Squat',
          },
        ],
        'workouts': <Map<String, dynamic>>[
          <String, dynamic>{
            'workoutId': 'w-1',
            'title': 'Workout A',
            'sets': <Map<String, dynamic>>[
              <String, dynamic>{
                'setId': 's-1',
                'lapCount': 1,
                'restBetweenLapsSeconds': 30,
                'moves': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'workoutMoveId': 'm-1',
                    'moveId': 'ex-1',
                    'type': 'reps',
                    'repCount': 10,
                  },
                ],
              },
            ],
          },
        ],
      });

      await service.importFromJsonString(validPayload);

      final plans = await repository.getAllPlans();
      expect(plans, hasLength(1));
      expect(plans.single.planId, 'plan-1');
      expect(plans.single.name, 'Plan 1');
    });
  });
}
