import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_parser.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  group('WorkoutPlanParser', () {
    const WorkoutPlanParser parser = WorkoutPlanParser();

    test('parses a valid plan', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'schemaVersion': 1,
        'planId': 'plan-1',
        'name': 'Plan 1',
        'exercises': <Map<String, dynamic>>[
          <String, dynamic>{
            'exerciseId': 'ex-1',
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
                'loopCount': 1,
                'restBetweenLoopsSeconds': 30,
                'moves': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'moveId': 'm-1',
                    'exerciseId': 'ex-1',
                    'type': 'reps',
                    'repCount': 10,
                  },
                ],
              },
            ],
          },
        ],
      };

      final WorkoutPlan parsed = parser.parseFromJson(json);
      expect(parsed.planId, 'plan-1');
      expect(parsed.workouts.single.sets.single.moves.single.repCount, 10);
    });

    test('throws on unsupported schemaVersion', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'schemaVersion': 3,
        'planId': 'plan-1',
        'name': 'Plan 1',
        'exercises': <dynamic>[],
        'workouts': <dynamic>[],
      };

      expect(
        () => parser.parseFromJson(json),
        throwsA(isA<WorkoutPlanParseException>()),
      );
    });

    test('throws when move references unknown exercise', () {
      final Map<String, dynamic> json = <String, dynamic>{
        'schemaVersion': 1,
        'planId': 'plan-1',
        'name': 'Plan 1',
        'exercises': <Map<String, dynamic>>[
          <String, dynamic>{
            'exerciseId': 'ex-1',
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
                'loopCount': 1,
                'restBetweenLoopsSeconds': 30,
                'moves': <Map<String, dynamic>>[
                  <String, dynamic>{
                    'moveId': 'm-1',
                    'exerciseId': 'ex-does-not-exist',
                    'type': 'reps',
                    'repCount': 10,
                  },
                ],
              },
            ],
          },
        ],
      };

      expect(
        () => parser.parseFromJson(json),
        throwsA(isA<WorkoutPlanParseException>()),
      );
    });
  });
}
