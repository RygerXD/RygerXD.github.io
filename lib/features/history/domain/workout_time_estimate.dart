import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_metrics.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

int estimateWorkoutSecondsFromHistory(
  Workout workout,
  Iterable<WorkoutMovePerformanceEntity> performances,
) {
  final Map<String, WorkoutMovePerformanceEntity> latestByMove =
      <String, WorkoutMovePerformanceEntity>{};

  for (final WorkoutMovePerformanceEntity performance in performances) {
    if (performance.workoutId != workout.workoutId) {
      continue;
    }
    final String key = _performanceKey(
      setId: performance.setId,
      lapIndex: performance.lapIndex,
      workoutMoveId: performance.workoutMoveId,
    );
    final WorkoutMovePerformanceEntity? latest = latestByMove[key];
    if (latest == null || performance.completedAt > latest.completedAt) {
      latestByMove[key] = performance;
    }
  }

  return estimateWorkoutSeconds(
    workout,
    previousMoveSeconds: ({
      required String setId,
      required int lapIndex,
      required String workoutMoveId,
    }) {
      return latestByMove[_performanceKey(
        setId: setId,
        lapIndex: lapIndex,
        workoutMoveId: workoutMoveId,
      )]
          ?.elapsedSeconds;
    },
  );
}

String _performanceKey({
  required String setId,
  required int lapIndex,
  required String workoutMoveId,
}) {
  return '$setId|$lapIndex|$workoutMoveId';
}
