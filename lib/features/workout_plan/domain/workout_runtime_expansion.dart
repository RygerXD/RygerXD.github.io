import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

int effectiveMoveSetCount(WorkoutMove move) {
  return move.setCount < 1 ? 1 : move.setCount;
}

Workout expandRepeatedMoveSets(Workout workout) {
  return workout.copyWith(
    sets: workout.sets
        .map((WorkoutSet set) => set.copyWith(
              moves:
                  set.moves.expand(expandWorkoutMove).toList(growable: false),
            ))
        .toList(growable: false),
  );
}

Iterable<WorkoutMove> expandWorkoutMove(WorkoutMove move) sync* {
  final int setCount = effectiveMoveSetCount(move);
  yield* _expandedMoveSides(move.copyWith(setCount: 1));
  for (int setNumber = 2; setNumber <= setCount; setNumber += 1) {
    yield* _expandedMoveSides(
      move.copyWith(
        workoutMoveId: '${move.workoutMoveId}:set-$setNumber',
        setCount: 1,
      ),
    );
  }
}

Iterable<WorkoutMove> _expandedMoveSides(WorkoutMove move) sync* {
  if (!move.repeatEachSide) {
    yield move;
    return;
  }

  for (final MoveSide side in MoveSide.values) {
    yield move.copyWith(
      workoutMoveId: '${move.workoutMoveId}:${side.name}',
      repeatEachSide: false,
      side: side,
    );
  }
}
