import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/core/media/move_media_image.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_metrics.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class ActiveMoveMedia extends StatelessWidget {
  const ActiveMoveMedia({
    required this.url,
    super.key,
  });

  final String url;

  @override
  Widget build(BuildContext context) {
    final Size screenSize = MediaQuery.sizeOf(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        constraints: BoxConstraints(
          maxWidth: screenSize.width * 0.9,
          maxHeight: screenSize.height * 0.24,
        ),
        color: colorScheme.surfaceContainerHighest,
        child: MoveMediaImage(
          source: url,
          fit: BoxFit.contain,
          loadingPlaceholder: const SizedBox(
            width: 160,
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          ),
          errorPlaceholder: const SizedBox(
            width: 160,
            height: 120,
            child: Icon(Icons.broken_image_outlined, size: 40),
          ),
        ),
      ),
    );
  }
}

class ActiveTimerDisplay extends StatelessWidget {
  const ActiveTimerDisplay({
    required this.seconds,
    required this.color,
    super.key,
  });

  final int seconds;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      formatShortClockDuration(seconds.clamp(0, 1 << 31)),
      style: TextStyle(
        fontSize: 120,
        fontWeight: FontWeight.bold,
        color: color,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
    );
  }
}

class ActiveStopwatchDisplay extends StatelessWidget {
  const ActiveStopwatchDisplay({
    required this.move,
    required this.seconds,
    required this.color,
    this.lastDuration,
    super.key,
  });

  final WorkoutMove move;
  final int seconds;
  final Color color;
  final int? lastDuration;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        ActiveTimerDisplay(seconds: seconds, color: color),
        if (move.repeatEachSide || move.side != null)
          const Text(
            'Left and right sides',
            style: TextStyle(color: Colors.grey, fontSize: 16),
            textAlign: TextAlign.center,
          ),
        if (lastDuration != null)
          Text(
            'Last: ${formatShortDuration(lastDuration!)}',
            style: const TextStyle(color: Colors.orange, fontSize: 16),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }
}

class ActiveAdjustableRepDisplay extends StatelessWidget {
  const ActiveAdjustableRepDisplay({
    required this.move,
    required this.currentReps,
    required this.onRepsChanged,
    this.lastReps,
    super.key,
  });

  final WorkoutMove move;
  final int currentReps;
  final ValueChanged<int> onRepsChanged;
  final int? lastReps;

  @override
  Widget build(BuildContext context) {
    final bool isPerSide = move.repeatEachSide || move.side != null;
    final Color color = Theme.of(context).colorScheme.primary;

    return Column(
      children: <Widget>[
        Text(
          isPerSide ? 'ACTUAL REPS / SIDE' : 'ACTUAL REPS',
          style: _metricLabelStyle,
        ),
        const SizedBox(height: 8),
        Text(
          currentReps.toString(),
          style: TextStyle(
            fontSize: 84,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          isPerSide
              ? 'Recommended: ${move.repCount ?? 0} / side'
              : 'Recommended: ${move.repCount ?? 0}',
          style: _hintStyle,
          textAlign: TextAlign.center,
        ),
        if (lastReps != null)
          Text(
            'Last: $lastReps',
            style: _lastValueStyle,
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 16),
        _AdjustmentButtons(
          color: color,
          adjustments: <_MetricAdjustment>[
            _MetricAdjustment(
              label: '-10',
              icon: Icons.keyboard_double_arrow_left,
              onPressed: currentReps >= 10
                  ? () => onRepsChanged(currentReps - 10)
                  : null,
            ),
            _MetricAdjustment(
              label: '-1',
              icon: Icons.remove,
              onPressed:
                  currentReps > 0 ? () => onRepsChanged(currentReps - 1) : null,
            ),
            _MetricAdjustment(
              label: '+1',
              icon: Icons.add,
              onPressed: () => onRepsChanged(currentReps + 1),
            ),
            _MetricAdjustment(
              label: '+10',
              icon: Icons.keyboard_double_arrow_right,
              onPressed: () => onRepsChanged(currentReps + 10),
            ),
          ],
        ),
      ],
    );
  }
}

class ActiveAdjustableWeightDisplay extends StatelessWidget {
  const ActiveAdjustableWeightDisplay({
    required this.move,
    required this.currentWeight,
    required this.onWeightChanged,
    this.lastWeight,
    super.key,
  });

  final WorkoutMove move;
  final double currentWeight;
  final ValueChanged<double> onWeightChanged;
  final double? lastWeight;

  @override
  Widget build(BuildContext context) {
    final String unit = move.targetWeightUnit?.name ?? '';
    final Color color = Theme.of(context).colorScheme.tertiary;

    return Column(
      children: <Widget>[
        const Text('ACTUAL WEIGHT', style: _metricLabelStyle),
        const SizedBox(height: 6),
        Text(
          '${formatWeight(currentWeight)} $unit',
          style: TextStyle(
            fontSize: 42,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          'Recommended: ${formatWeight(move.targetWeight ?? 0)} $unit',
          style: _hintStyle,
          textAlign: TextAlign.center,
        ),
        if (lastWeight != null)
          Text(
            'Last: ${formatWeight(lastWeight!)} $unit',
            style: _lastValueStyle,
            textAlign: TextAlign.center,
          ),
        const SizedBox(height: 12),
        _AdjustmentButtons(
          color: color,
          adjustments: <_MetricAdjustment>[
            _MetricAdjustment(
              label: '-5',
              icon: Icons.keyboard_double_arrow_left,
              onPressed: currentWeight >= 5
                  ? () => onWeightChanged(currentWeight - 5)
                  : null,
            ),
            _MetricAdjustment(
              label: '-1',
              icon: Icons.remove,
              onPressed: currentWeight >= 1
                  ? () => onWeightChanged(currentWeight - 1)
                  : null,
            ),
            _MetricAdjustment(
              label: '+1',
              icon: Icons.add,
              onPressed: () => onWeightChanged(currentWeight + 1),
            ),
            _MetricAdjustment(
              label: '+5',
              icon: Icons.keyboard_double_arrow_right,
              onPressed: () => onWeightChanged(currentWeight + 5),
            ),
          ],
        ),
      ],
    );
  }
}

class ActiveMetronomeSummary extends StatelessWidget {
  const ActiveMetronomeSummary({
    required this.bpm,
    required this.estimatedReps,
    super.key,
  });

  final int bpm;
  final int estimatedReps;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$bpm BPM - $estimatedReps reps',
      style: _hintStyle,
      textAlign: TextAlign.center,
    );
  }
}

class ActivePhaseChip extends StatelessWidget {
  const ActivePhaseChip({
    required this.label,
    required this.color,
    super.key,
  });

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

class _AdjustmentButtons extends StatelessWidget {
  const _AdjustmentButtons({
    required this.color,
    required this.adjustments,
  });

  final Color color;
  final List<_MetricAdjustment> adjustments;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 12,
      runSpacing: 12,
      children: <Widget>[
        for (final _MetricAdjustment adjustment in adjustments)
          _AdjustmentButton(
            label: adjustment.label,
            icon: adjustment.icon,
            onPressed: adjustment.onPressed,
            color: color,
          ),
      ],
    );
  }
}

class _AdjustmentButton extends StatelessWidget {
  const _AdjustmentButton({
    required this.label,
    required this.icon,
    required this.color,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: Column(
        children: <Widget>[
          IconButton.filled(
            onPressed: onPressed,
            icon: Icon(icon, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: color.withValues(alpha: 0.2),
              foregroundColor: color,
              fixedSize: const Size.square(56),
              padding: EdgeInsets.zero,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(color: color.withValues(alpha: 0.7), fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _MetricAdjustment {
  const _MetricAdjustment({
    required this.label,
    required this.icon,
    this.onPressed,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
}

const TextStyle _hintStyle = TextStyle(color: Colors.grey, fontSize: 16);
const TextStyle _lastValueStyle = TextStyle(color: Colors.orange, fontSize: 16);
const TextStyle _metricLabelStyle = TextStyle(
  color: Colors.grey,
  letterSpacing: 1.2,
  fontWeight: FontWeight.bold,
);
