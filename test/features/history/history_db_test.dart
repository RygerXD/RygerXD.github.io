import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';

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
        loopIndex: 0,
        moveId: 'move-1',
        exerciseId: 'exercise-1',
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
        loopIndex: 0,
        moveId: 'move-1',
        exerciseId: 'exercise-1',
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
}
