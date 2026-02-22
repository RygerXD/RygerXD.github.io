import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/features/active_workout/application/active_workout_controller.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({
    super.key,
    required this.planId,
  });

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<WorkoutPlan>> plansState = ref.watch(loadedWorkoutPlansNotifierProvider);

    return plansState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stack) => Scaffold(body: Center(child: Text('Error loading plan: $error'))),
      data: (List<WorkoutPlan> plans) {
        final WorkoutPlan? plan = plans.where((p) => p.planId == planId).firstOrNull;

        if (plan == null) {
          return const Scaffold(
            body: Center(child: Text('Plan not found')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(plan.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/library');
                }
              },
            ),
            actions: <Widget>[
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  ref.read(loadedWorkoutPlansNotifierProvider.notifier).removePlan(planId);
                  context.go('/library');
                },
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => context.go('/library/detail/$planId/edit-workout'),
            icon: const Icon(Icons.add),
            label: const Text('Add Workout'),
          ),
          body: ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: <Widget>[
              if (plan.description != null) ...[
                Text(
                  plan.description!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              Text(
                'Workouts in this Plan',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              ...plan.workouts.map((Workout workout) {
                return Card(
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Expanded(
                              child: Text(
                                workout.title,
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_outlined),
                              onPressed: () => context.go('/library/detail/$planId/edit-workout?workoutId=${workout.workoutId}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text('${workout.sets.length} Sets'),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton(
                          onPressed: () {
                            ref.read(activeWorkoutControllerProvider.notifier).startWithWorkout(workout, planId);
                            context.go('/active');
                          },
                          child: const Text('Start Workout'),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}
