import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';
import 'package:workout_app_rewrite/features/workout_summary/presentation/workout_summary_screen.dart';

void main() {
  testWidgets('shows workout summary before start',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 1,
        planId: 'plan-1',
        name: 'Plan 1',
        description: 'Preview this workout before starting.',
        workouts: <Workout>[
          Workout(
            workoutId: 'workout-a',
            title: 'Workout A',
            sets: <WorkoutSet>[
              WorkoutSet(
                setId: 'set-a',
                name: 'Circuit',
                loopCount: 2,
                restBetweenLoopsSeconds: 15,
                moves: <Move>[
                  Move(
                    moveId: 'move-a',
                    exerciseId: 'squat',
                    type: MoveType.duration,
                    prepTimeSeconds: 5,
                    durationSeconds: 30,
                  ),
                  Move(
                    moveId: 'move-b',
                    exerciseId: 'push-up',
                    type: MoveType.reps,
                    repCount: 12,
                  ),
                ],
              ),
            ],
          ),
        ],
        exercises: <Exercise>[
          Exercise(exerciseId: 'squat', name: 'Squat'),
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
          home: WorkoutSummaryScreen(
            planId: 'plan-1',
            workoutId: 'workout-a',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Workout A'), findsOneWidget);
    expect(find.text('Duration'), findsOneWidget);
    expect(find.text('00:01:25'), findsOneWidget);
    expect(find.text('Exercises'), findsWidgets);
    expect(find.text('4'), findsOneWidget);
    expect(find.text('Preview this workout before starting.'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Circuit'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Circuit'), findsOneWidget);
    expect(find.text('x2 Laps'), findsOneWidget);
    expect(find.text('Squat'), findsOneWidget);
    expect(find.text('Push Up'), findsOneWidget);
    expect(find.text('00:30'), findsOneWidget);
    expect(find.text('12 reps'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'START'), findsOneWidget);
  });
}
