import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

int estimateWorkoutSeconds(Workout workout) {
  return workout.sets.fold<int>(
    0,
    (int total, WorkoutSet set) => total + estimateSetSeconds(set),
  );
}

int estimateSetSeconds(WorkoutSet set) {
  int total = 0;
  for (int loop = 0; loop < set.loopCount; loop += 1) {
    for (final Move move in set.moves) {
      total += estimateMoveSeconds(move);
    }
    if (loop < set.loopCount - 1) {
      total += set.restBetweenLoopsSeconds;
    }
  }
  return total;
}

int estimateMoveSeconds(Move move) {
  final int activeSeconds = switch (move.type) {
    MoveType.duration => move.durationSeconds ?? 0,
    MoveType.reps || MoveType.stopwatch => 0,
  };
  return move.prepTimeSeconds + activeSeconds + move.finishTimeSeconds;
}

int countWorkoutMoves(Workout workout) {
  return workout.sets.fold<int>(
    0,
    (int total, WorkoutSet set) => total + (set.moves.length * set.loopCount),
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

String formatMoveTarget(Move move) {
  return switch (move.type) {
    MoveType.reps => '${move.repCount ?? 0} reps',
    MoveType.duration => formatShortClockDuration(move.durationSeconds ?? 0),
    MoveType.stopwatch => 'Max time',
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
