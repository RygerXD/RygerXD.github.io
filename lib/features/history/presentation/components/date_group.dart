import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/core/theme/tokens.dart';
import 'package:workout_app_rewrite/features/history/presentation/components/analysis_session_item.dart';
import 'package:workout_app_rewrite/features/history/presentation/components/session_card.dart';

class DateGroup extends StatelessWidget {
  const DateGroup({
    required this.dateLabel,
    required this.sessions,
    super.key,
  });

  final String dateLabel;
  final List<AnalysisSessionItem> sessions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
          child: Text(
            dateLabel,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
              letterSpacing: 0.4,
            ),
          ),
        ),
        ...sessions.map((AnalysisSessionItem session) => SessionCard(item: session)),
      ],
    );
  }
}
