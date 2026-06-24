import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/core/media/media_thumbnail.dart';
import 'package:workout_app_rewrite/core/media/move_media_image.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/core/widgets/confirm_destructive_action.dart';
import 'package:workout_app_rewrite/features/active_workout/application/active_workout_controller.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/history/domain/workout_time_estimate.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_metrics.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';
import 'package:workout_app_rewrite/features/workout_plan/presentation/export_workout_plan.dart';

class WorkoutSummaryScreen extends ConsumerWidget {
  const WorkoutSummaryScreen({
    super.key,
    required this.planId,
    required this.workoutId,
  });

  final String planId;
  final String workoutId;

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
          Scaffold(body: Center(child: Text('Error loading workout: $error'))),
      data: (List<WorkoutPlan> plans) {
        final WorkoutPlan? plan = plans
            .where((WorkoutPlan plan) => plan.planId == planId)
            .firstOrNull;
        final Workout? workout = plan?.workouts
            .where((Workout workout) =>
                workout.workoutId == workoutId && !workout.isArchived)
            .firstOrNull;

        if (plan == null || workout == null) {
          return const Scaffold(
            body: Center(child: Text('Workout not found')),
          );
        }

        final Map<String, Move> movesById = <String, Move>{
          for (final Move move in plan.moves) move.moveId: move,
        };
        final int estimatedSeconds =
            estimateWorkoutSecondsFromHistory(workout, performances);

        return Scaffold(
          appBar: AppBar(
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
                tooltip: 'Export workout',
                icon: const Icon(Icons.upload_file_outlined),
                onPressed: () => exportWorkoutPlan(
                  context,
                  ref,
                  _singleWorkoutPlan(plan, workout),
                ),
              ),
              IconButton(
                tooltip: 'Edit workout',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => context.go(
                  '/library/detail/$planId/edit-workout?workoutId=$workoutId',
                ),
              ),
              IconButton(
                tooltip: 'Delete workout',
                icon: const Icon(Icons.delete_outline),
                onPressed: () => _deleteWorkout(context, ref, workout),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            minimum: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.lg,
            ),
            child: FilledButton(
              onPressed: () {
                ref
                    .read(activeWorkoutControllerProvider.notifier)
                    .startWithWorkout(workout, planId, planSnapshot: plan);
                context.go('/active');
              },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
              ),
              child: const Text('START'),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            children: <Widget>[
              _WorkoutHero(workout: workout),
              const SizedBox(height: AppSpacing.xl),
              _StatsRow(
                duration: formatClockDuration(estimatedSeconds),
                moveCount: countWorkoutMoves(workout),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                child: Text(
                  optionalText(plan.description) ??
                      'Review the blocks, laps, moves, and sets before you start.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              const Divider(height: 1),
              const SizedBox(height: AppSpacing.xl),
              ...workout.sets.map((WorkoutSet set) {
                return _SetPreview(
                  set: set,
                  movesById: movesById,
                );
              }),
            ],
          ),
        );
      },
    );
  }

  Future<void> _deleteWorkout(
    BuildContext context,
    WidgetRef ref,
    Workout workout,
  ) async {
    final bool shouldDelete =
        await _confirmDeleteWorkout(context, workout.title);
    if (!shouldDelete || !context.mounted) {
      return;
    }

    try {
      await ref.read(loadedWorkoutPlansNotifierProvider.notifier).removeWorkout(
            planId: planId,
            workoutId: workout.workoutId,
          );
      if (!context.mounted) {
        return;
      }
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      context.go('/library/detail/$planId');
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Workout deleted. Saved history is kept.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting workout: $error')),
      );
    }
  }
}

WorkoutPlan _singleWorkoutPlan(WorkoutPlan plan, Workout workout) {
  return plan.copyWith(
    planId: '${plan.planId}-${workout.workoutId}',
    name: workout.title,
    imageUrl: workout.imageUrl ?? plan.imageUrl,
    workouts: <Workout>[workout],
    moves: plan.moves
        .where((Move planMove) => workout.sets.any(
              (WorkoutSet set) => set.moves.any(
                (WorkoutMove workoutMove) =>
                    workoutMove.moveId == planMove.moveId,
              ),
            ))
        .toList(growable: false),
  );
}

Future<bool> _confirmDeleteWorkout(
  BuildContext context,
  String workoutName,
) async {
  return confirmDestructiveAction(
    context,
    title: 'Delete Workout?',
    message:
        'Delete "$workoutName" from this plan? Saved workout history will stay available.',
    confirmLabel: 'Delete',
  );
}

class _WorkoutHero extends StatelessWidget {
  const _WorkoutHero({required this.workout});

  final Workout workout;

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = optionalText(workout.imageUrl);
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Column(
      children: <Widget>[
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.md),
          child: ColoredBox(
            color: colors.primaryContainer,
            child: SizedBox(
              width: double.infinity,
              height: 180,
              child: imageUrl == null
                  ? Icon(
                      Icons.fitness_center,
                      color: colors.onPrimaryContainer,
                      size: 56,
                    )
                  : MoveMediaImage(
                      source: imageUrl,
                      fit: BoxFit.cover,
                      errorPlaceholder: Icon(
                        Icons.fitness_center,
                        color: colors.onPrimaryContainer,
                        size: 56,
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          workout.title,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({
    required this.duration,
    required this.moveCount,
  });

  final String duration;
  final int moveCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _SummaryStat(
            label: 'Est. duration',
            value: duration,
          ),
        ),
        Expanded(
          child: _SummaryStat(
            label: 'Moves',
            value: '$moveCount',
          ),
        ),
      ],
    );
  }
}

class _SummaryStat extends StatelessWidget {
  const _SummaryStat({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
              ),
        ),
      ],
    );
  }
}

class _SetPreview extends StatelessWidget {
  const _SetPreview({
    required this.set,
    required this.movesById,
  });

  final WorkoutSet set;
  final Map<String, Move> movesById;

  @override
  Widget build(BuildContext context) {
    final String? setName = optionalText(set.name);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              if (setName != null)
                Expanded(
                  child: Text(
                    setName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                )
              else
                const Spacer(),
              if (set.lapCount > 1) _LapBadge(lapCount: set.lapCount),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...set.moves.map((WorkoutMove workoutMove) {
            final Move? move = movesById[workoutMove.moveId];
            return _MovePreviewRow(
              workoutMove: workoutMove,
              move: move,
            );
          }),
        ],
      ),
    );
  }
}

class _LapBadge extends StatelessWidget {
  const _LapBadge({required this.lapCount});

  final int lapCount;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          'x$lapCount Laps',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ),
    );
  }
}

class _MovePreviewRow extends StatelessWidget {
  const _MovePreviewRow({
    required this.workoutMove,
    required this.move,
  });

  final WorkoutMove workoutMove;
  final Move? move;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String moveName = move?.name ?? 'Unknown Move';
    final String? imageUrl = optionalText(move?.imageUrl);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          MediaThumbnail(
            imageUrl: imageUrl,
            fallbackIcon: Icons.fitness_center,
            backgroundColor: colors.surfaceContainerHighest,
            iconColor: colors.onSurfaceVariant,
            dimension: 56,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(
              moveName,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _MoveTargetBadge(label: formatMoveTarget(workoutMove)),
        ],
      ),
    );
  }
}

class _MoveTargetBadge extends StatelessWidget {
  const _MoveTargetBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: Theme.of(context).colorScheme.onPrimary,
                fontWeight: FontWeight.w800,
              ),
        ),
      ),
    );
  }
}
