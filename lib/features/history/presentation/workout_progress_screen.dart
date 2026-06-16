import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/core/widgets/confirm_destructive_action.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/history/domain/history_workout_snapshot.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_runtime_expansion.dart';

class WorkoutProgressScreen extends ConsumerWidget {
  const WorkoutProgressScreen({
    required this.sessionId,
    super.key,
  });

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<List<WorkoutSessionEntity>> sessionsAsync =
        ref.watch(allSessionsProvider);
    final AsyncValue<List<WorkoutMovePerformanceEntity>> performancesAsync =
        ref.watch(allMovePerformancesProvider);
    final AsyncValue<List<WorkoutPlan>> plansAsync =
        ref.watch(loadedWorkoutPlansNotifierProvider);

    if (sessionsAsync.isLoading || performancesAsync.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final Object? error = sessionsAsync.error ?? performancesAsync.error;
    if (error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout Progress')),
        body: Center(child: Text('Error loading workout progress: $error')),
      );
    }

    final List<WorkoutSessionEntity> sessions =
        sessionsAsync.value ?? <WorkoutSessionEntity>[];
    final List<WorkoutMovePerformanceEntity> performances =
        performancesAsync.value ?? <WorkoutMovePerformanceEntity>[];
    final WorkoutSessionEntity? selectedSession =
        _findSelectedSession(sessions);

    if (selectedSession == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Workout Progress')),
        body: const Center(child: Text('Workout session was not found.')),
      );
    }

    final List<WorkoutPlan> plans = plansAsync.value ?? <WorkoutPlan>[];
    final _WorkoutContext workoutContext =
        _resolveWorkoutContext(selectedSession, plans);
    final List<WorkoutSessionEntity> comparableSessions =
        _comparableSessions(sessions, selectedSession);
    final Set<String> comparableSessionIds = comparableSessions
        .map((WorkoutSessionEntity session) => session.sessionId)
        .toSet();
    final Map<String, WorkoutSessionEntity> sessionsById =
        <String, WorkoutSessionEntity>{
      for (final WorkoutSessionEntity session in comparableSessions)
        session.sessionId: session,
    };
    final List<_MoveSeries> moveSeries = _buildMoveSeries(
      performances: performances
          .where((WorkoutMovePerformanceEntity performance) =>
              performance.workoutId == selectedSession.workoutId &&
              comparableSessionIds.contains(performance.sessionId))
          .toList(growable: false),
      sessionsById: sessionsById,
      selectedSessionId: selectedSession.sessionId,
      workout: workoutContext.workout,
      plan: workoutContext.plan,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Progress'),
        actions: <Widget>[
          IconButton(
            tooltip: 'Delete session',
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _deleteSession(
              context,
              ref,
              selectedSession.sessionId,
              workoutContext.workoutName,
            ),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.md,
          AppSpacing.xl,
          AppSpacing.xxl,
        ),
        children: <Widget>[
          Text(
            workoutContext.workoutName,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${formatDate(_dateFromMs(selectedSession.startedAt))} - ${comparableSessions.length} tracked ${comparableSessions.length == 1 ? 'session' : 'sessions'}',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: AppSpacing.lg),
          if (moveSeries.isEmpty)
            _EmptyMoveHistory(workoutName: workoutContext.workoutName)
          else
            ...moveSeries.map((_MoveSeries series) => Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: _MoveProgressCard(series: series),
                )),
        ],
      ),
    );
  }

  WorkoutSessionEntity? _findSelectedSession(
      List<WorkoutSessionEntity> sessions) {
    for (final WorkoutSessionEntity session in sessions) {
      if (session.sessionId == sessionId) {
        return session;
      }
    }
    return null;
  }

  Future<void> _deleteSession(
    BuildContext context,
    WidgetRef ref,
    String sessionId,
    String workoutName,
  ) async {
    final bool shouldDelete = await _confirmDeleteSession(context, workoutName);
    if (!shouldDelete || !context.mounted) {
      return;
    }

    try {
      await ref.read(historyServiceProvider).deleteSession(sessionId);
      if (!context.mounted) {
        return;
      }
      final ScaffoldMessengerState messenger = ScaffoldMessenger.of(context);
      context.go('/analysis');
      messenger.showSnackBar(
        const SnackBar(content: Text('Workout session deleted.')),
      );
    } catch (error) {
      if (!context.mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting workout session: $error')),
      );
    }
  }
}

Future<bool> _confirmDeleteSession(
  BuildContext context,
  String workoutName,
) async {
  return confirmDestructiveAction(
    context,
    title: 'Delete Workout Session?',
    message: 'Delete this saved "$workoutName" session and its move history?',
  );
}

_WorkoutContext _resolveWorkoutContext(
  WorkoutSessionEntity session,
  List<WorkoutPlan> plans,
) {
  final HistoryWorkoutSnapshot? snapshot =
      decodeHistoryWorkoutSnapshot(session.workoutSnapshotJson);
  if (snapshot != null) {
    return _WorkoutContext(
      plan: snapshot.toWorkoutPlan(),
      workout: snapshot.workout,
      workoutName: optionalText(session.workoutName) ?? snapshot.workout.title,
    );
  }

  for (final WorkoutPlan plan in plans) {
    if (plan.planId != session.planId) {
      continue;
    }
    for (final Workout workout in plan.workouts) {
      if (workout.workoutId == session.workoutId) {
        return _WorkoutContext(
          plan: plan,
          workout: workout,
          workoutName: workout.title,
        );
      }
    }
    return _WorkoutContext(
      plan: plan,
      workout: null,
      workoutName: optionalText(session.workoutName) ?? 'Unknown Workout',
    );
  }
  return _WorkoutContext(
    plan: null,
    workout: null,
    workoutName: optionalText(session.workoutName) ?? 'Unknown Workout',
  );
}

List<WorkoutSessionEntity> _comparableSessions(
  List<WorkoutSessionEntity> sessions,
  WorkoutSessionEntity selectedSession,
) {
  final List<WorkoutSessionEntity> comparable = sessions
      .where((WorkoutSessionEntity session) =>
          session.workoutId == selectedSession.workoutId &&
          session.startedAt <= selectedSession.startedAt &&
          (session.status == 'completed' ||
              session.sessionId == selectedSession.sessionId))
      .toList(growable: false)
    ..sort((WorkoutSessionEntity a, WorkoutSessionEntity b) =>
        a.startedAt.compareTo(b.startedAt));
  return comparable;
}

List<_MoveSeries> _buildMoveSeries({
  required List<WorkoutMovePerformanceEntity> performances,
  required Map<String, WorkoutSessionEntity> sessionsById,
  required String selectedSessionId,
  required Workout? workout,
  required WorkoutPlan? plan,
}) {
  final Map<String, List<_MovePoint>> pointsByKey =
      <String, List<_MovePoint>>{};
  for (final WorkoutMovePerformanceEntity performance in performances) {
    final WorkoutSessionEntity? session = sessionsById[performance.sessionId];
    if (session == null) {
      continue;
    }
    final String key = _moveKey(
      setId: performance.setId,
      lapIndex: performance.lapIndex,
      workoutMoveId: performance.workoutMoveId,
      moveId: performance.moveId,
    );
    pointsByKey.putIfAbsent(key, () => <_MovePoint>[]).add(
          _MovePoint(
            reps: performance.repCount,
            elapsedSeconds: performance.elapsedSeconds,
            actualWeight: performance.actualWeight,
            actualWeightUnit: performance.actualWeightUnit,
            sessionStartedAt: _dateFromMs(session.startedAt),
            isSelected: performance.sessionId == selectedSessionId,
          ),
        );
  }

  for (final List<_MovePoint> points in pointsByKey.values) {
    points.sort((_MovePoint a, _MovePoint b) =>
        a.sessionStartedAt.compareTo(b.sessionStartedAt));
  }

  if (workout == null) {
    final List<_MoveSeries> fallback = pointsByKey.entries
        .map((MapEntry<String, List<_MovePoint>> entry) => _MoveSeries(
              label: entry.key,
              points: entry.value,
              moveType: null,
            ))
        .toList(growable: false)
      ..sort((_MoveSeries a, _MoveSeries b) => a.label.compareTo(b.label));
    return fallback;
  }

  final List<_MoveSeries> series = <_MoveSeries>[];
  final Workout expandedWorkout = expandRepeatedMoveSets(workout);
  for (int setIndex = 0;
      setIndex < expandedWorkout.sets.length;
      setIndex += 1) {
    final WorkoutSet set = expandedWorkout.sets[setIndex];
    for (int lapIndex = 0; lapIndex < set.lapCount; lapIndex += 1) {
      for (int moveIndex = 0; moveIndex < set.moves.length; moveIndex += 1) {
        final WorkoutMove move = set.moves[moveIndex];
        final String key = _moveKey(
          setId: set.setId,
          lapIndex: lapIndex,
          workoutMoveId: move.workoutMoveId,
          moveId: move.moveId,
        );
        final List<_MovePoint>? points = pointsByKey[key];
        if (points == null || points.isEmpty) {
          continue;
        }
        final String moveName = _moveName(move, plan);
        final String setName = set.name?.trim().isNotEmpty == true
            ? set.name!.trim()
            : 'Set ${setIndex + 1}';
        series.add(
          _MoveSeries(
            label: '$moveName - $setName, Lap ${lapIndex + 1}',
            points: points,
            moveType: move.type,
          ),
        );
      }
    }
  }
  return series;
}

String _moveKey({
  required String setId,
  required int lapIndex,
  required String workoutMoveId,
  required String moveId,
}) {
  return '$setId|$lapIndex|$workoutMoveId|$moveId';
}

String _planMoveName(String moveId, WorkoutPlan? plan) {
  if (plan == null) {
    return moveId;
  }
  for (final Move move in plan.moves) {
    if (move.moveId == moveId) {
      return move.name;
    }
  }
  return moveId;
}

String _moveName(WorkoutMove move, WorkoutPlan? plan) {
  final String moveName = _planMoveName(move.moveId, plan);
  return switch (move.side) {
    MoveSide.left => 'Left $moveName',
    MoveSide.right => 'Right $moveName',
    null => moveName,
  };
}

DateTime _dateFromMs(int millisecondsSinceEpoch) {
  return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
}

class _WorkoutContext {
  const _WorkoutContext({
    required this.plan,
    required this.workout,
    required this.workoutName,
  });

  final WorkoutPlan? plan;
  final Workout? workout;
  final String workoutName;
}

class _MoveSeries {
  const _MoveSeries({
    required this.label,
    required this.points,
    required this.moveType,
  });

  final String label;
  final List<_MovePoint> points;
  final MoveType? moveType;

  bool get hasWeight =>
      points.any((_MovePoint point) => point.actualWeight != null);

  bool get tracksReps =>
      moveType == null ||
      moveType == MoveType.reps ||
      points.any((_MovePoint point) => point.reps > 0);

  _MovePoint? get selectedPoint {
    for (final _MovePoint point in points.reversed) {
      if (point.isSelected) {
        return point;
      }
    }
    return null;
  }

  _MovePoint? get previousPoint {
    final _MovePoint? selected = selectedPoint;
    if (selected == null) {
      return points.length >= 2 ? points[points.length - 2] : null;
    }
    final int selectedIndex = points.indexOf(selected);
    if (selectedIndex <= 0) {
      return null;
    }
    return points[selectedIndex - 1];
  }
}

class _MovePoint {
  const _MovePoint({
    required this.reps,
    required this.elapsedSeconds,
    this.actualWeight,
    this.actualWeightUnit,
    required this.sessionStartedAt,
    required this.isSelected,
  });

  final int reps;
  final int elapsedSeconds;
  final double? actualWeight;
  final String? actualWeightUnit;
  final DateTime sessionStartedAt;
  final bool isSelected;
}

class _MoveProgressCard extends StatelessWidget {
  const _MoveProgressCard({
    required this.series,
  });

  final _MoveSeries series;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final _MovePoint? selected = series.selectedPoint;
    final _MovePoint? previous = series.previousPoint;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.fromBorderSide(
          BorderSide(color: colors.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            series.label,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (selected != null)
            _ProgressSummary(
              selected: selected,
              previous: previous,
              tracksReps: series.tracksReps,
            )
          else
            Text(
              '${series.points.length} past ${series.points.length == 1 ? 'entry' : 'entries'}',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: 220,
            width: double.infinity,
            child: CustomPaint(
              painter: _MoveProgressChartPainter(
                points: series.points,
                colorScheme: colors,
                tracksReps: series.tracksReps,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: <Widget>[
              _LegendItem(color: colors.primary, label: 'Time'),
              if (series.tracksReps)
                _LegendItem(color: colors.tertiary, label: 'Reps'),
              if (series.hasWeight)
                _LegendItem(color: colors.secondary, label: 'Weight'),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({
    required this.selected,
    required this.previous,
    required this.tracksReps,
  });

  final _MovePoint selected;
  final _MovePoint? previous;
  final bool tracksReps;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final int? repDelta =
        previous == null ? null : selected.reps - previous!.reps;
    final int? secondsDelta = previous == null
        ? null
        : selected.elapsedSeconds - previous!.elapsedSeconds;
    final double? weightDelta =
        previous?.actualWeight == null || selected.actualWeight == null
            ? null
            : selected.actualWeight! - previous!.actualWeight!;
    final String? weightUnit = selected.actualWeightUnit;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        if (tracksReps)
          _MetricPill(
            icon: Icons.repeat,
            label: '${selected.reps} reps',
            detail: repDelta == null
                ? 'No earlier entry'
                : _formatSigned(repDelta, suffix: ' reps'),
          ),
        _MetricPill(
          icon: Icons.timer_outlined,
          label: formatShortDuration(selected.elapsedSeconds),
          detail: secondsDelta == null
              ? 'No earlier entry'
              : _formatSigned(secondsDelta, suffix: 's'),
        ),
        if (selected.actualWeight != null)
          _MetricPill(
            icon: Icons.fitness_center,
            label:
                '${formatWeight(selected.actualWeight!)} ${weightUnit ?? ''}',
            detail: weightDelta == null
                ? 'No earlier entry'
                : _formatSignedWeight(weightDelta, suffix: weightUnit ?? ''),
          ),
        Text(
          formatDate(selected.sessionStartedAt),
          style: theme.textTheme.bodySmall
              ?.copyWith(color: colors.onSurfaceVariant),
        ),
      ],
    );
  }

  String _formatSigned(int value, {required String suffix}) {
    if (value > 0) {
      return '+$value$suffix';
    }
    return '$value$suffix';
  }

  String _formatSignedWeight(double value, {required String suffix}) {
    final String formatted = formatWeight(value.abs());
    final String sign = value > 0
        ? '+'
        : value < 0
            ? '-'
            : '';
    final String unit = suffix.isEmpty ? '' : ' $suffix';
    return '$sign$formatted$unit';
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
    required this.icon,
    required this.label,
    required this.detail,
  });

  final IconData icon;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadii.pill),
        border: Border.fromBorderSide(
            BorderSide(color: colors.outlineVariant.withValues(alpha: 0.35))),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: AppSpacing.xs),
          Text(label,
              style: theme.textTheme.labelLarge
                  ?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(width: AppSpacing.xs),
          Text(detail,
              style: theme.textTheme.labelMedium
                  ?.copyWith(color: colors.onSurfaceVariant)),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
  });

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(Icons.circle, size: 10, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ChartSeries {
  const _ChartSeries({
    required this.color,
    required this.values,
  });

  final Color color;
  final List<double?> values;
}

class _MoveProgressChartPainter extends CustomPainter {
  const _MoveProgressChartPainter({
    required this.points,
    required this.colorScheme,
    required this.tracksReps,
  });

  final List<_MovePoint> points;
  final ColorScheme colorScheme;
  final bool tracksReps;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect plot = Rect.fromLTWH(42, 12, size.width - 52, size.height - 44);
    final Paint axisPaint = Paint()
      ..color = colorScheme.outlineVariant
      ..strokeWidth = 1;
    final Paint gridPaint = Paint()
      ..color = colorScheme.outlineVariant.withValues(alpha: 0.35)
      ..strokeWidth = 1;

    canvas.drawLine(plot.bottomLeft, plot.bottomRight, axisPaint);
    canvas.drawLine(plot.bottomLeft, plot.topLeft, axisPaint);

    for (int i = 1; i <= 3; i += 1) {
      final double y = plot.top + (plot.height / 4) * i;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), gridPaint);
    }

    if (points.isEmpty) {
      _drawLabel(canvas, 'No move data', Offset(plot.center.dx, plot.center.dy),
          colorScheme.onSurfaceVariant,
          align: TextAlign.center);
      return;
    }

    final List<_ChartSeries> series = <_ChartSeries>[
      _ChartSeries(
        color: colorScheme.primary,
        values: points
            .map((_MovePoint point) => point.elapsedSeconds.toDouble())
            .toList(growable: false),
      ),
      if (tracksReps)
        _ChartSeries(
          color: colorScheme.tertiary,
          values: points
              .map((_MovePoint point) => point.reps.toDouble())
              .toList(growable: false),
        ),
      if (points.any((_MovePoint point) => point.actualWeight != null))
        _ChartSeries(
          color: colorScheme.secondary,
          values: points
              .map((_MovePoint point) => point.actualWeight)
              .toList(growable: false),
        ),
    ];

    final Iterable<double> allValues = series
        .expand((_ChartSeries chartSeries) => chartSeries.values)
        .whereType<double>();
    final double maxValue = math.max(1, allValues.fold<double>(0, math.max));

    Offset pointOffset(int index, double value) {
      final double x = points.length == 1
          ? plot.center.dx
          : plot.left + (index / (points.length - 1)) * plot.width;
      final double y = plot.bottom - (value / maxValue) * plot.height;
      return Offset(x, y);
    }

    for (final _ChartSeries chartSeries in series) {
      _drawSeries(canvas, chartSeries, pointOffset);
    }

    for (int index = 0; index < points.length; index += 1) {
      if (!points[index].isSelected) {
        continue;
      }
      final double x = points.length == 1
          ? plot.center.dx
          : plot.left + (index / (points.length - 1)) * plot.width;
      final Paint selectedPaint = Paint()
        ..color = colorScheme.primary.withValues(alpha: 0.18)
        ..strokeWidth = 2;
      canvas.drawLine(
          Offset(x, plot.top), Offset(x, plot.bottom), selectedPaint);
    }

    _drawLabel(canvas, '1', Offset(plot.left, plot.bottom + 16),
        colorScheme.onSurfaceVariant);
    _drawLabel(
        canvas,
        '${points.length} ${points.length == 1 ? 'time' : 'times'}',
        Offset(plot.right, plot.bottom + 16),
        colorScheme.onSurfaceVariant,
        align: TextAlign.right);
    _drawLabel(canvas, _formatAxisValue(maxValue),
        Offset(plot.left - 8, plot.top), colorScheme.onSurfaceVariant,
        align: TextAlign.right);
    _drawLabel(canvas, '0', Offset(plot.left - 8, plot.bottom - 10),
        colorScheme.onSurfaceVariant,
        align: TextAlign.right);
  }

  void _drawSeries(
    Canvas canvas,
    _ChartSeries series,
    Offset Function(int index, double value) pointOffset,
  ) {
    final Paint linePaint = Paint()
      ..color = series.color.withValues(alpha: 0.78)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final Paint pointPaint = Paint()..color = series.color;
    final Path path = Path();
    bool hasStarted = false;

    for (int index = 0; index < series.values.length; index += 1) {
      final double? value = series.values[index];
      if (value == null) {
        hasStarted = false;
        continue;
      }
      final Offset offset = pointOffset(index, value);
      if (!hasStarted) {
        path.moveTo(offset.dx, offset.dy);
        hasStarted = true;
      } else {
        path.lineTo(offset.dx, offset.dy);
      }
      canvas.drawCircle(offset, points[index].isSelected ? 5 : 3.5, pointPaint);
    }

    canvas.drawPath(path, linePaint);
  }

  String _formatAxisValue(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    return value.toStringAsFixed(1);
  }

  void _drawLabel(
    Canvas canvas,
    String text,
    Offset offset,
    Color color, {
    TextAlign align = TextAlign.left,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(color: color, fontSize: 11),
      ),
      textAlign: align,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 80);
    double dx = offset.dx;
    if (align == TextAlign.right) {
      dx -= painter.width;
    } else if (align == TextAlign.center) {
      dx -= painter.width / 2;
    }
    painter.paint(canvas, Offset(dx, offset.dy));
  }

  @override
  bool shouldRepaint(covariant _MoveProgressChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.colorScheme != colorScheme ||
        oldDelegate.tracksReps != tracksReps;
  }
}

class _EmptyMoveHistory extends StatelessWidget {
  const _EmptyMoveHistory({
    required this.workoutName,
  });

  final String workoutName;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.fromBorderSide(
          BorderSide(color: colors.outlineVariant.withValues(alpha: 0.3)),
        ),
      ),
      child: Column(
        children: <Widget>[
          Icon(Icons.show_chart, size: 48, color: colors.onSurfaceVariant),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No move-level history yet',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Complete $workoutName again to compare reps and completion time for each move.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
