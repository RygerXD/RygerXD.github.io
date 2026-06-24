import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/core/audio/built_in_sound_catalog.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/settings/presentation/sounds_screen.dart';
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
          builtInSoundsProvider.overrideWith(
            (ref) async => BuiltInSoundCatalog.fromAssetPaths(<String>[
              'assets/audio/classic.ogg',
              'assets/audio/new-sound.mp3',
            ]),
          ),
          workoutRepositoryProvider.overrideWithValue(workoutRepository),
        ],
        child: const WorkoutApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Import a plan'), findsOneWidget);
    expect(find.text('Create first plan'), findsOneWidget);
    final Iterable<SafeArea> shellSafeAreas = tester.widgetList<SafeArea>(
      find.ancestor(
        of: find.text('Create first plan'),
        matching: find.byType(SafeArea),
      ),
    );
    expect(
        shellSafeAreas
            .any((SafeArea safeArea) => safeArea.top && !safeArea.bottom),
        isTrue);

    await tester.tap(find.text('Library'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Plans'), findsOneWidget);

    await tester.tap(find.text('Moves'));
    await tester.pumpAndSettle();
    expect(find.text('No moves yet. Import or create a plan to add some.'),
        findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Sounds'), findsOneWidget);

    await tester.tap(find.text('Sounds'));
    await tester.pumpAndSettle();

    expect(find.text('Audio cues'), findsOneWidget);
    await tester.tap(find.byType(DropdownButtonFormField<int>).first);
    await tester.pumpAndSettle();
    expect(find.text('New sound'), findsOneWidget);
    await tester.tap(find.text('New sound'));
    await tester.pumpAndSettle();
    expect(
      sharedPreferences.getString('settings.sound_selections.v1'),
      contains('new-sound.mp3'),
    );
    await tester.scrollUntilVisible(
      find.text('Move start'),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Move start'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Move finished'),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Move finished'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('Metronome'),
      500,
      scrollable: find.byType(Scrollable),
    );
    await tester.tap(
      find.widgetWithText(SwitchListTile, 'Metronome'),
    );
    await tester.pumpAndSettle();
    expect(
      sharedPreferences.getBool('settings.metronome_click_enabled.v1'),
      isFalse,
    );

    await tester.scrollUntilVisible(
      find.text('Workout ended early'),
      500,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Workout complete'), findsOneWidget);
    expect(find.text('Rest finished'), findsNothing);
    expect(find.text('Move countdown'), findsNothing);
    expect(find.text('Workout ended early'), findsOneWidget);
  });

  testWidgets('moves tab returns to moves after archiving a workout',
      (WidgetTester tester) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    final InMemoryWorkoutRepository workoutRepository =
        InMemoryWorkoutRepository();
    await workoutRepository.savePlan(
      const WorkoutPlan(
        schemaVersion: 1,
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

    await tester.tap(find.byTooltip('Delete workout'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(find.text('Workout not found'), findsNothing);

    await tester.tap(find.text('Library'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Moves'));
    await tester.pumpAndSettle();

    expect(
      find.text('No moves yet. Import or create a plan to add some.'),
      findsOneWidget,
    );
    expect(find.text('Workout not found'), findsNothing);
  });
}
