import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/history/domain/history_workout_snapshot.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  test('deleteWorkoutSession removes only the selected session data', () async {
    final HistoryDatabase db = HistoryDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await db.insertSession(
      const WorkoutSessionEntity(
        sessionId: 'session-1',
        planId: 'plan-1',
        workoutId: 'workout-1',
        startedAt: 1000,
        endedAt: 2000,
        durationSeconds: 1,
        status: 'completed',
      ),
    );
    await db.insertSession(
      const WorkoutSessionEntity(
        sessionId: 'session-2',
        planId: 'plan-1',
        workoutId: 'workout-1',
        startedAt: 3000,
        endedAt: 4000,
        durationSeconds: 1,
        status: 'completed',
      ),
    );
    await db.insertMovePerformance(
      const WorkoutMovePerformanceEntity(
        performanceId: 'performance-1',
        sessionId: 'session-1',
        workoutId: 'workout-1',
        setId: 'set-1',
        lapIndex: 0,
        workoutMoveId: 'workout-move-1',
        moveId: 'move-1',
        repCount: 10,
        elapsedSeconds: 30,
        completedAt: 2000,
      ),
    );
    await db.insertMovePerformance(
      const WorkoutMovePerformanceEntity(
        performanceId: 'performance-2',
        sessionId: 'session-2',
        workoutId: 'workout-1',
        setId: 'set-1',
        lapIndex: 0,
        workoutMoveId: 'workout-move-1',
        moveId: 'move-1',
        repCount: 12,
        elapsedSeconds: 35,
        completedAt: 4000,
      ),
    );

    await db.deleteWorkoutSession('session-1');

    final List<WorkoutSessionEntity> sessions = await db.getAllSessions();
    final List<WorkoutMovePerformanceEntity> movePerformances =
        await db.getAllMovePerformances();

    expect(
      sessions.map((WorkoutSessionEntity session) => session.sessionId),
      <String>['session-2'],
    );
    expect(
      movePerformances.map(
        (WorkoutMovePerformanceEntity performance) => performance.performanceId,
      ),
      <String>['performance-2'],
    );
  });

  test('saveSession stores workout metadata snapshot for analysis', () async {
    final HistoryDatabase db = HistoryDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    const WorkoutPlan plan = WorkoutPlan(
      schemaVersion: 4,
      planId: 'plan-1',
      name: 'Plan 1',
      workouts: <Workout>[
        Workout(
          workoutId: 'workout-1',
          title: 'Workout A',
          sets: <WorkoutSet>[
            WorkoutSet(
              setId: 'set-1',
              lapCount: 1,
              restBetweenLapsSeconds: 0,
              moves: <WorkoutMove>[
                WorkoutMove(
                  workoutMoveId: 'move-1',
                  moveId: 'move-1',
                  type: MoveType.reps,
                  repCount: 10,
                ),
              ],
            ),
          ],
        ),
      ],
      moves: <Move>[
        Move(moveId: 'move-1', name: 'Squat'),
      ],
    );

    await HistoryService(db).saveSession(
      sessionId: 'session-1',
      planId: 'plan-1',
      workoutId: 'workout-1',
      workoutName: 'Workout A',
      workoutPlanSnapshot: plan,
      startedAt: DateTime.fromMillisecondsSinceEpoch(1000),
      endedAt: DateTime.fromMillisecondsSinceEpoch(2000),
      status: 'completed',
    );

    final WorkoutSessionEntity session = (await db.getAllSessions()).single;
    final HistoryWorkoutSnapshot? snapshot =
        decodeHistoryWorkoutSnapshot(session.workoutSnapshotJson);

    expect(session.planName, 'Plan 1');
    expect(session.workoutName, 'Workout A');
    expect(snapshot?.workout.title, 'Workout A');
    expect(snapshot?.moves.single.name, 'Squat');
  });
}
