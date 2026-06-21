import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/history/domain/workout_streak.dart';
import 'package:workout_app_rewrite/features/history/presentation/components/analysis_session_item.dart';
import 'package:workout_app_rewrite/features/history/presentation/components/date_group.dart';
import 'package:workout_app_rewrite/features/history/presentation/components/empty_history.dart';
import 'package:workout_app_rewrite/features/history/presentation/components/workout_heatmap.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

enum _HistoryRange { days30, days90, year, all }

class AnalysisScreen extends ConsumerStatefulWidget {
  const AnalysisScreen({super.key});

  @override
  ConsumerState<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends ConsumerState<AnalysisScreen> {
  String? _workoutId;
  String? _moveId;
  DateTime? _selectedDate;
  _HistoryRange _range = _HistoryRange.days90;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<WorkoutSessionEntity>> sessionsAsync =
        ref.watch(allSessionsProvider);
    final AsyncValue<List<WorkoutPlan>> plansAsync =
        ref.watch(loadedWorkoutPlansNotifierProvider);
    final List<WorkoutMovePerformanceEntity> performances =
        ref.watch(allMovePerformancesProvider).value ??
            const <WorkoutMovePerformanceEntity>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Analysis')),
      body: sessionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object error, StackTrace stack) => _AnalysisError(error: error),
        data: (List<WorkoutSessionEntity> sessions) {
          if (sessions.isEmpty) {
            return EmptyHistory(onStartWorkout: () => context.go('/dashboard'));
          }

          final List<WorkoutPlan> plans =
              plansAsync.value ?? const <WorkoutPlan>[];
          final List<AnalysisSessionItem> allItems =
              _buildSessionItems(sessions, plans);
          final Map<String, String> workoutNames = <String, String>{
            for (final AnalysisSessionItem item in allItems)
              item.session.workoutId: item.workoutName,
          };
          final Map<String, String> moveNames = <String, String>{
            for (final WorkoutPlan plan in plans)
              for (final Move move in plan.moves) move.moveId: move.name,
          };
          final List<AnalysisSessionItem> filtered = _filterItems(
            allItems,
            performances,
          );
          final _AnalysisSummary summary = _buildSummary(allItems);
          final _PersonalRecords records =
              _buildRecords(performances, moveNames);
          final Map<String, List<AnalysisSessionItem>> grouped =
              _groupSessionsByDate(filtered);
          final List<DateTime> workoutDates = allItems
              .where((AnalysisSessionItem item) => item.isCompleted)
              .map((AnalysisSessionItem item) => item.startedAt)
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
              _TrendCard(summary: summary),
              const SizedBox(height: AppSpacing.lg),
              _RecordsCard(records: records),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                decoration: _analysisDecoration(context),
                child: WorkoutHeatmap(
                  workoutDates: workoutDates,
                  daysToShow: 365,
                  selectedDate: _selectedDate,
                  onDateSelected: (DateTime date) {
                    setState(() {
                      _selectedDate =
                          _sameDay(_selectedDate, date) ? null : date;
                    });
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'History',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: AppSpacing.md),
              _AnalysisFilters(
                workoutNames: workoutNames,
                moveNames: moveNames,
                workoutId: _workoutId,
                moveId: _moveId,
                range: _range,
                selectedDate: _selectedDate,
                onWorkoutChanged: (String? value) =>
                    setState(() => _workoutId = value),
                onMoveChanged: (String? value) =>
                    setState(() => _moveId = value),
                onRangeChanged: (_HistoryRange value) => setState(() {
                  _range = value;
                  _selectedDate = null;
                }),
                onClearDate: () => setState(() => _selectedDate = null),
              ),
              if (filtered.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                  child:
                      Center(child: Text('No sessions match these filters.')),
                )
              else
                ...grouped.entries.map(
                  (MapEntry<String, List<AnalysisSessionItem>> entry) =>
                      DateGroup(dateLabel: entry.key, sessions: entry.value),
                ),
            ],
          );
        },
      ),
    );
  }

  List<AnalysisSessionItem> _filterItems(
    List<AnalysisSessionItem> items,
    List<WorkoutMovePerformanceEntity> performances,
  ) {
    final Set<String>? sessionsWithMove = _moveId == null
        ? null
        : performances
            .where(
                (WorkoutMovePerformanceEntity item) => item.moveId == _moveId)
            .map((WorkoutMovePerformanceEntity item) => item.sessionId)
            .toSet();
    final DateTime now = DateTime.now();
    final DateTime? cutoff = switch (_range) {
      _HistoryRange.days30 => now.subtract(const Duration(days: 30)),
      _HistoryRange.days90 => now.subtract(const Duration(days: 90)),
      _HistoryRange.year => now.subtract(const Duration(days: 365)),
      _HistoryRange.all => null,
    };
    return items.where((AnalysisSessionItem item) {
      if (_workoutId != null && item.session.workoutId != _workoutId) {
        return false;
      }
      if (sessionsWithMove != null &&
          !sessionsWithMove.contains(item.session.sessionId)) {
        return false;
      }
      if (_selectedDate != null && !_sameDay(item.startedAt, _selectedDate)) {
        return false;
      }
      if (_selectedDate == null &&
          cutoff != null &&
          item.startedAt.isBefore(cutoff)) {
        return false;
      }
      return true;
    }).toList(growable: false);
  }
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
    String workoutName = optionalText(session.workoutName) ?? 'Unknown Workout';
    if (workoutName == 'Unknown Workout' && plan != null) {
      for (final Workout workout in plan.workouts) {
        if (workout.workoutId == session.workoutId) {
          workoutName = workout.title;
          break;
        }
      }
    }
    return AnalysisSessionItem(
      session: session,
      planName: optionalText(session.planName) ?? plan?.name ?? 'Unknown Plan',
      workoutName: workoutName,
    );
  }).toList(growable: false);
}

Map<String, List<AnalysisSessionItem>> _groupSessionsByDate(
  List<AnalysisSessionItem> sessions,
) {
  final List<AnalysisSessionItem> sorted = List<AnalysisSessionItem>.from(
    sessions,
  )..sort((AnalysisSessionItem a, AnalysisSessionItem b) =>
      b.session.startedAt.compareTo(a.session.startedAt));
  final Map<String, List<AnalysisSessionItem>> grouped =
      <String, List<AnalysisSessionItem>>{};
  for (final AnalysisSessionItem item in sorted) {
    grouped
        .putIfAbsent(formatRelativeDateLabel(item.startedAt),
            () => <AnalysisSessionItem>[])
        .add(item);
  }
  return grouped;
}

_AnalysisSummary _buildSummary(List<AnalysisSessionItem> sessions) {
  final DateTime now = DateTime.now();
  final DateTime today = DateTime(now.year, now.month, now.day);
  final DateTime thisWeek = today.subtract(Duration(days: today.weekday - 1));
  final DateTime lastWeek = thisWeek.subtract(const Duration(days: 7));
  int thisWeekSeconds = 0;
  int lastWeekSeconds = 0;
  final List<DateTime> completedDates = <DateTime>[];
  for (final AnalysisSessionItem item in sessions) {
    if (!item.isCompleted) continue;
    completedDates.add(item.startedAt);
    if (!item.startedAt.isBefore(thisWeek)) {
      thisWeekSeconds += item.session.durationSeconds;
    } else if (!item.startedAt.isBefore(lastWeek)) {
      lastWeekSeconds += item.session.durationSeconds;
    }
  }
  return _AnalysisSummary(
    thisWeekSeconds: thisWeekSeconds,
    lastWeekSeconds: lastWeekSeconds,
    streakDays: calculateCurrentWorkoutStreakDays(completedDates, now: now),
  );
}

_PersonalRecords _buildRecords(
  List<WorkoutMovePerformanceEntity> performances,
  Map<String, String> moveNames,
) {
  WorkoutMovePerformanceEntity? weightRecord;
  WorkoutMovePerformanceEntity? repRecord;
  for (final WorkoutMovePerformanceEntity item in performances) {
    if (item.actualWeight != null &&
        (weightRecord?.actualWeight == null ||
            item.actualWeight! > weightRecord!.actualWeight!)) {
      weightRecord = item;
    }
    if (repRecord == null || item.repCount > repRecord.repCount) {
      repRecord = item;
    }
  }
  return _PersonalRecords(
    weight: weightRecord,
    reps: repRecord,
    moveNames: moveNames,
    weightTrend: _latestTrend(
      performances.where(
        (WorkoutMovePerformanceEntity item) => item.actualWeight != null,
      ),
      moveNames,
      valueFor: (WorkoutMovePerformanceEntity item) => item.actualWeight!,
      formatValue: (double value, WorkoutMovePerformanceEntity item) =>
          '${formatWeight(value)} ${item.actualWeightUnit ?? ''}'.trim(),
    ),
    repTrend: _latestTrend(
      performances.where(
        (WorkoutMovePerformanceEntity item) => item.repCount > 0,
      ),
      moveNames,
      valueFor: (WorkoutMovePerformanceEntity item) => item.repCount.toDouble(),
      formatValue: (double value, WorkoutMovePerformanceEntity item) =>
          '${value.round()} reps',
    ),
  );
}

_PerformanceTrend? _latestTrend(
  Iterable<WorkoutMovePerformanceEntity> performances,
  Map<String, String> moveNames, {
  required double Function(WorkoutMovePerformanceEntity item) valueFor,
  required String Function(
    double value,
    WorkoutMovePerformanceEntity item,
  ) formatValue,
}) {
  final Map<String, List<WorkoutMovePerformanceEntity>> byMove =
      <String, List<WorkoutMovePerformanceEntity>>{};
  for (final WorkoutMovePerformanceEntity item in performances) {
    byMove
        .putIfAbsent(item.moveId, () => <WorkoutMovePerformanceEntity>[])
        .add(item);
  }
  final List<List<WorkoutMovePerformanceEntity>> candidates = byMove.values
      .where((List<WorkoutMovePerformanceEntity> items) => items.length >= 2)
      .toList(growable: false);
  for (final List<WorkoutMovePerformanceEntity> items in candidates) {
    items.sort(
        (WorkoutMovePerformanceEntity a, WorkoutMovePerformanceEntity b) =>
            b.completedAt.compareTo(a.completedAt));
  }
  candidates.sort((List<WorkoutMovePerformanceEntity> a,
          List<WorkoutMovePerformanceEntity> b) =>
      b.first.completedAt.compareTo(a.first.completedAt));
  if (candidates.isEmpty) return null;
  final WorkoutMovePerformanceEntity current = candidates.first[0];
  final WorkoutMovePerformanceEntity previous = candidates.first[1];
  final double currentValue = valueFor(current);
  final double difference = currentValue - valueFor(previous);
  final String direction = difference == 0
      ? 'unchanged'
      : difference > 0
          ? 'up ${formatValue(difference, current)}'
          : 'down ${formatValue(difference.abs(), current)}';
  return _PerformanceTrend(
    moveName: moveNames[current.moveId] ?? 'Unknown move',
    currentValue: formatValue(currentValue, current),
    direction: direction,
  );
}

class _AnalysisSummary {
  const _AnalysisSummary({
    required this.thisWeekSeconds,
    required this.lastWeekSeconds,
    required this.streakDays,
  });

  final int thisWeekSeconds;
  final int lastWeekSeconds;
  final int streakDays;
}

class _PersonalRecords {
  const _PersonalRecords({
    required this.weight,
    required this.reps,
    required this.moveNames,
    required this.weightTrend,
    required this.repTrend,
  });

  final WorkoutMovePerformanceEntity? weight;
  final WorkoutMovePerformanceEntity? reps;
  final Map<String, String> moveNames;
  final _PerformanceTrend? weightTrend;
  final _PerformanceTrend? repTrend;
}

class _PerformanceTrend {
  const _PerformanceTrend({
    required this.moveName,
    required this.currentValue,
    required this.direction,
  });

  final String moveName;
  final String currentValue;
  final String direction;
}

class _AnalysisFilters extends StatelessWidget {
  const _AnalysisFilters({
    required this.workoutNames,
    required this.moveNames,
    required this.workoutId,
    required this.moveId,
    required this.range,
    required this.selectedDate,
    required this.onWorkoutChanged,
    required this.onMoveChanged,
    required this.onRangeChanged,
    required this.onClearDate,
  });

  final Map<String, String> workoutNames;
  final Map<String, String> moveNames;
  final String? workoutId;
  final String? moveId;
  final _HistoryRange range;
  final DateTime? selectedDate;
  final ValueChanged<String?> onWorkoutChanged;
  final ValueChanged<String?> onMoveChanged;
  final ValueChanged<_HistoryRange> onRangeChanged;
  final VoidCallback onClearDate;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: workoutId ?? '',
                decoration: const InputDecoration(
                  labelText: 'Workout',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem(value: '', child: Text('All')),
                  ...workoutNames.entries.map(
                    (MapEntry<String, String> entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (String? value) => onWorkoutChanged(
                    value == null || value.isEmpty ? null : value),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: moveId ?? '',
                decoration: const InputDecoration(
                  labelText: 'Move',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: <DropdownMenuItem<String>>[
                  const DropdownMenuItem(value: '', child: Text('All')),
                  ...moveNames.entries.map(
                    (MapEntry<String, String> entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                ],
                onChanged: (String? value) => onMoveChanged(
                    value == null || value.isEmpty ? null : value),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<_HistoryRange>(
            segments: const <ButtonSegment<_HistoryRange>>[
              ButtonSegment(value: _HistoryRange.days30, label: Text('30d')),
              ButtonSegment(value: _HistoryRange.days90, label: Text('90d')),
              ButtonSegment(value: _HistoryRange.year, label: Text('1y')),
              ButtonSegment(value: _HistoryRange.all, label: Text('All')),
            ],
            selected: <_HistoryRange>{range},
            onSelectionChanged: (Set<_HistoryRange> value) =>
                onRangeChanged(value.first),
          ),
        ),
        if (selectedDate != null) ...<Widget>[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.centerLeft,
            child: InputChip(
              label: Text(formatRelativeDateLabel(selectedDate!)),
              onDeleted: onClearDate,
            ),
          ),
        ],
      ],
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  const _SummaryGrid({required this.summary});

  final _AnalysisSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _SummaryCard(
            label: 'Active time',
            value: formatDuration(
              summary.thisWeekSeconds,
              zeroLabel: '0m',
              includeSeconds: false,
              omitZeroMinuteRemainder: true,
            ),
            detail: 'This week',
            icon: Icons.timer_outlined,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _SummaryCard(
            label: 'Streak',
            value: '${summary.streakDays}',
            detail: summary.streakDays == 1 ? 'Day' : 'Days',
            icon: Icons.auto_awesome_outlined,
          ),
        ),
      ],
    );
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
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: _analysisDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colors.onSurfaceVariant),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          Text(detail, style: TextStyle(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _TrendCard extends StatelessWidget {
  const _TrendCard({required this.summary});

  final _AnalysisSummary summary;

  @override
  Widget build(BuildContext context) {
    final int difference = summary.thisWeekSeconds - summary.lastWeekSeconds;
    final bool up = difference >= 0;
    final String comparison = summary.lastWeekSeconds == 0
        ? (summary.thisWeekSeconds == 0
            ? 'No active time recorded this week.'
            : 'You started building activity this week.')
        : '${formatDuration(difference.abs(), includeSeconds: false)} ${up ? 'more' : 'less'} active time than last week.';
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _analysisDecoration(context),
      child: Row(
        children: <Widget>[
          Icon(
            up ? Icons.trending_up : Icons.trending_down,
            color: up ? colors.primary : colors.error,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(comparison)),
        ],
      ),
    );
  }
}

class _RecordsCard extends StatelessWidget {
  const _RecordsCard({required this.records});

  final _PersonalRecords records;

  @override
  Widget build(BuildContext context) {
    if (records.weight == null && records.reps == null) {
      return const SizedBox.shrink();
    }
    final WorkoutMovePerformanceEntity? weight = records.weight;
    final WorkoutMovePerformanceEntity? reps = records.reps;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _analysisDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Personal records',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          if (weight != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _RecordRow(
              icon: Icons.monitor_weight_outlined,
              label: records.moveNames[weight.moveId] ?? 'Weight',
              value:
                  '${formatWeight(weight.actualWeight!)} ${weight.actualWeightUnit ?? ''}'
                      .trim(),
            ),
          ],
          if (reps != null) ...<Widget>[
            const SizedBox(height: AppSpacing.md),
            _RecordRow(
              icon: Icons.repeat,
              label: records.moveNames[reps.moveId] ?? 'Repetitions',
              value: '${reps.repCount} reps',
            ),
          ],
          if (records.weightTrend != null ||
              records.repTrend != null) ...<Widget>[
            const Divider(height: AppSpacing.xxl),
            Text(
              'Recent trends',
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            if (records.weightTrend
                case final _PerformanceTrend trend) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _TrendRow(icon: Icons.monitor_weight_outlined, trend: trend),
            ],
            if (records.repTrend
                case final _PerformanceTrend trend) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              _TrendRow(icon: Icons.repeat, trend: trend),
            ],
          ],
        ],
      ),
    );
  }
}

class _TrendRow extends StatelessWidget {
  const _TrendRow({required this.icon, required this.trend});

  final IconData icon;
  final _PerformanceTrend trend;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    return Row(
      children: <Widget>[
        Icon(icon, color: colors.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(trend.moveName),
              Text(
                trend.direction,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
            ],
          ),
        ),
        Text(
          trend.currentValue,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ],
    );
  }
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(child: Text(label)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _AnalysisError extends StatelessWidget {
  const _AnalysisError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: AppSpacing.md),
            const Text('Error loading history'),
            const SizedBox(height: AppSpacing.sm),
            Text(error.toString(), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

BoxDecoration _analysisDecoration(BuildContext context) {
  final ColorScheme colors = Theme.of(context).colorScheme;
  return BoxDecoration(
    color: colors.surfaceContainerHighest.withValues(alpha: 0.15),
    borderRadius: BorderRadius.circular(AppRadii.lg),
    border: Border.all(color: colors.outlineVariant.withValues(alpha: 0.35)),
  );
}

bool _sameDay(DateTime? first, DateTime? second) {
  return first != null &&
      second != null &&
      first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}
