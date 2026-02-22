import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/features/history/presentation/components/analysis_session_item.dart';

class SessionDetailSheet extends StatelessWidget {
  const SessionDetailSheet({
    required this.item,
    super.key,
  });

  final AnalysisSessionItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.lg,
          AppSpacing.xl,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.outlineVariant,
                  borderRadius: BorderRadius.circular(AppRadii.pill),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              item.workoutName,
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.planName,
              style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.lg),
            _DetailRow(
              icon: Icons.flag_outlined,
              label: 'Status',
              value: _statusLabel(item.session.status),
            ),
            _DetailRow(
              icon: Icons.calendar_today_outlined,
              label: 'Date',
              value: _formatDate(item.startedAt),
            ),
            _DetailRow(
              icon: Icons.access_time_outlined,
              label: 'Started',
              value: _formatTime(item.startedAt),
            ),
            if (item.endedAt != null)
              _DetailRow(
                icon: Icons.stop_circle_outlined,
                label: 'Ended',
                value: _formatTime(item.endedAt!),
              ),
            _DetailRow(
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: _formatDuration(item.session.durationSeconds),
            ),
            const SizedBox(height: AppSpacing.lg),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
                label: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _statusLabel(String status) {
    return switch (status) {
      'completed' => 'Completed',
      'abandoned' => 'Abandoned',
      _ => 'In Progress',
    };
  }

  static String _formatDate(DateTime date) {
    return '${_monthName(date.month)} ${date.day}, ${date.year}';
  }

  static String _formatTime(DateTime date) {
    final int hour = date.hour;
    final String minute = date.minute.toString().padLeft(2, '0');
    final String period = hour >= 12 ? 'PM' : 'AM';
    final int displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }

  static String _formatDuration(int seconds) {
    if (seconds <= 0) {
      return '-';
    }
    final Duration duration = Duration(seconds: seconds);
    if (duration.inHours == 0) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    }
    final int minutesRemainder = duration.inMinutes.remainder(60);
    return '${duration.inHours}h ${minutesRemainder}m';
  }

  static String _monthName(int month) {
    const List<String> names = <String>[
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return names[month - 1];
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Icon(icon, color: colors.onSurfaceVariant, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
