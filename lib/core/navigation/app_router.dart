import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/features/active_workout/presentation/active_workout_screen.dart';
import 'package:workout_app_rewrite/features/dashboard/presentation/dashboard_screen.dart';
import 'package:workout_app_rewrite/features/edit_workout/presentation/create_plan_screen.dart';
import 'package:workout_app_rewrite/features/edit_workout/presentation/edit_workout_screen.dart';
import 'package:workout_app_rewrite/features/history/presentation/analysis_screen.dart';
import 'package:workout_app_rewrite/features/history/presentation/workout_progress_screen.dart';
import 'package:workout_app_rewrite/features/library/presentation/library_screen.dart';
import 'package:workout_app_rewrite/features/settings/presentation/settings_screen.dart';
import 'package:workout_app_rewrite/features/workout_detail/presentation/workout_detail_screen.dart';

final Provider<GoRouter> appRouterProvider =
    Provider<GoRouter>((Ref<GoRouter> ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: <RouteBase>[
      StatefulShellRoute.indexedStack(
        builder: (
          BuildContext context,
          GoRouterState state,
          StatefulNavigationShell navigationShell,
        ) {
          return AppScaffold(navigationShell: navigationShell);
        },
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/dashboard',
                builder: (BuildContext context, GoRouterState state) {
                  return const DashboardScreen();
                },
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/library',
                builder: (BuildContext context, GoRouterState state) {
                  return const LibraryScreen();
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'create',
                    builder: (BuildContext context, GoRouterState state) {
                      return const CreatePlanScreen();
                    },
                  ),
                  GoRoute(
                    path: 'detail/:planId',
                    builder: (BuildContext context, GoRouterState state) {
                      final String planId = state.pathParameters['planId']!;
                      return WorkoutDetailScreen(planId: planId);
                    },
                    routes: <RouteBase>[
                      GoRoute(
                        path: 'edit-workout',
                        builder: (BuildContext context, GoRouterState state) {
                          final String planId = state.pathParameters['planId']!;
                          final String? workoutId =
                              state.uri.queryParameters['workoutId'];
                          return EditWorkoutScreen(
                            planId: planId,
                            workoutId: workoutId,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/analysis',
                builder: (BuildContext context, GoRouterState state) {
                  return const AnalysisScreen();
                },
                routes: <RouteBase>[
                  GoRoute(
                    path: 'session/:sessionId',
                    builder: (BuildContext context, GoRouterState state) {
                      final String sessionId =
                          state.pathParameters['sessionId']!;
                      return WorkoutProgressScreen(sessionId: sessionId);
                    },
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: '/settings',
                builder: (BuildContext context, GoRouterState state) {
                  return const SettingsScreen();
                },
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/active',
        builder: (BuildContext context, GoRouterState state) {
          return const ActiveWorkoutScreen();
        },
      ),
    ],
  );
});

class AppScaffold extends StatelessWidget {
  const AppScaffold({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: navigationShell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        destinations: const <Widget>[
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
              icon: Icon(Icons.fitness_center), label: 'Library'),
          NavigationDestination(
              icon: Icon(Icons.insights_outlined), label: 'Analysis'),
          NavigationDestination(
              icon: Icon(Icons.settings_outlined), label: 'Settings'),
        ],
        onDestinationSelected: (int index) {
          navigationShell.goBranch(index);
        },
      ),
    );
  }
}
