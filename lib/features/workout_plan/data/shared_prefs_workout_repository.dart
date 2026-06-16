import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class SharedPrefsWorkoutRepository implements WorkoutRepository {
  SharedPrefsWorkoutRepository(this._prefs);

  final SharedPreferences _prefs;
  static const String _planPrefix = 'workout_plan_';

  @override
  Future<void> deletePlan(String planId) async {
    await _prefs.remove('$_planPrefix$planId');
  }

  @override
  Future<List<WorkoutPlan>> getAllPlans() async {
    await _prefs.reload();
    final List<WorkoutPlan> plans = <WorkoutPlan>[];
    for (final String key in _prefs.getKeys()) {
      if (key.startsWith(_planPrefix)) {
        final String? jsonString = _prefs.getString(key);
        if (jsonString != null) {
          try {
            final Map<String, dynamic> jsonMap =
                jsonDecode(jsonString) as Map<String, dynamic>;
            plans.add(WorkoutPlan.fromJson(jsonMap));
          } catch (e) {
            // Ignore corrupted or invalid JSON items in storage.
          }
        }
      }
    }
    return plans;
  }

  @override
  Future<WorkoutPlan?> getPlanById(String planId) async {
    await _prefs.reload();
    final String? jsonString = _prefs.getString('$_planPrefix$planId');
    if (jsonString == null) {
      return null;
    }
    try {
      final Map<String, dynamic> jsonMap =
          jsonDecode(jsonString) as Map<String, dynamic>;
      return WorkoutPlan.fromJson(jsonMap);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> savePlan(WorkoutPlan plan) async {
    final String jsonString = jsonEncode(plan.toJson());
    final bool didSave =
        await _prefs.setString('$_planPrefix${plan.planId}', jsonString);
    if (!didSave) {
      throw StateError('Failed to persist workout plan ${plan.planId}.');
    }
  }
}
