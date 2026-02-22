import 'package:workout_app_rewrite/features/workout_plan/data/workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class InMemoryWorkoutRepository implements WorkoutRepository {
  final Map<String, WorkoutPlan> _plansById = <String, WorkoutPlan>{};

  @override
  Future<void> deletePlan(String planId) async {
    _plansById.remove(planId);
  }

  @override
  Future<List<WorkoutPlan>> getAllPlans() async {
    return _plansById.values.toList(growable: false);
  }

  @override
  Future<WorkoutPlan?> getPlanById(String planId) async {
    return _plansById[planId];
  }

  @override
  Future<void> savePlan(WorkoutPlan plan) async {
    _plansById[plan.planId] = plan;
  }
}
