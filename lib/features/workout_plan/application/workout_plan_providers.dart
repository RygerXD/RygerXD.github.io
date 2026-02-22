import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/drift_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_import_service.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_parser.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/mirrored_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/shared_prefs_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

final Provider<WorkoutPlanParser> workoutPlanParserProvider =
    Provider<WorkoutPlanParser>((Ref<WorkoutPlanParser> ref) {
  return const WorkoutPlanParser();
});

final Provider<SharedPreferences> sharedPreferencesProvider = Provider<SharedPreferences>((Ref<SharedPreferences> ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main.dart');
});

final Provider<WorkoutRepository> workoutRepositoryProvider =
    Provider<WorkoutRepository>((Ref<WorkoutRepository> ref) {
  final WorkoutRepository primary = SharedPrefsWorkoutRepository(ref.watch(sharedPreferencesProvider));
  final WorkoutRepository secondary = DriftWorkoutRepository(ref.watch(historyDatabaseProvider));
  return MirroredWorkoutRepository(primary: primary, secondary: secondary);
});

final Provider<WorkoutPlanImportService> workoutPlanImportServiceProvider =
    Provider<WorkoutPlanImportService>((Ref<WorkoutPlanImportService> ref) {
  return WorkoutPlanImportService(
    parser: ref.read(workoutPlanParserProvider),
    repository: ref.read(workoutRepositoryProvider),
  );
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
}

final AsyncNotifierProvider<LoadedWorkoutPlansNotifier, List<WorkoutPlan>> loadedWorkoutPlansNotifierProvider =
    AsyncNotifierProvider<LoadedWorkoutPlansNotifier, List<WorkoutPlan>>(() {
  return LoadedWorkoutPlansNotifier();
});
