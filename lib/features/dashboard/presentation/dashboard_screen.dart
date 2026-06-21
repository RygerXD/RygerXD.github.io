import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/core/media/media_thumbnail.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/active_workout/application/active_workout_controller.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_phase.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/history/domain/workout_streak.dart';
import 'package:workout_app_rewrite/features/history/domain/workout_time_estimate.dart';
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_metrics.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<WorkoutPlan>> plansState =
        ref.watch(loadedWorkoutPlansNotifierProvider);
    final List<WorkoutSessionEntity> sessions =
        ref.watch(allSessionsProvider).value ?? const <WorkoutSessionEntity>[];
    final List<WorkoutMovePerformanceEntity> performances =
        ref.watch(allMovePerformancesProvider).value ??
            const <WorkoutMovePerformanceEntity>[];
    final AppSettings settings = ref.watch(appSettingsProvider);
    final WorkoutPhase activePhase =
        ref.watch(activeWorkoutControllerProvider).phase;
    final ActiveWorkoutController activeController =
        ref.read(activeWorkoutControllerProvider.notifier);

    return plansState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (Object error, StackTrace stack) =>
          Center(child: Text('Error loading workouts: $error')),
      data: (List<WorkoutPlan> plans) {
        final List<_HomeWorkoutItem> workouts =
            _sortedWorkoutItems(plans, sessions);
        if (workouts.isEmpty) {
          return _FirstRunHome(
            onCreate: () => context.go('/library/create'),
            onImport: () => context.go('/library'),
          );
        }

        final bool hasActiveWorkout = activeController.workout != null &&
            activePhase != WorkoutPhase.idle &&
            activePhase != WorkoutPhase.completed &&
            activePhase != WorkoutPhase.completedEarly &&
            activePhase != WorkoutPhase.abandoned;
        final _HomeWorkoutItem primary = workouts.first;
        final _WeeklyProgress weekly = _weeklyProgress(sessions);
        final int streak = calculateCurrentWorkoutStreakDays(
          sessions
              .where((WorkoutSessionEntity session) =>
                  session.status == 'completed')
              .map((WorkoutSessionEntity session) =>
                  DateTime.fromMillisecondsSinceEpoch(session.startedAt)),
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          children: <Widget>[
            Text(
              hasActiveWorkout ? 'Workout in progress' : 'Up next',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (hasActiveWorkout)
              _ContinueWorkoutCard(
                workoutName: activeController.workout!.title,
                onContinue: () => context.go('/active'),
              )
            else
              _PrimaryWorkoutCard(
                item: primary,
                duration: formatWorkoutEstimate(
                  estimateWorkoutSecondsFromHistory(
                    primary.workout,
                    performances,
                  ),
                ),
                onOpen: () => _openWorkout(context, primary),
                onStart: () => _startWorkout(context, ref, primary),
              ),
            const SizedBox(height: AppSpacing.xl),
            _WeeklyProgressCard(
              completed: weekly.completed,
              goal: settings.streakWorkoutsPerWeek,
              activeMinutes: weekly.activeMinutes,
              streakDays: streak,
            ),
            if (workouts.length > 1) ...<Widget>[
              const SizedBox(height: AppSpacing.xxl),
              Text(
                'Recent workouts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final _HomeWorkoutItem item in workouts.skip(1).take(4))
                _RecentWorkoutCard(
                  item: item,
                  duration: formatWorkoutEstimate(
                    estimateWorkoutSecondsFromHistory(
                      item.workout,
                      performances,
                    ),
                  ),
                  onTap: () => _openWorkout(context, item),
                ),
            ],
            const SizedBox(height: AppSpacing.lg),
            TextButton.icon(
              onPressed: () => context.go('/library'),
              icon: const Icon(Icons.library_books_outlined),
              label: const Text('Open library'),
            ),
          ],
        );
      },
    );
  }

  void _openWorkout(BuildContext context, _HomeWorkoutItem item) {
    context.go(
      '/library/detail/${item.plan.planId}/workout/${item.workout.workoutId}',
    );
  }

  void _startWorkout(
    BuildContext context,
    WidgetRef ref,
    _HomeWorkoutItem item,
  ) {
    ref.read(activeWorkoutControllerProvider.notifier).startWithWorkout(
          item.workout,
          item.plan.planId,
          planSnapshot: item.plan,
        );
    context.go('/active');
  }
}

List<_HomeWorkoutItem> _sortedWorkoutItems(
  List<WorkoutPlan> plans,
  List<WorkoutSessionEntity> sessions,
) {
  final Map<String, int> latestByWorkout = <String, int>{};
  for (final WorkoutSessionEntity session in sessions) {
    if (session.status != 'completed') {
      continue;
    }
    final int current = latestByWorkout[session.workoutId] ?? -1;
    if (session.startedAt > current) {
      latestByWorkout[session.workoutId] = session.startedAt;
    }
  }
  final List<_HomeWorkoutItem> items = <_HomeWorkoutItem>[
    for (final WorkoutPlan plan in plans)
      for (final Workout workout in plan.workouts)
        if (!workout.isArchived)
          _HomeWorkoutItem(
            plan: plan,
            workout: workout,
            latestStartedAt: latestByWorkout[workout.workoutId],
          ),
  ];
  items.sort((_HomeWorkoutItem a, _HomeWorkoutItem b) {
    final int recent =
        (b.latestStartedAt ?? -1).compareTo(a.latestStartedAt ?? -1);
    return recent != 0 ? recent : a.workout.title.compareTo(b.workout.title);
  });
  return items;
}

_WeeklyProgress _weeklyProgress(List<WorkoutSessionEntity> sessions) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final int start =
      today.subtract(Duration(days: today.weekday - 1)).millisecondsSinceEpoch;
  int completed = 0;
  int seconds = 0;
  for (final WorkoutSessionEntity session in sessions) {
    if (session.status == 'completed' && session.startedAt >= start) {
      completed += 1;
      seconds += session.durationSeconds;
    }
  }
  return _WeeklyProgress(
    completed: completed,
    activeMinutes: (seconds / 60).round(),
  );
}

class _HomeWorkoutItem {
  const _HomeWorkoutItem({
    required this.plan,
    required this.workout,
    required this.latestStartedAt,
  });

  final WorkoutPlan plan;
  final Workout workout;
  final int? latestStartedAt;
}

class _WeeklyProgress {
  const _WeeklyProgress({required this.completed, required this.activeMinutes});

  final int completed;
  final int activeMinutes;
}

class _FirstRunHome extends StatelessWidget {
  const _FirstRunHome({required this.onCreate, required this.onImport});

  final VoidCallback onCreate;
  final VoidCallback onImport;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.fitness_center, size: 64, color: colors.primary),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Create your first workout plan',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'A plan contains the workouts and moves you will use during training.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Create first plan'),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onImport,
                icon: const Icon(Icons.download_rounded),
                label: const Text('Import a plan'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryWorkoutCard extends StatelessWidget {
  const _PrimaryWorkoutCard({
    required this.item,
    required this.duration,
    required this.onOpen,
    required this.onStart,
  });

  final _HomeWorkoutItem item;
  final String duration;
  final VoidCallback onOpen;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: <Widget>[
            InkWell(
              onTap: onOpen,
              borderRadius: BorderRadius.circular(AppRadii.md),
              child: Row(
                children: <Widget>[
                  MediaThumbnail(
                    imageUrl: optionalText(item.workout.imageUrl),
                    fallbackIcon: Icons.fitness_center,
                    backgroundColor: colors.primaryContainer,
                    iconColor: colors.onPrimaryContainer,
                    dimension: 72,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          item.workout.title,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${item.plan.name} - $duration',
                          style: TextStyle(color: colors.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Start workout'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContinueWorkoutCard extends StatelessWidget {
  const _ContinueWorkoutCard({
    required this.workoutName,
    required this.onContinue,
  });

  final String workoutName;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Text(
              workoutName,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: onContinue,
              icon: const Icon(Icons.play_arrow_rounded),
              label: const Text('Continue workout'),
            ),
          ],
        ),
      ),
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  const _WeeklyProgressCard({
    required this.completed,
    required this.goal,
    required this.activeMinutes,
    required this.streakDays,
  });

  final int completed;
  final int goal;
  final int activeMinutes;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Weekly goal',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Flexible(
                child: Text(
                  '$completed of $goal workouts',
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          LinearProgressIndicator(
            value: goal == 0 ? 0 : (completed / goal).clamp(0, 1).toDouble(),
            minHeight: 8,
            borderRadius: BorderRadius.circular(AppRadii.pill),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            '$activeMinutes active minutes - $streakDays-day streak',
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _RecentWorkoutCard extends StatelessWidget {
  const _RecentWorkoutCard({
    required this.item,
    required this.duration,
    required this.onTap,
  });

  final _HomeWorkoutItem item;
  final String duration;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ListTile(
        contentPadding: const EdgeInsets.all(AppSpacing.md),
        leading: MediaThumbnail(
          imageUrl: optionalText(item.workout.imageUrl),
          fallbackIcon: Icons.fitness_center,
          backgroundColor: colors.primaryContainer,
          iconColor: colors.onPrimaryContainer,
          dimension: 52,
        ),
        title: Text(
          item.workout.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text('${item.plan.name} - $duration'),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
