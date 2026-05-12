import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

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
            '${_formatDate(_dateFromMs(selectedSession.startedAt))} - ${comparableSessions.length} tracked ${comparableSessions.length == 1 ? 'session' : 'sessions'}',
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
}

_WorkoutContext _resolveWorkoutContext(
  WorkoutSessionEntity session,
  List<WorkoutPlan> plans,
) {
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
      workoutName: 'Unknown Workout',
    );
  }
  return const _WorkoutContext(
    plan: null,
    workout: null,
    workoutName: 'Unknown Workout',
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
      loopIndex: performance.loopIndex,
      moveId: performance.moveId,
      exerciseId: performance.exerciseId,
    );
    pointsByKey.putIfAbsent(key, () => <_MovePoint>[]).add(
          _MovePoint(
            reps: performance.repCount,
            elapsedSeconds: performance.elapsedSeconds,
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
            ))
        .toList(growable: false)
      ..sort((_MoveSeries a, _MoveSeries b) => a.label.compareTo(b.label));
    return fallback;
  }

  final List<_MoveSeries> series = <_MoveSeries>[];
  for (int setIndex = 0; setIndex < workout.sets.length; setIndex += 1) {
    final WorkoutSet set = workout.sets[setIndex];
    for (int loopIndex = 0; loopIndex < set.loopCount; loopIndex += 1) {
      for (int moveIndex = 0; moveIndex < set.moves.length; moveIndex += 1) {
        final Move move = set.moves[moveIndex];
        final String key = _moveKey(
          setId: set.setId,
          loopIndex: loopIndex,
          moveId: move.moveId,
          exerciseId: move.exerciseId,
        );
        final List<_MovePoint>? points = pointsByKey[key];
        if (points == null || points.isEmpty) {
          continue;
        }
        final String moveName = _exerciseName(move.exerciseId, plan);
        final String setName = set.name?.trim().isNotEmpty == true
            ? set.name!.trim()
            : 'Set ${setIndex + 1}';
        series.add(
          _MoveSeries(
            label: '$moveName - $setName, Loop ${loopIndex + 1}',
            points: points,
          ),
        );
      }
    }
  }
  return series;
}

String _moveKey({
  required String setId,
  required int loopIndex,
  required String moveId,
  required String exerciseId,
}) {
  return '$setId|$loopIndex|$moveId|$exerciseId';
}

String _exerciseName(String exerciseId, WorkoutPlan? plan) {
  if (plan == null) {
    return exerciseId;
  }
  for (final Exercise exercise in plan.exercises) {
    if (exercise.exerciseId == exerciseId) {
      return exercise.name;
    }
  }
  return exerciseId;
}

DateTime _dateFromMs(int millisecondsSinceEpoch) {
  return DateTime.fromMillisecondsSinceEpoch(millisecondsSinceEpoch);
}

String _formatDate(DateTime date) {
  const List<String> months = <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _formatDuration(int seconds) {
  if (seconds < 60) {
    return '${seconds}s';
  }
  final Duration duration = Duration(seconds: seconds);
  return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
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
  });

  final String label;
  final List<_MovePoint> points;

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
    required this.sessionStartedAt,
    required this.isSelected,
  });

  final int reps;
  final int elapsedSeconds;
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
            _ProgressSummary(selected: selected, previous: previous)
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
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: <Widget>[
              Icon(Icons.circle, size: 10, color: colors.primary),
              const SizedBox(width: AppSpacing.xs),
              Text('Selected workout', style: theme.textTheme.bodySmall),
              const SizedBox(width: AppSpacing.md),
              Icon(Icons.circle, size: 10, color: colors.tertiary),
              const SizedBox(width: AppSpacing.xs),
              Text('Past workout', style: theme.textTheme.bodySmall),
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
  });

  final _MovePoint selected;
  final _MovePoint? previous;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final int? repDelta =
        previous == null ? null : selected.reps - previous!.reps;
    final int? secondsDelta = previous == null
        ? null
        : selected.elapsedSeconds - previous!.elapsedSeconds;

    return Wrap(
      spacing: AppSpacing.md,
      runSpacing: AppSpacing.sm,
      children: <Widget>[
        _MetricPill(
          icon: Icons.repeat,
          label: '${selected.reps} reps',
          detail: repDelta == null
              ? 'No earlier entry'
              : _formatSigned(repDelta, suffix: ' reps'),
        ),
        _MetricPill(
          icon: Icons.timer_outlined,
          label: _formatDuration(selected.elapsedSeconds),
          detail: secondsDelta == null
              ? 'No earlier entry'
              : _formatSigned(secondsDelta, suffix: 's'),
        ),
        Text(
          _formatDate(selected.sessionStartedAt),
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

class _MoveProgressChartPainter extends CustomPainter {
  const _MoveProgressChartPainter({
    required this.points,
    required this.colorScheme,
  });

  final List<_MovePoint> points;
  final ColorScheme colorScheme;

  @override
  void paint(Canvas canvas, Size size) {
    final Rect plot = Rect.fromLTWH(38, 12, size.width - 48, size.height - 42);
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

    final int minReps =
        points.map((_MovePoint point) => point.reps).reduce(math.min);
    final int maxReps =
        points.map((_MovePoint point) => point.reps).reduce(math.max);
    final int minSeconds =
        points.map((_MovePoint point) => point.elapsedSeconds).reduce(math.min);
    final int maxSeconds =
        points.map((_MovePoint point) => point.elapsedSeconds).reduce(math.max);
    final int repSpan = maxReps - minReps;
    final int secondsSpan = maxSeconds - minSeconds;

    Offset pointOffset(_MovePoint point) {
      final double x = repSpan == 0
          ? plot.center.dx
          : plot.left + ((point.reps - minReps) / repSpan) * plot.width;
      final double y = secondsSpan == 0
          ? plot.center.dy
          : plot.bottom -
              ((point.elapsedSeconds - minSeconds) / secondsSpan) * plot.height;
      return Offset(x, y);
    }

    if (points.length > 1) {
      final Paint linePaint = Paint()
        ..color = colorScheme.primary.withValues(alpha: 0.55)
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke;
      final Path path = Path()
        ..moveTo(pointOffset(points.first).dx, pointOffset(points.first).dy);
      for (final _MovePoint point in points.skip(1)) {
        final Offset offset = pointOffset(point);
        path.lineTo(offset.dx, offset.dy);
      }
      canvas.drawPath(path, linePaint);
    }

    for (final _MovePoint point in points) {
      final Offset offset = pointOffset(point);
      final Paint fill = Paint()
        ..color = point.isSelected ? colorScheme.primary : colorScheme.tertiary;
      canvas.drawCircle(offset, point.isSelected ? 6 : 4, fill);
      if (point.isSelected) {
        final Paint ring = Paint()
          ..color = colorScheme.primary.withValues(alpha: 0.25)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3;
        canvas.drawCircle(offset, 10, ring);
      }
    }

    _drawLabel(canvas, '$minReps', Offset(plot.left, plot.bottom + 16),
        colorScheme.onSurfaceVariant);
    _drawLabel(canvas, '$maxReps reps', Offset(plot.right, plot.bottom + 16),
        colorScheme.onSurfaceVariant,
        align: TextAlign.right);
    _drawLabel(canvas, '${maxSeconds}s', Offset(plot.left - 8, plot.top),
        colorScheme.onSurfaceVariant,
        align: TextAlign.right);
    _drawLabel(canvas, '${minSeconds}s',
        Offset(plot.left - 8, plot.bottom - 10), colorScheme.onSurfaceVariant,
        align: TextAlign.right);
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
        oldDelegate.colorScheme != colorScheme;
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
