import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/core/media/media_thumbnail.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/history/domain/workout_time_estimate.dart';
import 'package:workout_app_rewrite/features/moves/presentation/moves_screen.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_metrics.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

enum _LibrarySection { plans, workouts, moves }

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  _LibrarySection _section = _LibrarySection.plans;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<WorkoutPlan>> plansState =
        ref.watch(loadedWorkoutPlansNotifierProvider);
    final List<WorkoutMovePerformanceEntity> performances =
        ref.watch(allMovePerformancesProvider).value ??
            const <WorkoutMovePerformanceEntity>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: SizedBox(
              width: double.infinity,
              child: SegmentedButton<_LibrarySection>(
                segments: const <ButtonSegment<_LibrarySection>>[
                  ButtonSegment<_LibrarySection>(
                    value: _LibrarySection.plans,
                    label: Text('Plans'),
                  ),
                  ButtonSegment<_LibrarySection>(
                    value: _LibrarySection.workouts,
                    label: Text('Workouts'),
                  ),
                  ButtonSegment<_LibrarySection>(
                    value: _LibrarySection.moves,
                    label: Text('Moves'),
                  ),
                ],
                selected: <_LibrarySection>{_section},
                onSelectionChanged: (Set<_LibrarySection> value) {
                  setState(() => _section = value.first);
                },
              ),
            ),
          ),
          Expanded(
            child: plansState.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (Object error, StackTrace stack) =>
                  Center(child: Text('Error loading library: $error')),
              data: (List<WorkoutPlan> plans) => switch (_section) {
                _LibrarySection.plans => _PlansView(plans: plans),
                _LibrarySection.workouts => _WorkoutsView(
                    plans: plans,
                    performances: performances,
                  ),
                _LibrarySection.moves => MovesLibraryView(plans: plans),
              },
            ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _importPlan,
                    icon: const Icon(Icons.download_rounded),
                    label: const Text('Import'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go('/library/create'),
                    icon: const Icon(Icons.add),
                    label: const Text('Create plan'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _importPlan() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: <String>['json'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) {
      return;
    }
    try {
      final WorkoutPlan plan = await ref
          .read(workoutPlanImportServiceProvider)
          .importFromJsonString(utf8.decode(result.files.single.bytes!));
      ref.invalidate(loadedWorkoutPlansNotifierProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Imported ${plan.name}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not import plan: $error')),
        );
      }
    }
  }
}

class _PlansView extends StatelessWidget {
  const _PlansView({required this.plans});

  final List<WorkoutPlan> plans;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    if (plans.isEmpty) {
      return const _LibraryEmptyState(
        icon: Icons.library_books_outlined,
        title: 'No plans yet',
        message: 'Create a plan or import an existing JSON file.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: plans.length,
      itemBuilder: (BuildContext context, int index) {
        final WorkoutPlan plan = plans[index];
        final int workoutCount = plan.workouts
            .where((Workout workout) => !workout.isArchived)
            .length;
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            leading: MediaThumbnail(
              imageUrl: optionalText(plan.imageUrl),
              fallbackIcon: Icons.library_books_outlined,
              backgroundColor: colors.primaryContainer,
              iconColor: colors.onPrimaryContainer,
              dimension: 56,
            ),
            title: Text(
              plan.name,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              optionalText(plan.description) ??
                  '$workoutCount ${workoutCount == 1 ? 'workout' : 'workouts'}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/library/detail/${plan.planId}'),
          ),
        );
      },
    );
  }
}

class _WorkoutsView extends StatelessWidget {
  const _WorkoutsView({required this.plans, required this.performances});

  final List<WorkoutPlan> plans;
  final List<WorkoutMovePerformanceEntity> performances;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final List<(WorkoutPlan, Workout)> workouts = <(WorkoutPlan, Workout)>[
      for (final WorkoutPlan plan in plans)
        for (final Workout workout in plan.workouts)
          if (!workout.isArchived) (plan, workout),
    ];
    if (workouts.isEmpty) {
      return const _LibraryEmptyState(
        icon: Icons.fitness_center,
        title: 'No workouts yet',
        message: 'Add a workout to one of your plans.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: workouts.length,
      itemBuilder: (BuildContext context, int index) {
        final (WorkoutPlan plan, Workout workout) = workouts[index];
        return Card(
          margin: const EdgeInsets.only(bottom: AppSpacing.md),
          child: ListTile(
            contentPadding: const EdgeInsets.all(AppSpacing.md),
            leading: MediaThumbnail(
              imageUrl: optionalText(workout.imageUrl),
              fallbackIcon: Icons.fitness_center,
              backgroundColor: colors.primaryContainer,
              iconColor: colors.onPrimaryContainer,
              dimension: 56,
            ),
            title: Text(
              workout.title,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            subtitle: Text(
              '${plan.name} · ${formatWorkoutEstimate(estimateWorkoutSecondsFromHistory(workout, performances))}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(
              '/library/detail/${plan.planId}/workout/${workout.workoutId}',
            ),
          ),
        );
      },
    );
  }
}

class _LibraryEmptyState extends StatelessWidget {
  const _LibraryEmptyState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 48, color: colors.primary),
            const SizedBox(height: AppSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
