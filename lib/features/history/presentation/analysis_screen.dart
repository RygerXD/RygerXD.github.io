import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/history/presentation/components/workout_heatmap.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class AnalysisScreen extends ConsumerWidget {
  const AnalysisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<WorkoutSessionEntity>> sessionsAsync = ref.watch(allSessionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis'),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            onPressed: () {
              // TODO: Export history
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
            return const Center(child: Text('No workout history found.'));
          }

          final List<DateTime> workoutDates = sessions
              .where((WorkoutSessionEntity s) => s.status == 'completed')
              .map((WorkoutSessionEntity s) => DateTime.fromMillisecondsSinceEpoch(s.startedAt))
              .toList();

          return Column(
            children: <Widget>[
              Container(
                margin: const EdgeInsets.all(AppSpacing.xl),
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
                child: WorkoutHeatmap(workoutDates: workoutDates),
              ),
              Expanded(
                child: _buildSessionList(ref, sessions),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSessionList(WidgetRef ref, List<WorkoutSessionEntity> sessions) {
    final Map<String, List<WorkoutSessionEntity>> groupedSessions = _groupSessionsByDate(sessions);
    final List<WorkoutPlan> plans = ref.read(loadedWorkoutPlansNotifierProvider).value ?? <WorkoutPlan>[];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.lg),
      itemCount: groupedSessions.length,
      itemBuilder: (BuildContext context, int index) {
        final MapEntry<String, List<WorkoutSessionEntity>> entry = groupedSessions.entries.elementAt(index);
        final String dateLabel = entry.key;
        final List<WorkoutSessionEntity> daySessions = entry.value;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
              child: Text(
                dateLabel,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: Theme.of(context).colorScheme.primary,
                      letterSpacing: 0.5,
                      height: 1.2,
                    ),
              ),
            ),
            ...daySessions.map((WorkoutSessionEntity session) {
              final WorkoutPlan? plan = plans.where((WorkoutPlan p) => p.planId == session.planId).firstOrNull;
              final Workout? workout = plan?.workouts.where((Workout w) => w.workoutId == session.workoutId).firstOrNull;

              final String planName = plan?.name ?? 'Unknown Plan';
              final String workoutTitle = workout?.title ?? 'Unknown Workout';
              final Duration duration = Duration(seconds: session.durationSeconds);
              final String timeString = '${duration.inMinutes}m ${duration.inSeconds % 60}s';

              final ThemeData theme = Theme.of(context);
              final ColorScheme colors = theme.colorScheme;
              final bool isComplete = session.status == 'completed';

              return Container(
                margin: const EdgeInsets.only(bottom: AppSpacing.md),
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(AppRadii.lg),
                  border: Border.fromBorderSide(
                    BorderSide(
                      color: colors.outlineVariant.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isComplete ? colors.primaryContainer : colors.errorContainer,
                        borderRadius: BorderRadius.circular(AppRadii.md),
                      ),
                      child: Icon(
                        isComplete ? Icons.check_circle_outline_rounded : Icons.cancel_outlined,
                        color: isComplete ? colors.primary : colors.error,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            workoutTitle,
                            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            planName,
                            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      timeString,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: AppSpacing.md),
          ],
        );
      },
    );
  }

  Map<String, List<WorkoutSessionEntity>> _groupSessionsByDate(List<WorkoutSessionEntity> sessions) {
    final Map<String, List<WorkoutSessionEntity>> grouped = <String, List<WorkoutSessionEntity>>{};
    
    // Sort newest first
    final List<WorkoutSessionEntity> sorted = List<WorkoutSessionEntity>.from(sessions)..sort((WorkoutSessionEntity a, WorkoutSessionEntity b) => b.startedAt.compareTo(a.startedAt));

    for (final WorkoutSessionEntity session in sorted) {
      final DateTime date = DateTime.fromMillisecondsSinceEpoch(session.startedAt);
      final String label = _getDateLabel(date);
      
      grouped.putIfAbsent(label, () => <WorkoutSessionEntity>[]);
      grouped[label]!.add(session);
    }
    
    return grouped;
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
