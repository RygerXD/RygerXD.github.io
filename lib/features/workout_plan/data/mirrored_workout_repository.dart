import 'package:workout_app_rewrite/features/workout_plan/data/workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

/// Uses [primary] as the source of truth while keeping a best-effort mirror in
/// [secondary] for compatibility with legacy storage.
class MirroredWorkoutRepository implements WorkoutRepository {
  MirroredWorkoutRepository({
    required WorkoutRepository primary,
    required WorkoutRepository secondary,
  })  : _primary = primary,
        _secondary = secondary;

  final WorkoutRepository _primary;
  final WorkoutRepository _secondary;

  @override
  Future<void> deletePlan(String planId) async {
    await _primary.deletePlan(planId);
    try {
      await _secondary.deletePlan(planId);
    } catch (_) {
      // Ignore secondary storage failures. Primary is authoritative.
    }
  }

  @override
  Future<List<WorkoutPlan>> getAllPlans() async {
    final List<WorkoutPlan> primaryPlans = await _primary.getAllPlans();
    if (primaryPlans.isNotEmpty) {
      return primaryPlans;
    }

    final List<WorkoutPlan> secondaryPlans = await _secondary.getAllPlans();
    if (secondaryPlans.isNotEmpty) {
      await _seedPrimaryFromSecondary(secondaryPlans);
    }
    return secondaryPlans;
  }

  @override
  Future<WorkoutPlan?> getPlanById(String planId) async {
    final WorkoutPlan? fromPrimary = await _primary.getPlanById(planId);
    if (fromPrimary != null) {
      return fromPrimary;
    }

    final WorkoutPlan? fromSecondary = await _secondary.getPlanById(planId);
    if (fromSecondary != null) {
      await _tryPrimarySave(fromSecondary);
    }
    return fromSecondary;
  }

  @override
  Future<void> savePlan(WorkoutPlan plan) async {
    await _primary.savePlan(plan);
    try {
      await _secondary.savePlan(plan);
    } catch (_) {
      // Ignore secondary storage failures. Primary is authoritative.
    }
  }

  Future<void> _seedPrimaryFromSecondary(List<WorkoutPlan> plans) async {
    for (final WorkoutPlan plan in plans) {
      await _tryPrimarySave(plan);
    }
  }

  Future<void> _tryPrimarySave(WorkoutPlan plan) async {
    try {
      await _primary.savePlan(plan);
    } catch (_) {
      // If migration into primary fails, we still return the legacy data.
    }
  }
}
