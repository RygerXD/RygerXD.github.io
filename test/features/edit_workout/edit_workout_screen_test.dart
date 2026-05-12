import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/edit_workout/presentation/edit_workout_screen.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  testWidgets('shows a newly added exercise name immediately',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 1,
        planId: 'plan-1',
        name: 'Plan 1',
        workouts: <Workout>[],
        exercises: <Exercise>[],
      ),
    );

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        workoutRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(loadedWorkoutPlansNotifierProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: EditWorkoutScreen(planId: 'plan-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Move'));
    await tester.pumpAndSettle();

    final Finder exerciseNameField = find
        .descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        )
        .first;
    await tester.enterText(exerciseNameField, 'Push Up');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(ListTile),
        matching: find.text('Push Up'),
      ),
      findsOneWidget,
    );
    expect(find.text('Unknown Exercise'), findsNothing);
  });

  testWidgets('adds BPM to duration moves', (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 1,
        planId: 'plan-1',
        name: 'Plan 1',
        workouts: <Workout>[],
        exercises: <Exercise>[],
      ),
    );

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        workoutRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(loadedWorkoutPlansNotifierProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: EditWorkoutScreen(planId: 'plan-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Move'));
    await tester.pumpAndSettle();

    final Finder exerciseNameField = find
        .descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        )
        .first;
    await tester.enterText(exerciseNameField, 'Jumping Jacks');
    await tester.tap(find.text('Duration'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Metronome'));
    await tester.pumpAndSettle();

    final Finder bpmField = find
        .descendant(
          of: find.byType(AlertDialog),
          matching: find.byType(TextField),
        )
        .last;
    await tester.enterText(bpmField, '72');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Jumping Jacks'), findsOneWidget);
    expect(find.text('30 seconds - 72 BPM'), findsOneWidget);
  });

  testWidgets('saves image or GIF URL for new moves',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 1,
        planId: 'plan-1',
        name: 'Plan 1',
        workouts: <Workout>[],
        exercises: <Exercise>[],
      ),
    );

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        workoutRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(loadedWorkoutPlansNotifierProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: EditWorkoutScreen(planId: 'plan-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('New Move'));
    await tester.pumpAndSettle();

    final Finder dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.at(0), 'Plank');
    await tester.enterText(
      dialogFields.at(1),
      'https://example.com/plank.gif',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    final WorkoutPlan? updatedPlan = await repository.getPlanById('plan-1');
    expect(updatedPlan?.exercises.single.imageUrl,
        'https://example.com/plank.gif');
  });

  testWidgets('edits added moves', (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 1,
        planId: 'plan-1',
        name: 'Plan 1',
        workouts: <Workout>[],
        exercises: <Exercise>[],
      ),
    );

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        workoutRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(loadedWorkoutPlansNotifierProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: EditWorkoutScreen(planId: 'plan-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Workout A');
    await tester.tap(find.text('New Move'));
    await tester.pumpAndSettle();

    Finder dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.at(0), 'Push Up');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.edit_outlined));
    await tester.pumpAndSettle();

    dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.at(0), 'Incline Push Up');
    await tester.enterText(dialogFields.last, '15');
    await tester.tap(find.widgetWithText(FilledButton, 'Save'));
    await tester.pumpAndSettle();

    expect(find.text('Incline Push Up'), findsOneWidget);
    expect(find.text('15 reps'), findsOneWidget);

    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    final WorkoutPlan? updatedPlan = await repository.getPlanById('plan-1');
    expect(updatedPlan?.exercises.single.name, 'Incline Push Up');
    expect(updatedPlan?.workouts.single.sets.single.moves.single.repCount, 15);
  });

  testWidgets('existing picker searches exercises and resets move settings',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 1,
        planId: 'plan-1',
        name: 'Plan 1',
        workouts: <Workout>[
          Workout(
            workoutId: 'source-workout',
            title: 'Source',
            sets: <WorkoutSet>[
              WorkoutSet(
                setId: 'source-set',
                loopCount: 1,
                restBetweenLoopsSeconds: 30,
                moves: <Move>[
                  Move(
                    moveId: 'source-move',
                    exerciseId: 'burpee',
                    type: MoveType.reps,
                    repCount: 99,
                    prepTimeSeconds: 12,
                  ),
                ],
              ),
            ],
          ),
        ],
        exercises: <Exercise>[
          Exercise(
            exerciseId: 'burpee',
            name: 'Burpee',
            imageUrl: 'https://example.com/burpee.gif',
          ),
        ],
      ),
    );

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        workoutRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(loadedWorkoutPlansNotifierProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: EditWorkoutScreen(planId: 'plan-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Workout A');
    await tester.tap(find.text('Existing'));
    await tester.pumpAndSettle();

    expect(find.text('Search exercises'), findsOneWidget);
    await tester.enterText(
        find.widgetWithText(TextField, 'Search exercises'), 'brp');
    await tester.pumpAndSettle();

    await tester.tap(find.text('Burpee'));
    await tester.pumpAndSettle();

    final Finder dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    expect(
      tester.widget<TextField>(dialogFields.at(0)).controller?.text,
      'Burpee',
    );
    expect(
      tester.widget<TextField>(dialogFields.at(1)).controller?.text,
      'https://example.com/burpee.gif',
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(find.text('Burpee'), findsOneWidget);
    expect(find.text('10 reps'), findsOneWidget);
    expect(find.text('99 reps'), findsNothing);

    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    final WorkoutPlan updatedPlan = (await repository.getPlanById('plan-1'))!;
    final Workout addedWorkout = updatedPlan.workouts
        .singleWhere((Workout workout) => workout.title == 'Workout A');
    final Move addedMove = addedWorkout.sets.single.moves.single;
    expect(addedMove.exerciseId, 'burpee');
    expect(addedMove.repCount, 10);
    expect(addedMove.prepTimeSeconds, 5);
    expect(updatedPlan.exercises.single.imageUrl,
        'https://example.com/burpee.gif');
  });

  testWidgets('saves set names and loop counts', (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 1,
        planId: 'plan-1',
        name: 'Plan 1',
        workouts: <Workout>[],
        exercises: <Exercise>[],
      ),
    );

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        workoutRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(loadedWorkoutPlansNotifierProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: EditWorkoutScreen(planId: 'plan-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'Workout A');
    await tester.enterText(find.byType(TextField).at(1), 'Warmup');
    await tester.enterText(find.byType(TextField).at(2), '3');
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    final WorkoutPlan? updatedPlan = await repository.getPlanById('plan-1');
    final WorkoutSet savedSet = updatedPlan!.workouts.single.sets.single;
    expect(savedSet.name, 'Warmup');
    expect(savedSet.loopCount, 3);
  });
}
