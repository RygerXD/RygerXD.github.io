import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_metrics.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  group('workout metrics', () {
    test('counts duration moves repeated for each side as double active time',
        () {
      const Move move = Move(
        moveId: 'm-1',
        exerciseId: 'ex-1',
        type: MoveType.duration,
        durationSeconds: 30,
        prepTimeSeconds: 5,
        finishTimeSeconds: 10,
        repeatEachSide: true,
      );

      expect(effectiveMoveDurationSeconds(move), 60);
      expect(estimateMoveSeconds(move), 90);
    });

    test('formats each-side duration targets', () {
      const Move move = Move(
        moveId: 'm-1',
        exerciseId: 'ex-1',
        type: MoveType.duration,
        durationSeconds: 30,
        repeatEachSide: true,
      );

      expect(formatMoveTarget(move), '00:30 / side');
    });

    test('formats each-side rep and stopwatch targets', () {
      const Move repMove = Move(
        moveId: 'm-1',
        exerciseId: 'ex-1',
        type: MoveType.reps,
        repCount: 10,
        repeatEachSide: true,
      );
      const Move stopwatchMove = Move(
        moveId: 'm-2',
        exerciseId: 'ex-2',
        type: MoveType.stopwatch,
        repeatEachSide: true,
      );

      expect(formatMoveTarget(repMove), '10 reps / side');
      expect(formatMoveTarget(stopwatchMove), 'Max time / side');
    });

    test('counts each-side moves as two workout move executions', () {
      const Workout workout = Workout(
        workoutId: 'w-1',
        title: 'Workout',
        sets: <WorkoutSet>[
          WorkoutSet(
            setId: 's-1',
            lapCount: 1,
            restBetweenLapsSeconds: 0,
            moves: <Move>[
              Move(
                moveId: 'm-1',
                exerciseId: 'ex-1',
                type: MoveType.reps,
                repCount: 10,
                repeatEachSide: true,
              ),
            ],
          ),
        ],
      );

      expect(countWorkoutMoves(workout), 2);
    });

    test('formats tracked target weight with move targets', () {
      const Move move = Move(
        moveId: 'm-1',
        exerciseId: 'ex-1',
        type: MoveType.reps,
        repCount: 10,
        targetWeight: 70,
        targetWeightUnit: WeightUnit.lb,
      );

      expect(formatMoveTarget(move), '10 reps, 70lbs');
      expect(formatMoveTargetWeight(move), '70lbs');
    });

    test('counts move setCount in estimates and target labels', () {
      const Move move = Move(
        moveId: 'm-1',
        exerciseId: 'ex-1',
        type: MoveType.reps,
        repCount: 10,
        prepTimeSeconds: 5,
        finishTimeSeconds: 15,
        setCount: 3,
      );

      const Workout workout = Workout(
        workoutId: 'w-1',
        title: 'Workout',
        sets: <WorkoutSet>[
          WorkoutSet(
            setId: 's-1',
            lapCount: 2,
            restBetweenLapsSeconds: 30,
            moves: <Move>[move],
          ),
        ],
      );

      expect(estimateMoveSeconds(move), 60);
      expect(countWorkoutMoves(workout), 6);
      expect(formatMoveTarget(move), '3 sets x 10 reps');
    });
  });
}
