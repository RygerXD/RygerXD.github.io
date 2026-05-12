import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
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
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              item.planName,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
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
              value: formatDate(
                item.startedAt,
                monthStyle: MonthNameStyle.long,
              ),
            ),
            _DetailRow(
              icon: Icons.access_time_outlined,
              label: 'Started',
              value: formatTime(item.startedAt),
            ),
            if (item.endedAt != null)
              _DetailRow(
                icon: Icons.stop_circle_outlined,
                label: 'Ended',
                value: formatTime(item.endedAt!),
              ),
            _DetailRow(
              icon: Icons.timer_outlined,
              label: 'Duration',
              value: formatDuration(item.session.durationSeconds),
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
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: colors.onSurfaceVariant),
          ),
          const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
