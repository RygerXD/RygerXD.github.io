import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';
import 'package:workout_app_rewrite/main.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('app shell renders and navigates between tabs',
      (WidgetTester tester) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    final WorkoutRepository workoutRepository = InMemoryWorkoutRepository();

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          allSessionsProvider.overrideWith(
            (ref) => Stream<List<WorkoutSessionEntity>>.value(
                <WorkoutSessionEntity>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          workoutRepositoryProvider.overrideWithValue(workoutRepository),
        ],
        child: const WorkoutApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Import Plan JSON'), findsOneWidget);
    expect(find.text('Create Plan'), findsOneWidget);
    final Iterable<SafeArea> shellSafeAreas = tester.widgetList<SafeArea>(
      find.ancestor(
        of: find.text('My Workouts'),
        matching: find.byType(SafeArea),
      ),
    );
    expect(
        shellSafeAreas
            .any((SafeArea safeArea) => safeArea.top && !safeArea.bottom),
        isTrue);

    await tester.tap(find.text('Moves'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('No moves yet. Import or create a plan to add some.'),
        findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Audio cues'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Get ready ding'),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Get ready ding'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Move finished ding'),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Move finished ding'), findsOneWidget);
  });

  testWidgets('moves tab returns to moves after archiving a workout',
      (WidgetTester tester) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    final InMemoryWorkoutRepository workoutRepository =
        InMemoryWorkoutRepository();
    await workoutRepository.savePlan(
      const WorkoutPlan(
        schemaVersion: 4,
        planId: 'plan-1',
        name: 'Plan 1',
        workouts: <Workout>[
          Workout(
            workoutId: 'workout-a',
            title: 'Workout A',
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
          Move(moveId: 'move-1', name: 'Squat'),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          allSessionsProvider.overrideWith(
            (ref) => Stream<List<WorkoutSessionEntity>>.value(
                <WorkoutSessionEntity>[]),
          ),
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          workoutRepositoryProvider.overrideWithValue(workoutRepository),
        ],
        child: const WorkoutApp(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Workout A'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Archive workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Archive'));
    await tester.pumpAndSettle();

    expect(find.text('Workout not found'), findsNothing);

    await tester.tap(find.text('Moves'));
    await tester.pumpAndSettle();

    expect(
      find.text('No moves yet. Import or create a plan to add some.'),
      findsOneWidget,
    );
    expect(find.text('Workout not found'), findsNothing);
  });
}
