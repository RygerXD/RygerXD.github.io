import 'dart:convert';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class DriftWorkoutRepository implements WorkoutRepository {
  DriftWorkoutRepository(this._db);

  final HistoryDatabase _db;

  @override
  Future<void> deletePlan(String planId) async {
    await _db.deleteWorkoutPlan(planId);
  }

  @override
  Future<List<WorkoutPlan>> getAllPlans() async {
    final List<WorkoutPlan> plans = <WorkoutPlan>[];
    final List<WorkoutPlanEntity> entities = await _db.getAllWorkoutPlans();

    for (final WorkoutPlanEntity entity in entities) {
      try {
        final Map<String, dynamic> jsonMap =
            jsonDecode(entity.jsonPayload) as Map<String, dynamic>;
        plans.add(WorkoutPlan.fromJson(jsonMap));
      } catch (e) {
        // Ignore corrupted JSON
      }
    }
    return plans;
  }

  @override
  Future<WorkoutPlan?> getPlanById(String planId) async {
    final List<WorkoutPlanEntity> entities = await _db.getAllWorkoutPlans();
    for (final WorkoutPlanEntity entity in entities) {
      if (entity.planId == planId) {
        try {
          final Map<String, dynamic> jsonMap =
              jsonDecode(entity.jsonPayload) as Map<String, dynamic>;
          return WorkoutPlan.fromJson(jsonMap);
        } catch (e) {
          return null;
        }
      }
    }
    return null;
  }

  @override
  Future<void> savePlan(WorkoutPlan plan) async {
    final String jsonString = jsonEncode(plan.toJson());
    await _db.insertWorkoutPlan(
      WorkoutPlanEntity(
        planId: plan.planId,
        jsonPayload: jsonString,
      ),
    );
  }
}
