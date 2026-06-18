import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/history/domain/history_workout_snapshot.dart';
import 'package:workout_app_rewrite/features/history/presentation/workout_progress_screen.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  testWidgets('keeps removed moves visible in the same workout history',
      (WidgetTester tester) async {
    final HistoryDatabase database = HistoryDatabase(NativeDatabase.memory());
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    addTearDown(database.close);

    const WorkoutMove squat = WorkoutMove(
      workoutMoveId: 'squat-entry',
      moveId: 'squat',
      type: MoveType.reps,
      repCount: 10,
    );
    const WorkoutMove pushUp = WorkoutMove(
      workoutMoveId: 'push-up-entry',
      moveId: 'push-up',
      type: MoveType.reps,
      repCount: 10,
    );
    const WorkoutPlan oldPlan = WorkoutPlan(
      schemaVersion: 4,
      planId: 'plan-1',
      name: 'Plan',
      workouts: <Workout>[
        Workout(
          workoutId: 'workout-1',
          title: 'Strength',
          sets: <WorkoutSet>[
            WorkoutSet(
              setId: 'set-1',
              lapCount: 1,
              restBetweenLapsSeconds: 0,
              moves: <WorkoutMove>[squat, pushUp],
            ),
          ],
        ),
      ],
      moves: <Move>[
        Move(moveId: 'squat', name: 'Squat'),
        Move(moveId: 'push-up', name: 'Push Up'),
      ],
    );
    const WorkoutPlan currentPlan = WorkoutPlan(
      schemaVersion: 4,
      planId: 'plan-1',
      name: 'Plan',
      workouts: <Workout>[
        Workout(
          workoutId: 'workout-1',
          title: 'Strength',
          imageUrl: 'https://example.com/new-image.png',
          sets: <WorkoutSet>[
            WorkoutSet(
              setId: 'set-1',
              lapCount: 1,
              restBetweenLapsSeconds: 0,
              moves: <WorkoutMove>[squat],
            ),
          ],
        ),
      ],
      moves: <Move>[
        Move(moveId: 'squat', name: 'Squat'),
        Move(moveId: 'push-up', name: 'Push Up'),
      ],
    );
    await repository.savePlan(currentPlan);

    await database.insertSession(
      WorkoutSessionEntity(
        sessionId: 'session-1',
        planId: 'plan-1',
        workoutId: 'workout-1',
        workoutName: 'Strength',
        workoutSnapshotJson: encodeHistoryWorkoutSnapshot(oldPlan, 'workout-1'),
        startedAt: 1000,
        endedAt: 2000,
        durationSeconds: 1,
        status: 'completed',
      ),
    );
    await database.insertSession(
      WorkoutSessionEntity(
        sessionId: 'session-2',
        planId: 'plan-1',
        workoutId: 'workout-1',
        workoutName: 'Strength',
        workoutSnapshotJson:
            encodeHistoryWorkoutSnapshot(currentPlan, 'workout-1'),
        startedAt: 3000,
        endedAt: 4000,
        durationSeconds: 1,
        status: 'completed',
      ),
    );
    for (final ({String id, String sessionId, WorkoutMove move, int reps}) row
        in <({String id, String sessionId, WorkoutMove move, int reps})>[
      (id: 'p1', sessionId: 'session-1', move: squat, reps: 10),
      (id: 'p2', sessionId: 'session-1', move: pushUp, reps: 8),
      (id: 'p3', sessionId: 'session-2', move: squat, reps: 12),
    ]) {
      await database.insertMovePerformance(
        WorkoutMovePerformanceEntity(
          performanceId: row.id,
          sessionId: row.sessionId,
          workoutId: 'workout-1',
          setId: 'set-1',
          lapIndex: 0,
          workoutMoveId: row.move.workoutMoveId,
          moveId: row.move.moveId,
          repCount: row.reps,
          elapsedSeconds: 30,
          completedAt: 4000,
        ),
      );
    }

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        historyDatabaseProvider.overrideWithValue(database),
        workoutRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(loadedWorkoutPlansNotifierProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: WorkoutProgressScreen(sessionId: 'session-2'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('2 tracked sessions'), findsOneWidget);
    expect(find.textContaining('Squat - Set 1, Lap 1'), findsOneWidget);
    expect(find.textContaining('Push Up - Set 1, Lap 1'), findsOneWidget);
  });
}
