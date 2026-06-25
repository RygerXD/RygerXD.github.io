import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/history/presentation/analysis_screen.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  testWidgets('shows actionable insights, records, and history filters',
      (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 700);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final DateTime now = DateTime.now();
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 1,
        planId: 'plan-1',
        name: 'Strength',
        workouts: <Workout>[
          Workout(
            workoutId: 'workout-1',
            title: 'Push Day',
            sets: <WorkoutSet>[],
          ),
        ],
        moves: <Move>[
          Move(moveId: 'move-1', name: 'Bench Press'),
        ],
      ),
    );

    final List<WorkoutSessionEntity> sessions = <WorkoutSessionEntity>[
      WorkoutSessionEntity(
        sessionId: 'session-1',
        planId: 'plan-1',
        workoutId: 'workout-1',
        planName: 'Strength',
        workoutName: 'Push Day',
        startedAt: now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
        endedAt: now.millisecondsSinceEpoch,
        durationSeconds: 1800,
        status: 'completed',
      ),
      WorkoutSessionEntity(
        sessionId: 'session-2',
        planId: 'plan-1',
        workoutId: 'workout-1',
        planName: 'Strength',
        workoutName: 'Push Day',
        startedAt: now.subtract(const Duration(days: 8)).millisecondsSinceEpoch,
        endedAt: now.subtract(const Duration(days: 8)).millisecondsSinceEpoch,
        durationSeconds: 1200,
        status: 'completed',
      ),
      WorkoutSessionEntity(
        sessionId: 'session-3',
        planId: 'plan-1',
        workoutId: 'workout-1',
        planName: 'Strength',
        workoutName: 'Push Day',
        startedAt: now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
        endedAt: now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
        durationSeconds: 300,
        status: 'completedEarly',
      ),
    ];
    final List<WorkoutMovePerformanceEntity> performances =
        <WorkoutMovePerformanceEntity>[
      WorkoutMovePerformanceEntity(
        performanceId: 'performance-1',
        sessionId: 'session-1',
        workoutId: 'workout-1',
        setId: 'set-1',
        lapIndex: 0,
        workoutMoveId: 'workout-move-1',
        moveId: 'move-1',
        repCount: 12,
        actualWeight: 50,
        actualWeightUnit: 'lb',
        elapsedSeconds: 30,
        completedAt: now.millisecondsSinceEpoch,
      ),
      WorkoutMovePerformanceEntity(
        performanceId: 'performance-2',
        sessionId: 'session-2',
        workoutId: 'workout-1',
        setId: 'set-1',
        lapIndex: 0,
        workoutMoveId: 'workout-move-1',
        moveId: 'move-1',
        repCount: 10,
        actualWeight: 45,
        actualWeightUnit: 'lb',
        elapsedSeconds: 30,
        completedAt:
            now.subtract(const Duration(days: 8)).millisecondsSinceEpoch,
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          workoutRepositoryProvider.overrideWithValue(repository),
          allSessionsProvider.overrideWith(
            (ref) => Stream<List<WorkoutSessionEntity>>.value(sessions),
          ),
          allMovePerformancesProvider.overrideWith(
            (ref) =>
                Stream<List<WorkoutMovePerformanceEntity>>.value(performances),
          ),
        ],
        child: const MaterialApp(home: AnalysisScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Active time'), findsOneWidget);
    expect(find.byIcon(Icons.trending_up), findsOneWidget);
    expect(find.byTooltip('Export'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('Personal records'),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('50 lb'), findsWidgets);
    expect(find.text('12 reps'), findsWidgets);
    expect(find.text('Recent trends'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('History'),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Workout'), findsOneWidget);
    expect(find.text('Move'), findsOneWidget);
    expect(find.text('90d'), findsOneWidget);
    expect(find.text('Ended Early'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
