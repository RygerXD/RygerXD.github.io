import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_export_service.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_import_service.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_parser.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/shared_prefs_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

final Provider<WorkoutPlanParser> workoutPlanParserProvider =
    Provider<WorkoutPlanParser>((Ref<WorkoutPlanParser> ref) {
  return const WorkoutPlanParser();
});

final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>((Ref<SharedPreferences> ref) {
  throw UnimplementedError(
      'sharedPreferencesProvider must be overridden in main.dart');
});

final Provider<WorkoutRepository> workoutRepositoryProvider =
    Provider<WorkoutRepository>((Ref<WorkoutRepository> ref) {
  return SharedPrefsWorkoutRepository(ref.watch(sharedPreferencesProvider));
});

final Provider<WorkoutPlanImportService> workoutPlanImportServiceProvider =
    Provider<WorkoutPlanImportService>((Ref<WorkoutPlanImportService> ref) {
  return WorkoutPlanImportService(
    parser: ref.read(workoutPlanParserProvider),
    repository: ref.read(workoutRepositoryProvider),
  );
});

final Provider<WorkoutPlanExportService> workoutPlanExportServiceProvider =
    Provider<WorkoutPlanExportService>((Ref<WorkoutPlanExportService> ref) {
  return const WorkoutPlanExportService();
});

class LoadedWorkoutPlansNotifier extends AsyncNotifier<List<WorkoutPlan>> {
  @override
  Future<List<WorkoutPlan>> build() async {
    final WorkoutRepository repository = ref.read(workoutRepositoryProvider);
    return repository.getAllPlans();
  }

  Future<void> loadPlan(WorkoutPlan plan) async {
    final WorkoutRepository repository = ref.read(workoutRepositoryProvider);
    await repository.savePlan(plan);
    ref.invalidateSelf();
    await future;
  }

  Future<void> removePlan(String planId) async {
    final WorkoutRepository repository = ref.read(workoutRepositoryProvider);
    await repository.deletePlan(planId);
    ref.invalidateSelf();
    await future;
  }

  Future<void> removeWorkout({
    required String planId,
    required String workoutId,
  }) async {
    final WorkoutRepository repository = ref.read(workoutRepositoryProvider);
    final WorkoutPlan? plan = await repository.getPlanById(planId);
    if (plan == null) {
      return;
    }

    final int workoutIndex = plan.workouts.indexWhere(
      (Workout workout) => workout.workoutId == workoutId,
    );
    if (workoutIndex == -1 || plan.workouts[workoutIndex].isArchived) {
      return;
    }

    final List<Workout> updatedWorkouts = List<Workout>.from(plan.workouts);
    updatedWorkouts.removeAt(workoutIndex);
    final Set<String> referencedMoveIds =
        plan.referencedMoveIds(fromWorkouts: updatedWorkouts);

    await repository.savePlan(
      plan.copyWith(
        workouts: updatedWorkouts,
        moves: plan.moves
            .where((Move move) => referencedMoveIds.contains(move.moveId))
            .toList(growable: false),
      ),
    );
    ref.invalidateSelf();
    await future;
  }
}

final AsyncNotifierProvider<LoadedWorkoutPlansNotifier, List<WorkoutPlan>>
    loadedWorkoutPlansNotifierProvider =
    AsyncNotifierProvider<LoadedWorkoutPlansNotifier, List<WorkoutPlan>>(() {
  return LoadedWorkoutPlansNotifier();
});
