import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/exercises/presentation/exercises_screen.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  testWidgets('lists and edits existing exercises',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 1,
        planId: 'plan-1',
        name: 'Plan 1',
        workouts: <Workout>[
          Workout(
            workoutId: 'workout-1',
            title: 'Workout 1',
            sets: <WorkoutSet>[
              WorkoutSet(
                setId: 'set-1',
                loopCount: 1,
                restBetweenLoopsSeconds: 0,
                moves: <Move>[
                  Move(
                    moveId: 'move-1',
                    exerciseId: 'exercise-1',
                    type: MoveType.reps,
                    repCount: 10,
                  ),
                ],
              ),
            ],
          ),
        ],
        exercises: <Exercise>[
          Exercise(
            exerciseId: 'exercise-1',
            name: 'Push Up',
            imageUrl: 'https://example.com/push-up.gif',
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
        child: const MaterialApp(home: ExercisesScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Push Up'), findsOneWidget);
    expect(find.text('1 move across 1 plan'), findsOneWidget);

    await tester.tap(find.text('Push Up'));
    await tester.pumpAndSettle();

    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Incline Push Up');
    await tester.enterText(fields.at(1), 'https://example.com/incline.gif');
    await tester.enterText(fields.at(2), 'Hands elevated.');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final WorkoutPlan savedPlan = (await repository.getPlanById('plan-1'))!;
    final Exercise savedExercise = savedPlan.exercises.single;
    expect(savedExercise.name, 'Incline Push Up');
    expect(savedExercise.imageUrl, 'https://example.com/incline.gif');
    expect(savedExercise.description, 'Hands elevated.');
    expect(savedPlan.workouts.single.sets.single.moves.single.exerciseId,
        'exercise-1');
    expect(find.text('Incline Push Up'), findsOneWidget);
  });
}
