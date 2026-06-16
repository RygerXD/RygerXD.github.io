import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/edit_workout/presentation/add_move_dialog.dart';
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
        schemaVersion: 3,
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

    await tester.enterText(find.byType(TextField).at(0), 'Arms');
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
      find.text('Push Up'),
      findsOneWidget,
    );
    expect(find.text('Unknown Exercise'), findsNothing);

    await tester.tap(find.text('Existing'));
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Push Up'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('adds BPM to duration moves', (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 3,
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
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Metronome'));
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

  testWidgets('add move dialog saves each-side duration moves',
      (WidgetTester tester) async {
    Move? capturedMove;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AddMoveDialog(
                        onAdd: (Move move, Exercise exercise) {
                          capturedMove = move;
                        },
                      );
                    },
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    Finder dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.at(0), 'Lunge');
    await tester.tap(find.text('Time'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Left and right sides'));
    await tester.tap(find.text('Left and right sides'));
    await tester.pumpAndSettle();

    dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.at(4), '30');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add'));
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(capturedMove?.type, MoveType.duration);
    expect(capturedMove?.durationSeconds, 30);
    expect(capturedMove?.repeatEachSide, true);
  });

  testWidgets('add move dialog saves each-side rep moves',
      (WidgetTester tester) async {
    Move? capturedMove;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AddMoveDialog(
                        onAdd: (Move move, Exercise exercise) {
                          capturedMove = move;
                        },
                      );
                    },
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    Finder dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.at(0), 'Split Squat');

    await tester.ensureVisible(find.text('Left and right sides'));
    await tester.tap(find.text('Left and right sides'));
    await tester.pumpAndSettle();

    dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.at(4), '12');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add'));
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(capturedMove?.type, MoveType.reps);
    expect(capturedMove?.repCount, 12);
    expect(capturedMove?.repeatEachSide, true);
  });

  testWidgets('saves image or GIF URL for new moves',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 3,
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
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    final WorkoutPlan? updatedPlan = await repository.getPlanById('plan-1');
    expect(updatedPlan?.exercises.single.imageUrl,
        'https://example.com/plank.gif');
  });

  testWidgets('saves image or GIF URL for workouts',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 3,
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

    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Cardio');
    await tester.enterText(fields.at(1), 'https://example.com/cardio.gif');

    final TextField mediaField = tester.widget<TextField>(fields.at(1));
    expect(mediaField.keyboardType, TextInputType.multiline);
    expect(mediaField.contentInsertionConfiguration, isNotNull);
    expect(
      mediaField.contentInsertionConfiguration!.allowedMimeTypes,
      contains('image/gif'),
    );

    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    final WorkoutPlan? updatedPlan = await repository.getPlanById('plan-1');
    expect(updatedPlan?.workouts.single.imageUrl,
        'https://example.com/cardio.gif');
  });

  testWidgets('add move dialog saves target weight',
      (WidgetTester tester) async {
    Move? capturedMove;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AddMoveDialog(
                        onAdd: (Move move, Exercise exercise) {
                          capturedMove = move;
                        },
                      );
                    },
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    Finder dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.at(0), 'Dumbbell Curl');

    await tester.ensureVisible(find.text('Track weight'));
    await tester.tap(find.text('Track weight'));
    await tester.pumpAndSettle();

    dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.last, '35');
    await tester.ensureVisible(find.widgetWithText(FilledButton, 'Add'));
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(capturedMove?.targetWeight, 35);
    expect(capturedMove?.targetWeightUnit, WeightUnit.lb);
  });

  testWidgets('shows target weight on weighted move cards',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 3,
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
                restBetweenLapsSeconds: 30,
                moves: <Move>[
                  Move(
                    moveId: 'move-1',
                    exerciseId: 'incline-bench',
                    type: MoveType.reps,
                    repCount: 10,
                    setCount: 3,
                    targetWeight: 70,
                    targetWeightUnit: WeightUnit.lb,
                  ),
                ],
              ),
            ],
          ),
        ],
        exercises: <Exercise>[
          Exercise(exerciseId: 'incline-bench', name: 'Incline Bench'),
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
          home: EditWorkoutScreen(planId: 'plan-1', workoutId: 'workout-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Incline Bench'), findsOneWidget);
    expect(find.text('10 reps, 70lbs'), findsOneWidget);
    expect(find.text('3 sets x 10 reps, 70lbs'), findsNothing);
    expect(find.text('10 reps'), findsNothing);
  });

  testWidgets('add move dialog saves cooldown time',
      (WidgetTester tester) async {
    Move? capturedMove;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AddMoveDialog(
                        onAdd: (Move move, Exercise exercise) {
                          capturedMove = move;
                        },
                      );
                    },
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final Finder dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.at(0), 'Burpee');
    await tester.enterText(dialogFields.at(3), '20');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(capturedMove?.finishTimeSeconds, 20);
  });

  testWidgets('add move dialog defaults cooldown time to zero',
      (WidgetTester tester) async {
    Move? capturedMove;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AddMoveDialog(
                        onAdd: (Move move, Exercise exercise) {
                          capturedMove = move;
                        },
                      );
                    },
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final Finder dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.at(0), 'Jumping Jacks');
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(capturedMove?.finishTimeSeconds, 0);
  });

  testWidgets('add move media field accepts keyboard GIF insertion',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AddMoveDialog(
                        onAdd: (Move move, Exercise exercise) {},
                      );
                    },
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final Finder dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    final TextField mediaField = tester.widget<TextField>(dialogFields.at(1));

    expect(mediaField.keyboardType, TextInputType.multiline);
    expect(mediaField.textInputAction, TextInputAction.newline);
    expect(mediaField.minLines, 1);
    expect(mediaField.maxLines, 3);
    expect(mediaField.contentInsertionConfiguration, isNotNull);
    expect(
      mediaField.contentInsertionConfiguration!.allowedMimeTypes,
      contains('image/*'),
    );
    expect(
      mediaField.contentInsertionConfiguration!.allowedMimeTypes,
      contains('image/gif'),
    );
  });

  testWidgets('add move dialog saves max-time moves',
      (WidgetTester tester) async {
    Move? capturedMove;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (BuildContext context) {
              return TextButton(
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (BuildContext context) {
                      return AddMoveDialog(
                        onAdd: (Move move, Exercise exercise) {
                          capturedMove = move;
                        },
                      );
                    },
                  );
                },
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    final Finder dialogFields = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(dialogFields.at(0), 'Wall Sit');
    await tester.tap(find.text('Max Time'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Left and right sides'));
    await tester.tap(find.text('Left and right sides'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Add'));
    await tester.pumpAndSettle();

    expect(capturedMove?.type, MoveType.stopwatch);
    expect(capturedMove?.repCount, isNull);
    expect(capturedMove?.durationSeconds, isNull);
    expect(capturedMove?.repeatEachSide, true);
  });

  testWidgets('edits added moves', (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 3,
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

    await tester.tap(find.text('Push Up'));
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

  testWidgets('updates move set count from the exercise card',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 3,
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
                restBetweenLapsSeconds: 30,
                moves: <Move>[
                  Move(
                    moveId: 'move-1',
                    exerciseId: 'push-up',
                    type: MoveType.reps,
                    repCount: 10,
                  ),
                ],
              ),
            ],
          ),
        ],
        exercises: <Exercise>[
          Exercise(exerciseId: 'push-up', name: 'Push Up'),
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
          home: EditWorkoutScreen(planId: 'plan-1', workoutId: 'workout-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Increase sets'));
    await tester.pumpAndSettle();

    expect(find.text('2'), findsOneWidget);
    expect(find.text('sets'), findsOneWidget);

    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    final WorkoutPlan updatedPlan = (await repository.getPlanById('plan-1'))!;
    expect(updatedPlan.workouts.single.sets.single.moves.single.setCount, 2);
  });

  testWidgets('existing picker searches exercises and resets move settings',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 3,
        planId: 'plan-1',
        name: 'Plan 1',
        workouts: <Workout>[
          Workout(
            workoutId: 'source-workout',
            title: 'Source',
            sets: <WorkoutSet>[
              WorkoutSet(
                setId: 'source-set',
                lapCount: 1,
                restBetweenLapsSeconds: 30,
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
    expect(addedMove.finishTimeSeconds, 0);
    expect(updatedPlan.exercises.single.imageUrl,
        'https://example.com/burpee.gif');
  });

  testWidgets('saves set names, lap counts, and rest between laps',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 3,
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
    await tester.enterText(find.byType(TextField).at(2), 'Warmup');
    await tester.enterText(find.byType(TextFormField).last, '45');
    await tester.tap(find.byTooltip('Increase laps'));
    await tester.pump();
    await tester.tap(find.byTooltip('Increase laps'));
    await tester.pump();
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    final WorkoutPlan? updatedPlan = await repository.getPlanById('plan-1');
    final WorkoutSet savedSet = updatedPlan!.workouts.single.sets.single;
    expect(savedSet.name, 'Warmup');
    expect(savedSet.lapCount, 3);
    expect(savedSet.restBetweenLapsSeconds, 45);
  });

  testWidgets('new sets default rest between laps to zero',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 3,
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
    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    final WorkoutPlan? updatedPlan = await repository.getPlanById('plan-1');
    expect(
      updatedPlan!.workouts.single.sets.single.restBetweenLapsSeconds,
      0,
    );
  });

  testWidgets('reorders moves inside a set', (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 3,
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
                restBetweenLapsSeconds: 30,
                moves: <Move>[
                  Move(
                    moveId: 'move-1',
                    exerciseId: 'push-up',
                    type: MoveType.reps,
                    repCount: 10,
                  ),
                  Move(
                    moveId: 'move-2',
                    exerciseId: 'squat',
                    type: MoveType.reps,
                    repCount: 12,
                  ),
                ],
              ),
            ],
          ),
        ],
        exercises: <Exercise>[
          Exercise(exerciseId: 'push-up', name: 'Push Up'),
          Exercise(exerciseId: 'squat', name: 'Squat'),
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
          home: EditWorkoutScreen(planId: 'plan-1', workoutId: 'workout-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final Offset firstHandleCenter =
        tester.getCenter(find.byIcon(Icons.drag_indicator).first);
    final TestGesture gesture = await tester.startGesture(firstHandleCenter);
    await tester.pump();
    await gesture.moveBy(const Offset(0, 180));
    await tester.pump(const Duration(milliseconds: 500));
    await gesture.up();
    await tester.pumpAndSettle();

    await tester.tap(find.text('SAVE'));
    await tester.pumpAndSettle();

    final WorkoutPlan updatedPlan = (await repository.getPlanById('plan-1'))!;
    final List<Move> savedMoves = updatedPlan.workouts.single.sets.single.moves;
    expect(savedMoves.map((Move move) => move.exerciseId), <String>[
      'squat',
      'push-up',
    ]);
  });
}
