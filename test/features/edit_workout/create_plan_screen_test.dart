import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/core/media/image_or_gif_url_field.dart';
import 'package:workout_app_rewrite/features/edit_workout/presentation/create_plan_screen.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  testWidgets('creates plans with the shared image or GIF field',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    final ProviderContainer container = ProviderContainer(
      overrides: <Override>[
        workoutRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);
    await container.read(loadedWorkoutPlansNotifierProvider.future);

    final GoRouter router = _buildRouter(initialLocation: '/create');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final Finder fields = find.byType(TextField);
    await tester.enterText(fields.at(0), 'Plan 1');
    await tester.enterText(fields.at(1), 'https://example.com/plan.gif');

    final TextField mediaField = tester.widget<TextField>(fields.at(1));
    expect(mediaField.keyboardType, TextInputType.multiline);
    expect(mediaField.contentInsertionConfiguration, isNotNull);
    expect(
      mediaField.contentInsertionConfiguration!.allowedMimeTypes,
      contains('image/gif'),
    );

    await tester.tap(find.text('Create'));
    await tester.pumpAndSettle();

    final List<WorkoutPlan> plans = await repository.getAllPlans();
    expect(plans.single.name, 'Plan 1');
    expect(plans.single.imageUrl, 'https://example.com/plan.gif');
    expect(find.text('Plan detail'), findsOneWidget);
  });

  testWidgets('edits a plan image without replacing its contents',
      (WidgetTester tester) async {
    final InMemoryWorkoutRepository repository = InMemoryWorkoutRepository();
    await repository.savePlan(
      const WorkoutPlan(
        schemaVersion: 4,
        planId: 'plan-1',
        name: 'Plan 1',
        imageUrl: 'https://example.com/old.gif',
        workouts: <Workout>[
          Workout(
            workoutId: 'workout-1',
            title: 'Workout 1',
            sets: <WorkoutSet>[],
          ),
        ],
        moves: <Move>[
          Move(moveId: 'move-1', name: 'Push Up'),
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

    final GoRouter router =
        _buildRouter(initialLocation: '/library/detail/plan-1/edit');
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    final Finder mediaField = find.descendant(
      of: find.byType(ImageOrGifUrlField),
      matching: find.byType(TextField),
    );
    expect(
      tester.widget<TextField>(mediaField).controller?.text,
      'https://example.com/old.gif',
    );

    await tester.enterText(mediaField, 'https://example.com/new.gif');
    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    final WorkoutPlan savedPlan = (await repository.getPlanById('plan-1'))!;
    expect(savedPlan.imageUrl, 'https://example.com/new.gif');
    expect(savedPlan.workouts.single.workoutId, 'workout-1');
    expect(savedPlan.moves.single.moveId, 'move-1');
    expect(find.text('Plan detail'), findsOneWidget);
  });
}

GoRouter _buildRouter({required String initialLocation}) {
  return GoRouter(
    initialLocation: initialLocation,
    routes: <RouteBase>[
      GoRoute(
        path: '/create',
        builder: (BuildContext context, GoRouterState state) {
          return const CreatePlanScreen();
        },
      ),
      GoRoute(
        path: '/library/detail/:planId',
        builder: (BuildContext context, GoRouterState state) {
          return const Text(
            'Plan detail',
            textDirection: TextDirection.ltr,
          );
        },
        routes: <RouteBase>[
          GoRoute(
            path: 'edit',
            builder: (BuildContext context, GoRouterState state) {
              return CreatePlanScreen(
                planId: state.pathParameters['planId']!,
              );
            },
          ),
        ],
      ),
    ],
  );
}
