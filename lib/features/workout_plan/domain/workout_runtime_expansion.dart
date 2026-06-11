import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

int effectiveMoveSetCount(Move move) {
  return move.setCount < 1 ? 1 : move.setCount;
}

Workout expandRepeatedMoveSets(Workout workout) {
  return workout.copyWith(
    sets: workout.sets
        .map((WorkoutSet set) => set.copyWith(
              moves: set.moves
                  .expand((Move move) => _expandedMoveSets(move))
                  .toList(growable: false),
            ))
        .toList(growable: false),
  );
}

Iterable<Move> _expandedMoveSets(Move move) sync* {
  final int setCount = effectiveMoveSetCount(move);
  yield move.copyWith(setCount: 1);
  for (int setNumber = 2; setNumber <= setCount; setNumber += 1) {
    yield move.copyWith(
      moveId: '${move.moveId}:set-$setNumber',
      setCount: 1,
    );
  }
}
