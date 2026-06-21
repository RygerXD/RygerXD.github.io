import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/history/presentation/components/analysis_session_item.dart';

class SessionCard extends StatelessWidget {
  const SessionCard({
    required this.item,
    super.key,
  });

  final AnalysisSessionItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;
    final _StatusStyle statusStyle =
        _StatusStyle.fromSessionStatus(item.session.status, colors);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(AppRadii.lg),
        border: Border.fromBorderSide(
          BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadii.lg),
        onTap: () {
          context.go('/analysis/session/${item.session.sessionId}');
        },
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: <Widget>[
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: statusStyle.backgroundColor,
                  borderRadius: BorderRadius.circular(AppRadii.md),
                ),
                child: Icon(
                  statusStyle.icon,
                  color: statusStyle.foregroundColor,
                  size: 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      item.workoutName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.planName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: <Widget>[
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            Icon(Icons.access_time,
                                size: 14, color: colors.onSurfaceVariant),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              formatTime(item.startedAt),
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.sm, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusStyle.backgroundColor,
                            borderRadius: BorderRadius.circular(AppRadii.pill),
                          ),
                          child: Text(
                            statusStyle.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: statusStyle.foregroundColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    formatDuration(item.session.durationSeconds),
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  Text(
                    'duration',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.icon,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final IconData icon;
  final Color backgroundColor;
  final Color foregroundColor;

  factory _StatusStyle.fromSessionStatus(String status, ColorScheme colors) {
    if (status == 'completed') {
      return _StatusStyle(
        label: 'Completed',
        icon: Icons.check_circle_outline_rounded,
        backgroundColor: colors.primaryContainer,
        foregroundColor: colors.primary,
      );
    }
    if (status == 'abandoned') {
      return _StatusStyle(
        label: 'Abandoned',
        icon: Icons.cancel_outlined,
        backgroundColor: colors.errorContainer,
        foregroundColor: colors.error,
      );
    }
    return _StatusStyle(
      label: 'In Progress',
      icon: Icons.play_circle_outline_rounded,
      backgroundColor: colors.secondaryContainer,
      foregroundColor: colors.secondary,
    );
  }
}
