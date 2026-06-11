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
      expect(estimateMoveSeconds(move), 75);
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
            loopCount: 2,
            restBetweenLoopsSeconds: 30,
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
