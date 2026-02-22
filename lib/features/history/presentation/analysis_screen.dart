import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/history/presentation/components/analysis_session_item.dart';
import 'package:workout_app_rewrite/features/history/presentation/components/date_group.dart';
import 'package:workout_app_rewrite/features/history/presentation/components/empty_history.dart';
import 'package:workout_app_rewrite/features/history/presentation/components/workout_heatmap.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<WorkoutSessionEntity>> sessionsAsync = ref.watch(allSessionsProvider);
    final AsyncValue<List<WorkoutPlan>> plansAsync = ref.watch(loadedWorkoutPlansNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Export is not available yet.')),
              );
            },
          ),
        ],
      ),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
              const SizedBox(height: AppSpacing.md),
              const Text('Error loading history'),
              const SizedBox(height: AppSpacing.sm),
              Text(error.toString(), style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
        data: (List<WorkoutSessionEntity> sessions) {
          if (sessions.isEmpty) {
            return EmptyHistory(
              onStartWorkout: () {
                context.go('/library');
              },
            );
          }

          final List<WorkoutPlan> plans = plansAsync.value ?? <WorkoutPlan>[];
          final List<AnalysisSessionItem> sessionItems = _buildSessionItems(sessions, plans);
          final Map<String, List<AnalysisSessionItem>> groupedSessions = _groupSessionsByDate(sessionItems);
          final _AnalysisSummary summary = _buildSummary(sessionItems);
          final List<DateTime> workoutDates = sessionItems
              .where((AnalysisSessionItem s) => s.isCompleted)
              .map((AnalysisSessionItem s) => s.startedAt)
              .toList(growable: false);

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl,
              AppSpacing.md,
              AppSpacing.xl,
              AppSpacing.xxl,
            ),
            children: <Widget>[
              _SummaryGrid(summary: summary),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.fromBorderSide(
                    BorderSide(
                      color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: WorkoutHeatmap(workoutDates: workoutDates, daysToShow: 365),
              ),
              if (plansAsync.isLoading) ...<Widget>[
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'Loading workout metadata...',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
              ...groupedSessions.entries.map((MapEntry<String, List<AnalysisSessionItem>> entry) {
                return DateGroup(
                  dateLabel: entry.key,
                  sessions: entry.value,
                );
              }),
            ],
          );
        },
      ),
    );
  }

  List<AnalysisSessionItem> _buildSessionItems(
    List<WorkoutSessionEntity> sessions,
    List<WorkoutPlan> plans,
  ) {
    final Map<String, WorkoutPlan> plansById = <String, WorkoutPlan>{
      for (final WorkoutPlan plan in plans) plan.planId: plan,
    };

    return sessions.map((WorkoutSessionEntity session) {
      final WorkoutPlan? plan = plansById[session.planId];
      String workoutName = 'Unknown Workout';

      if (plan != null) {
        for (final Workout workout in plan.workouts) {
          if (workout.workoutId == session.workoutId) {
            workoutName = workout.title;
            break;
          }
        }
      }

      return AnalysisSessionItem(
        session: session,
        planName: plan?.name ?? 'Unknown Plan',
        workoutName: workoutName,
      );
    }).toList(growable: false);
  }

  Map<String, List<AnalysisSessionItem>> _groupSessionsByDate(List<AnalysisSessionItem> sessions) {
    final Map<String, List<AnalysisSessionItem>> grouped = <String, List<AnalysisSessionItem>>{};
    final List<AnalysisSessionItem> sorted = List<AnalysisSessionItem>.from(sessions)
      ..sort((AnalysisSessionItem a, AnalysisSessionItem b) => b.session.startedAt.compareTo(a.session.startedAt));

    for (final AnalysisSessionItem session in sorted) {
      final DateTime date = session.startedAt;
      final String label = _getDateLabel(date);

      grouped.putIfAbsent(label, () => <AnalysisSessionItem>[]);
      grouped[label]!.add(session);
    }

    return grouped;
  }

  _AnalysisSummary _buildSummary(List<AnalysisSessionItem> sessions) {
    int completedSessions = 0;
    int weeklyCompletedSessions = 0;
    int weeklyDurationSeconds = 0;

    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime startOfWeek = today.subtract(Duration(days: today.weekday - 1));

    for (final AnalysisSessionItem item in sessions) {
      if (!item.isCompleted) {
        continue;
      }
      completedSessions += 1;
      if (item.startedAt.isAfter(startOfWeek.subtract(const Duration(milliseconds: 1)))) {
        weeklyCompletedSessions += 1;
        weeklyDurationSeconds += item.session.durationSeconds;
      }
    }

    final int streakDays = _calculateCurrentStreakDays(
      sessions.where((AnalysisSessionItem item) => item.isCompleted).toList(growable: false),
    );

    return _AnalysisSummary(
      totalSessions: sessions.length,
      completedSessions: completedSessions,
      weeklyCompletedSessions: weeklyCompletedSessions,
      weeklyDurationSeconds: weeklyDurationSeconds,
      streakDays: streakDays,
    );
  }

  int _calculateCurrentStreakDays(List<AnalysisSessionItem> completedSessions) {
    final Set<DateTime> workoutDays = completedSessions
        .map((AnalysisSessionItem item) {
          final DateTime date = item.startedAt;
          return DateTime(date.year, date.month, date.day);
        })
        .toSet();

    if (workoutDays.isEmpty) {
      return 0;
    }

    DateTime latestDay = workoutDays.first;
    for (final DateTime day in workoutDays) {
      if (day.isAfter(latestDay)) {
        latestDay = day;
      }
    }

    int streak = 0;
    DateTime cursor = latestDay;
    while (workoutDays.contains(cursor)) {
      streak += 1;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _getDateLabel(DateTime date) {
    final DateTime now = DateTime.now();
    final DateTime today = DateTime(now.year, now.month, now.day);
    final DateTime sessionDate = DateTime(date.year, date.month, date.day);

    final int difference = today.difference(sessionDate).inDays;

    if (difference == 0) {
      return 'Today';
    }
    if (difference == 1) {
      return 'Yesterday';
    }
    if (difference < 7) {
      return _getWeekdayName(date.weekday);
    }
    
    return '${_getMonthName(date.month)} ${date.day}, ${date.year}';
  }

  String _getWeekdayName(int weekday) {
    const List<String> names = <String>['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return names[weekday - 1];
  }

  String _getMonthName(int month) {
    const List<String> names = <String>['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }
}

class _AnalysisSummary {
  const _AnalysisSummary({
    required this.totalSessions,
    required this.completedSessions,
    required this.weeklyCompletedSessions,
    required this.weeklyDurationSeconds,
    required this.streakDays,
  });

  final int totalSessions;
  final int completedSessions;
  final int weeklyCompletedSessions;
  final int weeklyDurationSeconds;
  final int streakDays;
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final _AnalysisSummary summary;

  @override
  Widget build(BuildContext context) {
    final int completionPercent = summary.totalSessions == 0
        ? 0
        : ((summary.completedSessions / summary.totalSessions) * 100).round();

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.md,
      children: <Widget>[
        _SummaryCard(
          label: 'Workouts',
          value: '${summary.weeklyCompletedSessions}',
          detail: 'This Week',
          icon: Icons.local_fire_department_rounded,
        ),
        _SummaryCard(
          label: 'Active Time',
          value: _formatDuration(summary.weeklyDurationSeconds),
          detail: 'This Week',
          icon: Icons.timer_outlined,
        ),
        _SummaryCard(
          label: 'Completion',
          value: '$completionPercent%',
          detail: '${summary.completedSessions}/${summary.totalSessions} sessions',
          icon: Icons.flag_circle_outlined,
        ),
        _SummaryCard(
          label: 'Streak',
          value: '${summary.streakDays}d',
          detail: 'Current',
          icon: Icons.auto_awesome_outlined,
        ),
      ].map((Widget card) {
        return SizedBox(
          width: (MediaQuery.sizeOf(context).width - (AppSpacing.xl * 2) - AppSpacing.md) / 2,
          child: card,
        );
      }).toList(growable: false),
    );
  }

  static String _formatDuration(int seconds) {
    if (seconds <= 0) {
      return '0m';
    }
    final Duration duration = Duration(seconds: seconds);
    if (duration.inHours == 0) {
      return '${duration.inMinutes}m';
    }
    final int minutesRemainder = duration.inMinutes.remainder(60);
    if (minutesRemainder == 0) {
      return '${duration.inHours}h';
    }
    return '${duration.inHours}h ${minutesRemainder}m';
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
  });

  final String label;
  final String value;
  final String detail;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.fromBorderSide(
          BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            detail,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
