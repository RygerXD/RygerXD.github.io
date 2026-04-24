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
}
