import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_export_service.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';
import 'package:workout_app_rewrite/features/workout_summary/presentation/workout_summary_screen.dart';

void main() {
  testWidgets('shows workout summary before start',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    final _FakeWorkoutPlanExportService exportService =
        _FakeWorkoutPlanExportService();
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
                lapCount: 2,
                restBetweenLapsSeconds: 15,
                moves: <WorkoutMove>[
                  WorkoutMove(
                    workoutMoveId: 'move-a',
                    moveId: 'squat',
                    type: MoveType.duration,
                    prepTimeSeconds: 5,
                    durationSeconds: 30,
                  ),
                  WorkoutMove(
                    workoutMoveId: 'move-b',
                    moveId: 'push-up',
                    type: MoveType.reps,
                    repCount: 12,
                  ),
                ],
              ),
            ],
          ),
        ],
        moves: <Move>[
          Move(moveId: 'squat', name: 'Squat'),
          Move(moveId: 'push-up', name: 'Push Up'),
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
          home: WorkoutSummaryScreen(
            planId: 'plan-1',
            workoutId: 'workout-a',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Workout A'), findsOneWidget);
    expect(find.text('Est. duration'), findsOneWidget);
    expect(find.text('Calories'), findsNothing);
    expect(find.text('00:01:25'), findsOneWidget);
    expect(find.text('Moves'), findsWidgets);
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
    expect(find.byTooltip('Export workout'), findsOneWidget);

    await tester.tap(find.byTooltip('Export workout'));
    await tester.pumpAndSettle();

    expect(exportService.exportedPlan?.planId, 'plan-1-workout-a');
    expect(exportService.exportedPlan?.name, 'Workout A');
    expect(exportService.exportedPlan?.workouts.single.workoutId, 'workout-a');
    expect(
      exportService.exportedPlan?.moves.map((Move move) => move.moveId),
      <String>['squat', 'push-up'],
    );
    expect(find.text('Exported Workout A'), findsOneWidget);
  });

  testWidgets('confirms before deleting workout from active plan views',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
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
                setId: 'set-a',
                lapCount: 1,
                restBetweenLapsSeconds: 0,
                moves: <WorkoutMove>[
                  WorkoutMove(
                    workoutMoveId: 'move-a',
                    moveId: 'push-up',
                    type: MoveType.reps,
                    repCount: 10,
                  ),
                ],
              ),
            ],
          ),
          Workout(
            workoutId: 'workout-b',
            title: 'Workout B',
            sets: <WorkoutSet>[
              WorkoutSet(
                setId: 'set-b',
                lapCount: 1,
                restBetweenLapsSeconds: 0,
                moves: <WorkoutMove>[
                  WorkoutMove(
                    workoutMoveId: 'move-b',
                    moveId: 'squat',
                    type: MoveType.reps,
                    repCount: 12,
                  ),
                ],
              ),
            ],
          ),
        ],
        moves: <Move>[
          Move(moveId: 'push-up', name: 'Push Up'),
          Move(moveId: 'squat', name: 'Squat'),
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

    final GoRouter router = GoRouter(
      initialLocation: '/library/detail/plan-1/workout/workout-a',
      routes: <RouteBase>[
        GoRoute(
          path: '/library/detail/:planId',
          builder: (BuildContext context, GoRouterState state) {
            return Scaffold(
              body: Text('Plan detail ${state.pathParameters['planId']}'),
            );
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'workout/:workoutId',
              builder: (BuildContext context, GoRouterState state) {
                return WorkoutSummaryScreen(
                  planId: state.pathParameters['planId']!,
                  workoutId: state.pathParameters['workoutId']!,
                );
              },
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Delete workout'));
    await tester.pumpAndSettle();

    expect(find.text('Delete Workout?'), findsOneWidget);
    expect(
      find.text(
        'Delete "Workout A" from this plan? Saved workout history will stay available.',
      ),
      findsOneWidget,
    );

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    final WorkoutPlan? updatedPlan = await repository.getPlanById('plan-1');
    expect(updatedPlan?.workouts, hasLength(1));
    expect(updatedPlan?.workouts.single.workoutId, 'workout-b');
    expect(updatedPlan?.workouts.single.isArchived, isFalse);
    expect(
        updatedPlan?.moves.map((Move move) => move.moveId), <String>['squat']);
    expect(find.text('Plan detail plan-1'), findsOneWidget);
  });

  testWidgets('back arrow returns to the route that opened the workout summary',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
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
                setId: 'set-a',
                lapCount: 1,
                restBetweenLapsSeconds: 0,
                moves: <WorkoutMove>[
                  WorkoutMove(
                    workoutMoveId: 'move-a',
                    moveId: 'push-up',
                    type: MoveType.reps,
                    repCount: 10,
                  ),
                ],
              ),
            ],
          ),
        ],
        moves: <Move>[
          Move(moveId: 'push-up', name: 'Push Up'),
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

    final GoRouter router = GoRouter(
      initialLocation: '/dashboard',
      routes: <RouteBase>[
        GoRoute(
          path: '/dashboard',
          builder: (BuildContext context, GoRouterState state) {
            return Scaffold(
              body: Center(
                child: FilledButton(
                  onPressed: () => context.push(
                    '/library/detail/plan-1/workout/workout-a',
                  ),
                  child: const Text('Open workout'),
                ),
              ),
            );
          },
        ),
        GoRoute(
          path: '/library/detail/:planId',
          builder: (BuildContext context, GoRouterState state) {
            return Scaffold(
              body: Text('Plan detail ${state.pathParameters['planId']}'),
            );
          },
          routes: <RouteBase>[
            GoRoute(
              path: 'workout/:workoutId',
              builder: (BuildContext context, GoRouterState state) {
                return WorkoutSummaryScreen(
                  planId: state.pathParameters['planId']!,
                  workoutId: state.pathParameters['workoutId']!,
                );
              },
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open workout'));
    await tester.pumpAndSettle();

    expect(find.text('Workout A'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(find.text('Open workout'), findsOneWidget);
    expect(find.text('Plan detail plan-1'), findsNothing);
  });
}

class _FakeWorkoutPlanExportService extends WorkoutPlanExportService {
  WorkoutPlan? exportedPlan;

  @override
  Future<WorkoutPlanExportResult?> exportPlan(WorkoutPlan plan) async {
    exportedPlan = plan;
    return const WorkoutPlanExportResult(
      fileName: 'workout-a.workout.plan.json',
      path: 'C:\\workout-a.workout.plan.json',
    );
  }
}
