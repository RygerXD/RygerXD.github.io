import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_runtime_expansion.dart';

typedef PreviousMoveSeconds = int? Function({
  required String setId,
  required int lapIndex,
  required String workoutMoveId,
});

int estimateWorkoutSeconds(
  Workout workout, {
  PreviousMoveSeconds? previousMoveSeconds,
}) {
  return workout.sets.fold<int>(0, (int total, WorkoutSet set) {
    return total +
        estimateSetSeconds(
          set,
          previousMoveSeconds: previousMoveSeconds,
        );
  });
}

int estimateSetSeconds(
  WorkoutSet set, {
  PreviousMoveSeconds? previousMoveSeconds,
}) {
  int total = 0;
  for (int lap = 0; lap < set.lapCount; lap += 1) {
    for (final WorkoutMove move in set.moves) {
      for (final WorkoutMove expandedMove in expandWorkoutMove(move)) {
        total += estimateMoveSeconds(
          expandedMove,
          previousActiveSeconds: expandedMove.type == MoveType.reps
              ? previousMoveSeconds?.call(
                  setId: set.setId,
                  lapIndex: lap,
                  workoutMoveId: expandedMove.workoutMoveId,
                )
              : null,
        );
      }
    }
    if (lap < set.lapCount - 1) {
      total += set.restBetweenLapsSeconds;
    }
  }
  return total;
}

int estimateMoveSeconds(
  WorkoutMove move, {
  int? previousActiveSeconds,
}) {
  final int activeSeconds = switch (move.type) {
    MoveType.duration => move.durationSeconds ?? 0,
    MoveType.reps => previousActiveSeconds ?? 0,
    MoveType.stopwatch => 0,
  };
  return (move.prepTimeSeconds + activeSeconds + move.finishTimeSeconds) *
      effectiveMoveSetCount(move) *
      effectiveMoveSideCount(move);
}

int effectiveMoveDurationSeconds(WorkoutMove move) {
  final int durationSeconds = move.durationSeconds ?? 0;
  if (move.type != MoveType.duration) {
    return 0;
  }
  return move.repeatEachSide ? durationSeconds * 2 : durationSeconds;
}

int effectiveMoveSideCount(WorkoutMove move) {
  return move.repeatEachSide ? 2 : 1;
}

int countWorkoutMoves(Workout workout) {
  return workout.sets.fold<int>(
    0,
    (int total, WorkoutSet set) =>
        total +
        (set.moves.fold<int>(
              0,
              (int moveTotal, WorkoutMove move) =>
                  moveTotal +
                  (effectiveMoveSetCount(move) * effectiveMoveSideCount(move)),
            ) *
            set.lapCount),
  );
}

String formatWorkoutEstimate(int seconds) {
  if (seconds <= 0) {
    return '0sec';
  }

  final Duration duration = Duration(seconds: seconds);
  final int hours = duration.inHours;
  final int minutes = duration.inMinutes.remainder(60);
  final int remainingSeconds = duration.inSeconds.remainder(60);

  if (hours > 0) {
    if (minutes == 0) {
      return '${hours}hrs';
    }
    return '${hours}hrs ${minutes}mins';
  }
  if (minutes == 0) {
    return '${remainingSeconds}sec';
  }
  if (remainingSeconds == 0) {
    return '${minutes}mins';
  }
  return '${minutes}mins ${remainingSeconds}sec';
}

String formatClockDuration(int seconds) {
  final Duration duration = Duration(seconds: seconds);
  final String hours = duration.inHours.toString().padLeft(2, '0');
  final String minutes =
      duration.inMinutes.remainder(60).toString().padLeft(2, '0');
  final String remainingSeconds =
      duration.inSeconds.remainder(60).toString().padLeft(2, '0');
  return '$hours:$minutes:$remainingSeconds';
}

String formatMoveTarget(WorkoutMove move) {
  final String baseTarget = switch (move.type) {
    MoveType.reps => '${move.repCount ?? 0} reps',
    MoveType.duration => formatShortClockDuration(move.durationSeconds ?? 0),
    MoveType.stopwatch => 'Max time',
  };
  final String target =
      _withTargetWeight(_withEachSide(baseTarget, move), move);
  final int setCount = effectiveMoveSetCount(move);
  return setCount > 1 ? '$setCount sets x $target' : target;
}

String? formatMoveTargetWeight(WorkoutMove move) {
  final double? weight = move.targetWeight;
  final WeightUnit? unit = move.targetWeightUnit;
  if (weight == null || unit == null) {
    return null;
  }
  return '${formatWeight(weight)}${_formatWeightUnit(unit)}';
}

String _withTargetWeight(String label, WorkoutMove move) {
  final String? targetWeight = formatMoveTargetWeight(move);
  if (targetWeight == null) {
    return label;
  }
  return '$label, $targetWeight';
}

String _withEachSide(String label, WorkoutMove move) {
  return move.repeatEachSide ? '$label / side' : label;
}

String _formatWeightUnit(WeightUnit unit) {
  return switch (unit) {
    WeightUnit.lb => 'lbs',
    WeightUnit.kg => 'kg',
  };
}

String formatShortClockDuration(int seconds) {
  final Duration duration = Duration(seconds: seconds);
  final int minutes = duration.inMinutes;
  final int remainingSeconds = duration.inSeconds.remainder(60);
  if (minutes == 0) {
    return '00:${remainingSeconds.toString().padLeft(2, '0')}';
  }
  return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
}
