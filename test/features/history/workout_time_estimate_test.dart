import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/history/domain/workout_time_estimate.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  test('uses the latest completion time for every repeated rep set', () {
    const Workout workout = Workout(
      workoutId: 'workout-1',
      title: 'Workout',
      sets: <WorkoutSet>[
        WorkoutSet(
          setId: 'set-1',
          lapCount: 1,
          restBetweenLapsSeconds: 0,
          moves: <WorkoutMove>[
            WorkoutMove(
              workoutMoveId: 'move-1',
              moveId: 'exercise-1',
              type: MoveType.reps,
              repCount: 10,
              prepTimeSeconds: 5,
              finishTimeSeconds: 5,
              setCount: 2,
            ),
          ],
        ),
      ],
    );
    const List<WorkoutMovePerformanceEntity> performances =
        <WorkoutMovePerformanceEntity>[
      WorkoutMovePerformanceEntity(
        performanceId: 'old',
        sessionId: 'session-1',
        workoutId: 'workout-1',
        setId: 'set-1',
        lapIndex: 0,
        workoutMoveId: 'move-1',
        moveId: 'exercise-1',
        repCount: 10,
        elapsedSeconds: 20,
        completedAt: 100,
      ),
      WorkoutMovePerformanceEntity(
        performanceId: 'new',
        sessionId: 'session-2',
        workoutId: 'workout-1',
        setId: 'set-1',
        lapIndex: 0,
        workoutMoveId: 'move-1',
        moveId: 'exercise-1',
        repCount: 10,
        elapsedSeconds: 30,
        completedAt: 200,
      ),
      WorkoutMovePerformanceEntity(
        performanceId: 'second-set',
        sessionId: 'session-2',
        workoutId: 'workout-1',
        setId: 'set-1',
        lapIndex: 0,
        workoutMoveId: 'move-1:set-2',
        moveId: 'exercise-1',
        repCount: 10,
        elapsedSeconds: 40,
        completedAt: 201,
      ),
    ];

    expect(estimateWorkoutSecondsFromHistory(workout, performances), 90);
  });
}
