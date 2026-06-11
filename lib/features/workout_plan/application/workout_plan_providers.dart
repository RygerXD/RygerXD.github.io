import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_export_service.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_import_service.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_parser.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/drift_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/mirrored_workout_repository.dart';
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
  final WorkoutRepository primary =
      SharedPrefsWorkoutRepository(ref.watch(sharedPreferencesProvider));
  final WorkoutRepository secondary =
      DriftWorkoutRepository(ref.watch(historyDatabaseProvider));
  return MirroredWorkoutRepository(primary: primary, secondary: secondary);
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

    final List<Workout> updatedWorkouts = plan.workouts
        .where((Workout workout) => workout.workoutId != workoutId)
        .toList(growable: false);
    if (updatedWorkouts.length == plan.workouts.length) {
      return;
    }

    await repository.savePlan(
      plan.copyWith(
        workouts: updatedWorkouts,
        exercises: _referencedExercises(
          exercises: plan.exercises,
          workouts: updatedWorkouts,
        ),
      ),
    );
    ref.invalidateSelf();
    await future;
  }
}

List<Exercise> _referencedExercises({
  required List<Exercise> exercises,
  required List<Workout> workouts,
}) {
  final Set<String> referencedExerciseIds = <String>{};
  for (final Workout workout in workouts) {
    for (final WorkoutSet set in workout.sets) {
      for (final Move move in set.moves) {
        referencedExerciseIds.add(move.exerciseId);
      }
    }
  }

  return exercises
      .where((Exercise exercise) =>
          referencedExerciseIds.contains(exercise.exerciseId))
      .toList(growable: false);
}

final AsyncNotifierProvider<LoadedWorkoutPlansNotifier, List<WorkoutPlan>>
    loadedWorkoutPlansNotifierProvider =
    AsyncNotifierProvider<LoadedWorkoutPlansNotifier, List<WorkoutPlan>>(() {
  return LoadedWorkoutPlansNotifier();
});
