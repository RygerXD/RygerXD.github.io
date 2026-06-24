import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/active_workout/application/active_workout_controller.dart';
import 'package:workout_app_rewrite/features/active_workout/application/rep_history_service.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_phase.dart';
import 'package:workout_app_rewrite/features/active_workout/presentation/active_workout_screen.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  test('ending a workout saves the session as completed', () async {
    final HistoryDatabase database = HistoryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        historyDatabaseProvider.overrideWithValue(database),
      ],
    );
    addTearDown(container.dispose);
    final WorkoutPlan plan = _planWithMove(
      const WorkoutMove(
        workoutMoveId: 'move-1',
        moveId: 'move-1',
        type: MoveType.reps,
        repCount: 15,
      ),
    );

    final ActiveWorkoutController controller =
        container.read(activeWorkoutControllerProvider.notifier);
    controller.startWithWorkout(
      plan.workouts.single,
      plan.planId,
      planSnapshot: plan,
    );
    controller.startPrepNow();
    controller.endWorkout();

    await Future<void>.delayed(Duration.zero);
    final List<WorkoutSessionEntity> sessions = await database.getAllSessions();
    expect(sessions, hasLength(1));
    expect(sessions.single.status, 'completed');
    expect(sessions.single.workoutName, plan.workouts.single.title);
  });

  test('canceling a workout discards its recorded data', () async {
    final HistoryDatabase database = HistoryDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        historyDatabaseProvider.overrideWithValue(database),
      ],
    );
    addTearDown(container.dispose);
    final WorkoutPlan plan = _planWithMove(
      const WorkoutMove(
        workoutMoveId: 'move-1',
        moveId: 'move-1',
        type: MoveType.reps,
        repCount: 15,
      ),
    );
    final ActiveWorkoutController controller =
        container.read(activeWorkoutControllerProvider.notifier);
    controller.startWithWorkout(plan.workouts.single, plan.planId);
    final String sessionId = controller.sessionId!;
    await container.read(historyServiceProvider).saveMovePerformance(
          sessionId: sessionId,
          workoutId: 'workout-1',
          setId: 'set-1',
          lapIndex: 0,
          workoutMoveId: 'move-1',
          moveId: 'move-1',
          repCount: 10,
          elapsedSeconds: 5,
          completedAt: DateTime.now(),
        );

    await controller.cancelWorkout();

    expect(await database.getAllSessions(), isEmpty);
    expect(await database.getAllMovePerformances(), isEmpty);
  });

  testWidgets('zero-second prep starts the move automatically',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final WorkoutPlan plan = _planWithMove(
      const WorkoutMove(
        workoutMoveId: 'move-1',
        moveId: 'move-1',
        type: MoveType.reps,
        repCount: 15,
      ),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(activeWorkoutControllerProvider.notifier)
        .startWithWorkout(plan.workouts.single, plan.planId);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ActiveWorkoutScreen()),
      ),
    );
    await tester.pump();

    expect(
      container.read(activeWorkoutControllerProvider).phase,
      WorkoutPhase.move,
    );
  });

  testWidgets('exit dialog offers save or discard choices',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final WorkoutPlan plan = _planWithMove(
      const WorkoutMove(
        workoutMoveId: 'move-1',
        moveId: 'move-1',
        type: MoveType.reps,
        repCount: 15,
      ),
    );
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);
    container
        .read(activeWorkoutControllerProvider.notifier)
        .startWithWorkout(plan.workouts.single, plan.planId);
    container.read(activeWorkoutControllerProvider.notifier).startPrepNow();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ActiveWorkoutScreen()),
      ),
    );
    await tester.pump();
    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('End or Cancel Workout?'), findsOneWidget);
    expect(
      find.text(
        'End workout saves this session to history. '
        'Cancel workout does not save workout history or move data.',
      ),
      findsOneWidget,
    );
    expect(find.text('END WORKOUT AND SAVE'), findsOneWidget);
    expect(find.text('CANCEL WITHOUT SAVING'), findsOneWidget);

    await tester.tap(find.text('KEEP WORKING'));
    await tester.pumpAndSettle();
  });

  testWidgets('rep and weight controls fit in a tight active workout viewport',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    final WorkoutPlan plan = _planWithMove(
      const WorkoutMove(
        workoutMoveId: 'move-1',
        moveId: 'move-1',
        type: MoveType.reps,
        repCount: 15,
        targetWeight: 35,
        targetWeightUnit: WeightUnit.lb,
      ),
    );
    await repository.savePlan(plan);

    final RepHistoryService repHistoryService = RepHistoryService(preferences);
    await repHistoryService.saveReps(
      workoutId: 'workout-1',
      setId: 'set-1',
      lapIndex: 0,
      moveId: 'move-1',
      reps: 16,
    );
    await repHistoryService.saveWeight(
      workoutId: 'workout-1',
      setId: 'set-1',
      lapIndex: 0,
      moveId: 'move-1',
      weightUnit: WeightUnit.lb.name,
      weight: 40,
    );

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        workoutRepositoryProvider.overrideWithValue(repository),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);
    await container.read(loadedWorkoutPlansNotifierProvider.future);
    container
        .read(activeWorkoutControllerProvider.notifier)
        .startWithWorkout(plan.workouts.single, plan.planId);
    container.read(activeWorkoutControllerProvider.notifier).startPrepNow();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ActiveWorkoutScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('ACTUAL REPS'), findsOneWidget);
    expect(find.text('ACTUAL WEIGHT'), findsOneWidget);
    expect(find.text('Last: 16'), findsOneWidget);
    expect(find.text('Last: 40 lb'), findsOneWidget);
    expect(find.text('COMPLETE'), findsOneWidget);
  });

  testWidgets('weighted each-side moves show as left and right executions',
      (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    final SharedPreferences preferences = await SharedPreferences.getInstance();
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    final WorkoutPlan plan = _planWithMove(
      const WorkoutMove(
        workoutMoveId: 'move-1',
        moveId: 'move-1',
        type: MoveType.reps,
        repCount: 15,
        repeatEachSide: true,
        targetWeight: 35,
        targetWeightUnit: WeightUnit.lb,
      ),
    );
    await repository.savePlan(plan);

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        workoutRepositoryProvider.overrideWithValue(repository),
        sharedPreferencesProvider.overrideWithValue(preferences),
      ],
    );
    addTearDown(container.dispose);
    await container.read(loadedWorkoutPlansNotifierProvider.future);
    container
        .read(activeWorkoutControllerProvider.notifier)
        .startWithWorkout(plan.workouts.single, plan.planId);
    container.read(activeWorkoutControllerProvider.notifier).startPrepNow();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: ActiveWorkoutScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Left Pushups'), findsOneWidget);
    expect(find.text('Move 1 of 2'), findsOneWidget);
    expect(find.text('Block 1 - Lap 1 of 1'), findsOneWidget);
    expect(find.text('ACTUAL REPS / SIDE'), findsOneWidget);
    expect(find.text('ACTUAL WEIGHT'), findsOneWidget);

    container.read(activeWorkoutControllerProvider.notifier).completeMove();
    await tester.pump();

    expect(find.text('Next: Right Pushups'), findsOneWidget);
    expect(find.text('Move 2 of 2'), findsOneWidget);
  });
}

WorkoutPlan _planWithMove(WorkoutMove move) {
  return WorkoutPlan(
    schemaVersion: 1,
    planId: 'plan-1',
    name: 'Plan 1',
    workouts: <Workout>[
      Workout(
        workoutId: 'workout-1',
        title: 'Metronome Test',
        sets: <WorkoutSet>[
          WorkoutSet(
            setId: 'set-1',
            lapCount: 1,
            restBetweenLapsSeconds: 0,
            moves: <WorkoutMove>[move],
          ),
        ],
      ),
    ],
    moves: const <Move>[
      Move(
        moveId: 'move-1',
        name: 'Pushups',
        imageUrl: 'missing-pushup.gif',
      ),
    ],
  );
}
