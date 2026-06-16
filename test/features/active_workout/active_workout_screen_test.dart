import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/active_workout/application/active_workout_controller.dart';
import 'package:workout_app_rewrite/features/active_workout/application/rep_history_service.dart';
import 'package:workout_app_rewrite/features/active_workout/presentation/active_workout_screen.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
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
      const Move(
        moveId: 'move-1',
        exerciseId: 'exercise-1',
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
      exerciseId: 'exercise-1',
      reps: 16,
    );
    await repHistoryService.saveWeight(
      workoutId: 'workout-1',
      setId: 'set-1',
      lapIndex: 0,
      exerciseId: 'exercise-1',
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
      const Move(
        moveId: 'move-1',
        exerciseId: 'exercise-1',
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
    expect(find.text('1 / 2 - Lap 1/1'), findsOneWidget);
    expect(find.text('ACTUAL REPS / SIDE'), findsOneWidget);
    expect(find.text('ACTUAL WEIGHT'), findsOneWidget);

    container.read(activeWorkoutControllerProvider.notifier).completeMove();
    await tester.pump();

    expect(find.text('Next: Right Pushups'), findsOneWidget);
    expect(find.text('2 / 2 - Lap 1/1'), findsOneWidget);
  });
}

WorkoutPlan _planWithMove(Move move) {
  return WorkoutPlan(
    schemaVersion: 3,
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
            moves: <Move>[move],
          ),
        ],
      ),
    ],
    exercises: const <Exercise>[
      Exercise(
        exerciseId: 'exercise-1',
        name: 'Pushups',
        imageUrl: 'missing-pushup.gif',
      ),
    ],
  );
}
