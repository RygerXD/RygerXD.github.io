import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/core/media/media_thumbnail.dart';
import 'package:workout_app_rewrite/features/workout_detail/presentation/workout_detail_screen.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_export_service.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  testWidgets('shows workout image thumbnails inside a plan',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    final _FakeWorkoutPlanExportService exportService =
        _FakeWorkoutPlanExportService();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 1,
        planId: 'plan-1',
        name: 'Plan 1',
        workouts: <Workout>[
          Workout(
            workoutId: 'workout-1',
            title: 'Leg Day',
            imageUrl: 'workout.gif',
            sets: <WorkoutSet>[
              WorkoutSet(
                setId: 'set-1',
                lapCount: 1,
                restBetweenLapsSeconds: 0,
                moves: <WorkoutMove>[
                  WorkoutMove(
                    workoutMoveId: 'move-1',
                    moveId: 'move-1',
                    type: MoveType.duration,
                    durationSeconds: 60,
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

    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        workoutRepositoryProvider.overrideWithValue(repository),
        workoutPlanExportServiceProvider.overrideWithValue(exportService),
      ],
    );
    addTearDown(container.dispose);
    await container.read(loadedWorkoutPlansNotifierProvider.future);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: WorkoutDetailScreen(planId: 'plan-1'),
        ),
      ),
    );
    await tester.pump();

    final MediaThumbnail thumbnail =
        tester.widget<MediaThumbnail>(find.byType(MediaThumbnail));
    expect(thumbnail.imageUrl, 'workout.gif');
    expect(thumbnail.dimension, 60);
    expect(find.text('Leg Day'), findsOneWidget);
    expect(find.text('1mins'), findsOneWidget);
    expect(find.text('1 Block'), findsOneWidget);
    expect(find.byTooltip('Export plan'), findsOneWidget);
    expect(find.byTooltip('Export workout'), findsNothing);
    expect(find.byTooltip('Edit workout'), findsNothing);
    expect(exportService.exportedPlan, isNull);
  });

  testWidgets('confirms before deleting workout plan',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 1,
        planId: 'plan-1',
        name: 'Plan 1',
        workouts: <Workout>[],
        moves: <Move>[],
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
          home: WorkoutDetailScreen(planId: 'plan-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.delete_outline));
    await tester.pumpAndSettle();

    expect(find.text('Delete Workout?'), findsOneWidget);
    expect(
      find.text('Are you sure you want to delete "Plan 1"?'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(await repository.getPlanById('plan-1'), isNotNull);
  });
}

class _FakeWorkoutPlanExportService extends WorkoutPlanExportService {
  WorkoutPlan? exportedPlan;

  @override
  Future<WorkoutPlanExportResult?> exportPlan(WorkoutPlan plan) async {
    exportedPlan = plan;
    return const WorkoutPlanExportResult(
      fileName: 'leg-day.workout.plan.json',
      path: 'C:\\leg-day.workout.plan.json',
    );
  }
}
