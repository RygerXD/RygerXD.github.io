import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';

class EmptyHistory extends StatelessWidget {
  const EmptyHistory({
    super.key,
    this.onStartWorkout,
  });

  final VoidCallback? onStartWorkout;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: colors.surfaceContainerHighest.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.insights_outlined,
                size: 40,
                color: colors.primary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No Analysis Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Complete your first workout to unlock heatmaps and session history.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onStartWorkout,
              icon: const Icon(Icons.fitness_center),
              label: const Text('Go to Home'),
            ),
          ],
        ),
      ),
    );
  }
}
