import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/core/media/media_thumbnail.dart';
import 'package:workout_app_rewrite/core/media/move_media_image.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/core/widgets/confirm_destructive_action.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/history/domain/workout_time_estimate.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_metrics.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';
import 'package:workout_app_rewrite/features/workout_plan/presentation/export_workout_plan.dart';

class WorkoutDetailScreen extends ConsumerWidget {
  const WorkoutDetailScreen({
    super.key,
    required this.planId,
  });

  final String planId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<WorkoutPlan>> plansState =
        ref.watch(loadedWorkoutPlansNotifierProvider);
    final List<WorkoutMovePerformanceEntity> performances =
        ref.watch(allMovePerformancesProvider).value ??
            <WorkoutMovePerformanceEntity>[];

    return plansState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (Object error, StackTrace stack) =>
          Scaffold(body: Center(child: Text('Error loading plan: $error'))),
      data: (List<WorkoutPlan> plans) {
        final WorkoutPlan? plan =
            plans.where((p) => p.planId == planId).firstOrNull;

        if (plan == null) {
          return const Scaffold(
            body: Center(child: Text('Plan not found')),
          );
        }
        final List<Workout> activeWorkouts = plan.workouts
            .where((Workout workout) => !workout.isArchived)
            .toList(growable: false);

        return Scaffold(
          appBar: AppBar(
            title: Text(plan.name),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/dashboard');
                }
              },
            ),
            actions: <Widget>[
              IconButton(
                tooltip: 'Export plan',
                icon: const Icon(Icons.upload_file_outlined),
                onPressed: () => exportWorkoutPlan(context, ref, plan),
              ),
              IconButton(
                tooltip: 'Edit plan',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.go('/library/detail/$planId/edit'),
              ),
              IconButton(
                tooltip: 'Delete plan',
                icon: const Icon(Icons.delete_outline),
                onPressed: () async {
                  final bool shouldDelete =
                      await _confirmDeleteWorkout(context, plan.name);
                  if (!shouldDelete || !context.mounted) {
                    return;
                  }
                  await ref
                      .read(loadedWorkoutPlansNotifierProvider.notifier)
                      .removePlan(planId);
                  if (context.mounted) {
                    context.go('/dashboard');
                  }
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
              if (optionalText(plan.imageUrl) case final String imageUrl) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadii.md),
                  child: SizedBox(
                    height: 180,
                    child: MoveMediaImage(
                      source: imageUrl,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
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
              if (activeWorkouts.isEmpty)
                Text(
                  'No active workouts in this plan.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ...activeWorkouts.map((Workout workout) {
                return _PlanWorkoutCard(
                  workout: workout,
                  performances: performances,
                  onTap: () => context.go(
                    '/library/detail/$planId/workout/${workout.workoutId}',
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

class _PlanWorkoutCard extends StatelessWidget {
  const _PlanWorkoutCard({
    required this.workout,
    required this.performances,
    required this.onTap,
  });

  final Workout workout;
  final List<WorkoutMovePerformanceEntity> performances;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String setCount =
        '${workout.sets.length} ${workout.sets.length == 1 ? 'Block' : 'Blocks'}';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              MediaThumbnail(
                imageUrl: optionalText(workout.imageUrl),
                fallbackIcon: Icons.fitness_center,
                backgroundColor: colors.primaryContainer,
                iconColor: colors.onPrimaryContainer,
                dimension: 60,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      workout.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.timer_outlined,
                          size: 18,
                          color: colors.onSurfaceVariant,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            formatWorkoutEstimate(
                              estimateWorkoutSecondsFromHistory(
                                workout,
                                performances,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: colors.onSurfaceVariant,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      setCount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colors.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Icon(
                Icons.chevron_right,
                color: colors.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<bool> _confirmDeleteWorkout(
    BuildContext context, String workoutName) async {
  return confirmDestructiveAction(
    context,
    title: 'Delete Workout?',
    message: 'Are you sure you want to delete "$workoutName"?',
  );
}
