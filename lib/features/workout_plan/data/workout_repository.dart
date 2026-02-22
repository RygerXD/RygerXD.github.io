import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

abstract interface class WorkoutRepository {
  Future<List<WorkoutPlan>> getAllPlans();

  Future<WorkoutPlan?> getPlanById(String planId);

  Future<void> savePlan(WorkoutPlan plan);

  Future<void> deletePlan(String planId);
}
