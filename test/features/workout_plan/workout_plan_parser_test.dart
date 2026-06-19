import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_parser.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  group('WorkoutPlanParser', () {
    const WorkoutPlanParser parser = WorkoutPlanParser();

    test('parses a valid plan', () {
      final WorkoutPlan parsed = parser.parseFromJson(_planJson(
        move: <String, dynamic>{
          'repCount': 10,
          'setCount': 2,
        },
      ));

      expect(parsed.planId, 'plan-1');
      expect(parsed.imageUrl, 'https://example.com/plan.gif');
      expect(
          parsed.workouts.single.imageUrl, 'https://example.com/workout.gif');
      expect(parsed.workouts.single.sets.single.moves.single.repCount, 10);
      expect(parsed.workouts.single.sets.single.moves.single.setCount, 2);
    });

    test('throws on unsupported schemaVersion', () {
      expect(
        () => parser.parseFromJson(_planJson(schemaVersion: 5)),
        throwsA(isA<WorkoutPlanParseException>()),
      );
    });

    test('formats validation issues in exception text', () {
      try {
        parser.parseFromJson(_planJson(schemaVersion: 5));
        fail('Expected parse exception.');
      } on WorkoutPlanParseException catch (error) {
        expect(
          error.toString(),
          contains(r'$.schemaVersion: Unsupported schemaVersion: 5'),
        );
      }
    });

    test('defaults omitted set timing fields', () {
      final Map<String, dynamic> json = _planJson();
      final Map<String, dynamic> set = (json['workouts'] as List<dynamic>)
          .single['sets']
          .single as Map<String, dynamic>;
      set.remove('lapCount');
      set.remove('restBetweenLapsSeconds');

      final WorkoutSet parsed =
          parser.parseFromJson(json).workouts.single.sets.single;

      expect(parsed.lapCount, 1);
      expect(parsed.restBetweenLapsSeconds, 0);
    });

    test('throws when move references unknown move', () {
      expect(
        () => parser.parseFromJson(_planJson(
          move: <String, dynamic>{'moveId': 'ex-does-not-exist'},
        )),
        throwsA(isA<WorkoutPlanParseException>()),
      );
    });

    test('parses metronome BPM for duration moves', () {
      final WorkoutPlan parsed = parser.parseFromJson(_planJson(
        moveName: 'Jumping Jacks',
        move: <String, dynamic>{
          'type': 'duration',
          'durationSeconds': 30,
          'metronomeSpeed': 60,
        },
      ));

      expect(
          parsed.workouts.single.sets.single.moves.single.metronomeSpeed, 60);
    });

    test('parses each-side duration moves', () {
      final WorkoutMove move = parser
          .parseFromJson(_planJson(
            moveName: 'Lunge',
            move: <String, dynamic>{
              'type': 'duration',
              'durationSeconds': 30,
              'repeatEachSide': true,
            },
          ))
          .workouts
          .single
          .sets
          .single
          .moves
          .single;

      expect(move.durationSeconds, 30);
      expect(move.repeatEachSide, true);
      expect(move.toJson()['repeatEachSide'], true);
    });

    test('parses stopwatch moves', () {
      final WorkoutMove move = parser
          .parseFromJson(_planJson(
            moveName: 'Wall Sit',
            move: <String, dynamic>{'type': 'stopwatch'},
          ))
          .workouts
          .single
          .sets
          .single
          .moves
          .single;

      expect(move.type, MoveType.stopwatch);
      expect(move.durationSeconds, isNull);
    });

    test('throws when metronome BPM is set on a rep move', () {
      expect(
        () => parser.parseFromJson(_planJson(
          move: <String, dynamic>{'metronomeSpeed': 60},
        )),
        throwsA(isA<WorkoutPlanParseException>()),
      );
    });

    test('throws when a move includes fields for another move type', () {
      expect(
        () => parser.parseFromJson(_planJson(
          moveName: 'Jumping Jacks',
          move: <String, dynamic>{
            'type': 'duration',
            'durationSeconds': 30,
            'repCount': 10,
          },
        )),
        throwsA(isA<WorkoutPlanParseException>()),
      );
    });

    test('parses each-side rep moves', () {
      final WorkoutMove move = parser
          .parseFromJson(_planJson(
            move: <String, dynamic>{'repeatEachSide': true},
          ))
          .workouts
          .single
          .sets
          .single
          .moves
          .single;

      expect(move.type, MoveType.reps);
      expect(move.repCount, 10);
      expect(move.repeatEachSide, true);
    });

    test('parses each-side stopwatch moves', () {
      final WorkoutMove move = parser
          .parseFromJson(_planJson(
            moveName: 'Wall Sit',
            move: <String, dynamic>{
              'type': 'stopwatch',
              'repeatEachSide': true,
            },
          ))
          .workouts
          .single
          .sets
          .single
          .moves
          .single;

      expect(move.type, MoveType.stopwatch);
      expect(move.durationSeconds, isNull);
      expect(move.repeatEachSide, true);
    });

    test('throws when move setCount is less than one', () {
      expect(
        () => parser.parseFromJson(_planJson(
          move: <String, dynamic>{'setCount': 0},
        )),
        throwsA(isA<WorkoutPlanParseException>()),
      );
    });
  });
}

Map<String, dynamic> _planJson({
  int schemaVersion = 1,
  String moveId = 'ex-1',
  String moveName = 'Squat',
  Map<String, dynamic> move = const <String, dynamic>{},
}) {
  final Map<String, dynamic> moveJson = <String, dynamic>{
    'workoutMoveId': 'm-1',
    'moveId': moveId,
    'type': 'reps',
    'repCount': 10,
    ...move,
  };
  if (moveJson['type'] != 'reps' && !move.containsKey('repCount')) {
    moveJson.remove('repCount');
  }

  return <String, dynamic>{
    'schemaVersion': schemaVersion,
    'planId': 'plan-1',
    'name': 'Plan 1',
    'imageUrl': 'https://example.com/plan.gif',
    'moves': <Map<String, dynamic>>[
      <String, dynamic>{
        'moveId': moveId,
        'name': moveName,
      },
    ],
    'workouts': <Map<String, dynamic>>[
      <String, dynamic>{
        'workoutId': 'w-1',
        'title': 'Workout A',
        'imageUrl': 'https://example.com/workout.gif',
        'sets': <Map<String, dynamic>>[
          <String, dynamic>{
            'setId': 's-1',
            'lapCount': 1,
            'restBetweenLapsSeconds': 30,
            'moves': <Map<String, dynamic>>[moveJson],
          },
        ],
      },
    ],
  };
}
