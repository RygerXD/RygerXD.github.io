import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/dashboard/presentation/dashboard_screen.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('shows workouts by most recent completion with estimates',
      (WidgetTester tester) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 1,
        planId: 'plan-1',
        name: 'Plan 1',
        workouts: <Workout>[
          Workout(
            workoutId: 'workout-a',
            title: 'Older Workout',
            sets: <WorkoutSet>[
              WorkoutSet(
                setId: 'set-a',
                lapCount: 1,
                restBetweenLapsSeconds: 0,
                moves: <WorkoutMove>[
                  WorkoutMove(
                    workoutMoveId: 'move-a',
                    moveId: 'move-a',
                    type: MoveType.duration,
                    durationSeconds: 30,
                  ),
                ],
              ),
            ],
          ),
          Workout(
            workoutId: 'workout-b',
            title: 'Recent Workout',
            imageUrl: 'https://example.com/recent-workout.gif',
            sets: <WorkoutSet>[
              WorkoutSet(
                setId: 'set-b',
                lapCount: 1,
                restBetweenLapsSeconds: 0,
                moves: <WorkoutMove>[
                  WorkoutMove(
                    workoutMoveId: 'move-b',
                    moveId: 'move-b',
                    type: MoveType.duration,
                    prepTimeSeconds: 5,
                    durationSeconds: 65,
                  ),
                ],
              ),
            ],
          ),
        ],
        moves: <Move>[
          Move(moveId: 'move-a', name: 'A'),
          Move(moveId: 'move-b', name: 'B'),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          workoutRepositoryProvider.overrideWithValue(repository),
          allSessionsProvider.overrideWith(
            (ref) => Stream<List<WorkoutSessionEntity>>.value(
              const <WorkoutSessionEntity>[
                WorkoutSessionEntity(
                  sessionId: 'session-a',
                  planId: 'plan-1',
                  workoutId: 'workout-a',
                  startedAt: 1000,
                  durationSeconds: 30,
                  status: 'completed',
                ),
                WorkoutSessionEntity(
                  sessionId: 'session-b',
                  planId: 'plan-1',
                  workoutId: 'workout-b',
                  startedAt: 2000,
                  durationSeconds: 70,
                  status: 'completed',
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('My Workouts'), findsOneWidget);
    expect(find.text('Recent Workout'), findsOneWidget);
    expect(find.text('Older Workout'), findsOneWidget);
    expect(find.text('1mins 10sec'), findsOneWidget);

    final double recentTop = tester.getTopLeft(find.text('Recent Workout')).dy;
    final double olderTop = tester.getTopLeft(find.text('Older Workout')).dy;
    expect(recentTop, lessThan(olderTop));
  });

  testWidgets('toggles from workouts to plans', (WidgetTester tester) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
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
                    moveId: 'move-a',
                    type: MoveType.duration,
                    durationSeconds: 30,
                  ),
                ],
              ),
            ],
          ),
        ],
        moves: <Move>[
          Move(moveId: 'move-a', name: 'A'),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          workoutRepositoryProvider.overrideWithValue(repository),
          allSessionsProvider.overrideWith(
            (ref) => Stream<List<WorkoutSessionEntity>>.value(
              <WorkoutSessionEntity>[],
            ),
          ),
        ],
        child: const MaterialApp(home: DashboardScreen()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Workout A'), findsOneWidget);

    await tester.tap(find.text('My Plans'));
    await tester.pumpAndSettle();

    expect(find.text('Plan 1'), findsOneWidget);
    expect(find.text('1 workout'), findsOneWidget);
    expect(find.text('Workout A'), findsNothing);
  });

  testWidgets('workout tap opens the summary route instead of active workout',
      (WidgetTester tester) async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
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
                    moveId: 'move-a',
                    type: MoveType.duration,
                    durationSeconds: 30,
                  ),
                ],
              ),
            ],
          ),
        ],
        moves: <Move>[
          Move(moveId: 'move-a', name: 'A'),
        ],
      ),
    );
    final GoRouter router = GoRouter(
      initialLocation: '/dashboard',
      routes: <RouteBase>[
        GoRoute(
          path: '/dashboard',
          builder: (BuildContext context, GoRouterState state) {
            return const DashboardScreen();
          },
        ),
        GoRoute(
          path: '/library/detail/:planId/workout/:workoutId',
          builder: (BuildContext context, GoRouterState state) {
            return Text(
              'Summary ${state.pathParameters['workoutId']}',
              textDirection: TextDirection.ltr,
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
          workoutRepositoryProvider.overrideWithValue(repository),
          allSessionsProvider.overrideWith(
            (ref) => Stream<List<WorkoutSessionEntity>>.value(
              <WorkoutSessionEntity>[],
            ),
          ),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Workout A'));
    await tester.pumpAndSettle();

    expect(find.text('Summary workout-a'), findsOneWidget);
  });
}
