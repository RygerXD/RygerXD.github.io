import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

Future<void> exportWorkoutPlan(
  BuildContext context,
  WidgetRef ref,
  WorkoutPlan plan,
) async {
  try {
    final result = await ref.read(workoutPlanExportServiceProvider).exportPlan(
          plan,
        );
    if (!context.mounted) {
      return;
    }
    if (result == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export canceled.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Exported ${plan.name}')),
    );
  } catch (error) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error exporting workout: $error')),
      );
    }
  }
}
