import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/moves/presentation/moves_screen.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  testWidgets('lists and edits existing moves', (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 4,
        planId: 'plan-1',
        name: 'Plan 1',
        workouts: <Workout>[
          Workout(
            workoutId: 'workout-1',
            title: 'Workout 1',
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
                  WorkoutMove(
                    workoutMoveId: 'move-2',
                    moveId: 'move-2',
                    type: MoveType.reps,
                    repCount: 12,
                  ),
                ],
              ),
            ],
          ),
        ],
        moves: <Move>[
          Move(
            moveId: 'move-1',
            name: 'Push Up',
            imageUrl: 'https://example.com/push-up.gif',
          ),
          Move(
            moveId: 'move-2',
            name: 'Squat',
          ),
          Move(
            moveId: 'unused-move',
            name: 'Old Deleted Workout Move',
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
        child: const MaterialApp(home: MovesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Push Up'), findsOneWidget);
    expect(find.text('1 move'), findsNothing);
    expect(find.text('1 move across 1 plan'), findsNothing);
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('Old Deleted Workout Move'), findsNothing);

    await tester.enterText(
        find.widgetWithText(TextField, 'Search moves'), 'psh');
    await tester.pumpAndSettle();

    expect(find.text('Push Up'), findsOneWidget);
    expect(find.text('1 move'), findsNothing);
    expect(find.text('Squat'), findsNothing);

    await tester.tap(find.text('Push Up'));
    await tester.pumpAndSettle();

    expect(find.text('From: Plan 1'), findsOneWidget);

    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(1), 'Incline Push Up');
    await tester.enterText(fields.at(2), 'https://example.com/incline.gif');
    await tester.enterText(fields.at(3), 'Hands elevated.');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final WorkoutPlan savedPlan = (await repository.getPlanById('plan-1'))!;
    final Move savedMove = savedPlan.moves.firstWhere(
      (Move move) => move.moveId == 'move-1',
    );
    expect(savedMove.name, 'Incline Push Up');
    expect(savedMove.imageUrl, 'https://example.com/incline.gif');
    expect(savedMove.description, 'Hands elevated.');
    expect(
      savedPlan.workouts.single.sets.single.moves
          .map((WorkoutMove move) => move.moveId),
      contains('move-1'),
    );
    expect(find.text('Incline Push Up'), findsOneWidget);
  });

  testWidgets('removes moves from deleted plans', (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 4,
        planId: 'plan-1',
        name: 'Deleted Plan',
        workouts: <Workout>[
          Workout(
            workoutId: 'workout-1',
            title: 'Workout 1',
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
          Move(moveId: 'move-1', name: 'Push Up'),
        ],
      ),
    );
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 4,
        planId: 'plan-2',
        name: 'Remaining Plan',
        workouts: <Workout>[
          Workout(
            workoutId: 'workout-2',
            title: 'Workout 2',
            sets: <WorkoutSet>[
              WorkoutSet(
                setId: 'set-2',
                lapCount: 1,
                restBetweenLapsSeconds: 0,
                moves: <WorkoutMove>[
                  WorkoutMove(
                    workoutMoveId: 'move-2',
                    moveId: 'move-2',
                    type: MoveType.reps,
                    repCount: 12,
                  ),
                ],
              ),
            ],
          ),
        ],
        moves: <Move>[
          Move(moveId: 'move-2', name: 'Squat'),
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
        child: const MaterialApp(home: MovesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Push Up'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);

    await container
        .read(loadedWorkoutPlansNotifierProvider.notifier)
        .removePlan('plan-1');
    await tester.pumpAndSettle();

    expect(find.text('Push Up'), findsNothing);
    expect(find.text('Squat'), findsOneWidget);
  });
}
