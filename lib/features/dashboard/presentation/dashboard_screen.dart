import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/core/media/exercise_media_image.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_metrics.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

enum _HomeListMode {
  workouts,
  plans,
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  _HomeListMode _listMode = _HomeListMode.workouts;

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final String greeting = switch (now.hour) {
      >= 5 && < 12 => 'Good Morning,',
      >= 12 && < 17 => 'Good Afternoon,',
      _ => 'Good Evening,',
    };

    // Compute weekly stats from live session data
    final AsyncValue<List<WorkoutSessionEntity>> sessionsAsync =
        ref.watch(allSessionsProvider);
    final List<WorkoutSessionEntity> sessions =
        sessionsAsync.value ?? <WorkoutSessionEntity>[];
    final AsyncValue<List<WorkoutPlan>> plansState =
        ref.watch(loadedWorkoutPlansNotifierProvider);

    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime startOfWeek =
        today.subtract(Duration(days: today.weekday - 1));
    final int startOfWeekMs = startOfWeek.millisecondsSinceEpoch;

    int weeklyWorkouts = 0;
    int weeklyDurationSeconds = 0;
    for (final WorkoutSessionEntity session in sessions) {
      if (session.status == 'completed' && session.startedAt >= startOfWeekMs) {
        weeklyWorkouts += 1;
        weeklyDurationSeconds += session.durationSeconds;
      }
    }
    final int weeklyMinutes = (weeklyDurationSeconds / 60).round();

    return ListView(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl, vertical: AppSpacing.xxl),
      children: <Widget>[
        Text(
          greeting,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: -1.0,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Ready to crush your goals today?',
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: AppSpacing.xxl),
        Row(
          children: <Widget>[
            Expanded(
              child: _StatCard(
                title: 'Workouts',
                value: '$weeklyWorkouts',
                subtitle: 'This Week',
                icon: Icons.local_fire_department_rounded,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _StatCard(
                title: 'Active Time',
                value: '$weeklyMinutes',
                subtitle: 'Minutes',
                icon: Icons.timer_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xxl),
        _HomeModeToggle(
          selectedMode: _listMode,
          onChanged: (Set<_HomeListMode> selected) {
            setState(() {
              _listMode = selected.first;
            });
          },
        ),
        const SizedBox(height: AppSpacing.lg),
        plansState.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (Object error, StackTrace stack) =>
              Text('Error loading plans: $error'),
          data: (List<WorkoutPlan> plans) {
            if (_listMode == _HomeListMode.workouts) {
              final List<_WorkoutListItem> workouts =
                  _recentWorkoutItems(plans, sessions);
              if (workouts.isEmpty) {
                return const _EmptyHomeState(
                  message: 'Create or import a plan to see workouts here.',
                );
              }
              return Column(
                children: workouts.map((_WorkoutListItem item) {
                  return _WorkoutCard(
                    item: item,
                    onTap: () => context.go(
                      '/library/detail/${item.plan.planId}/workout/${item.workout.workoutId}',
                    ),
                  );
                }).toList(growable: false),
              );
            }

            if (plans.isEmpty) {
              return const _EmptyHomeState(
                message: 'Import or create your first plan.',
              );
            }
            return Column(
              children: plans.map((WorkoutPlan plan) {
                return _PlanCard(
                  plan: plan,
                  onTap: () => context.go('/library/detail/${plan.planId}'),
                );
              }).toList(growable: false),
            );
          },
        ),
        const SizedBox(height: AppSpacing.xxl),
        Text(
          'Quick Actions',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
        const SizedBox(height: AppSpacing.md),
        FilledButton.tonalIcon(
          onPressed: () async {
            final FilePickerResult? result =
                await FilePicker.platform.pickFiles(
              type: FileType.custom,
              allowedExtensions: ['json'],
              withData: true,
            );

            if (result != null && result.files.single.bytes != null) {
              try {
                final String jsonString =
                    utf8.decode(result.files.single.bytes!);
                final WorkoutPlan plan = await ref
                    .read(workoutPlanImportServiceProvider)
                    .importFromJsonString(jsonString);

                // Invalidate the loaded plans so the library re-fetches from the database
                ref.invalidate(loadedWorkoutPlansNotifierProvider);

                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text('Successfully imported ${plan.name}')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error importing workout: $e')),
                  );
                }
              }
            }
          },
          icon: const Icon(Icons.download_rounded),
          label: const Text('Import Workout JSON'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.all(AppSpacing.lg),
            alignment: Alignment.centerLeft,
          ),
        ),
      ],
    );
  }

  List<_WorkoutListItem> _recentWorkoutItems(
    List<WorkoutPlan> plans,
    List<WorkoutSessionEntity> sessions,
  ) {
    final Map<String, int> latestStartedAtByWorkoutId = <String, int>{};
    for (final WorkoutSessionEntity session in sessions) {
      if (session.status != 'completed') {
        continue;
      }
      final int? currentLatest = latestStartedAtByWorkoutId[session.workoutId];
      if (currentLatest == null || session.startedAt > currentLatest) {
        latestStartedAtByWorkoutId[session.workoutId] = session.startedAt;
      }
    }

    final List<_WorkoutListItem> items = <_WorkoutListItem>[
      for (final WorkoutPlan plan in plans)
        for (final Workout workout in plan.workouts)
          _WorkoutListItem(
            plan: plan,
            workout: workout,
            latestStartedAt: latestStartedAtByWorkoutId[workout.workoutId],
          ),
    ];

    items.sort((_WorkoutListItem a, _WorkoutListItem b) {
      final int latestComparison =
          (b.latestStartedAt ?? -1).compareTo(a.latestStartedAt ?? -1);
      if (latestComparison != 0) {
        return latestComparison;
      }
      return a.workout.title.compareTo(b.workout.title);
    });
    return items;
  }
}

class _HomeModeToggle extends StatelessWidget {
  const _HomeModeToggle({
    required this.selectedMode,
    required this.onChanged,
  });

  final _HomeListMode selectedMode;
  final ValueChanged<Set<_HomeListMode>> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_HomeListMode>(
      segments: const <ButtonSegment<_HomeListMode>>[
        ButtonSegment<_HomeListMode>(
          value: _HomeListMode.workouts,
          label: Text('My Workouts'),
          icon: Icon(Icons.fitness_center),
        ),
        ButtonSegment<_HomeListMode>(
          value: _HomeListMode.plans,
          label: Text('My Plans'),
          icon: Icon(Icons.library_books_outlined),
        ),
      ],
      selected: <_HomeListMode>{selectedMode},
      onSelectionChanged: onChanged,
    );
  }
}

class _WorkoutListItem {
  const _WorkoutListItem({
    required this.plan,
    required this.workout,
    required this.latestStartedAt,
  });

  final WorkoutPlan plan;
  final Workout workout;
  final int? latestStartedAt;
}

class _WorkoutCard extends StatelessWidget {
  const _WorkoutCard({
    required this.item,
    required this.onTap,
  });

  final _WorkoutListItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Workout workout = item.workout;
    final ColorScheme colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              _MediaThumbnail(
                imageUrl: optionalText(workout.imageUrl),
                fallbackIcon: Icons.fitness_center,
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
                              estimateWorkoutSeconds(workout),
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
                      item.plan.name,
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
                Icons.play_arrow_rounded,
                color: colors.primary,
                size: 32,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.onTap,
  });

  final WorkoutPlan plan;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final String subtitle = optionalText(plan.description) ??
        '${plan.workouts.length} ${plan.workouts.length == 1 ? 'workout' : 'workouts'}';

    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.md),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              _MediaThumbnail(
                imageUrl: optionalText(plan.imageUrl),
                fallbackIcon: Icons.library_books_outlined,
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      plan.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

class _MediaThumbnail extends StatelessWidget {
  const _MediaThumbnail({
    required this.imageUrl,
    required this.fallbackIcon,
  });

  final String? imageUrl;
  final IconData fallbackIcon;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.sm),
      child: ColoredBox(
        color: colors.primaryContainer,
        child: SizedBox.square(
          dimension: 60,
          child: imageUrl == null
              ? Icon(
                  fallbackIcon,
                  color: colors.onPrimaryContainer,
                )
              : ExerciseMediaImage(
                  source: imageUrl!,
                  fit: BoxFit.cover,
                  errorPlaceholder: Icon(
                    fallbackIcon,
                    color: colors.onPrimaryContainer,
                  ),
                ),
        ),
      ),
    );
  }
}

class _EmptyHomeState extends StatelessWidget {
  const _EmptyHomeState({
    required this.message,
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(message),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.fromBorderSide(
          BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.4),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              Icon(icon, color: colors.primary, size: 24),
              Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: <Widget>[
              Text(
                value,
                style: theme.textTheme.headlineLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.onSurface,
                ),
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(width: AppSpacing.xs),
                Text(
                  subtitle!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
