import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/in_memory_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/mirrored_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  const WorkoutPlan samplePlan = WorkoutPlan(
    schemaVersion: 2,
    planId: 'plan-1',
    name: 'Plan 1',
    workouts: <Workout>[
      Workout(
        workoutId: 'w-1',
        title: 'Workout A',
        sets: <WorkoutSet>[
          WorkoutSet(
            setId: 's-1',
            lapCount: 1,
            restBetweenLapsSeconds: 30,
            moves: <Move>[
              Move(
                moveId: 'm-1',
                exerciseId: 'ex-1',
                type: MoveType.reps,
                repCount: 10,
              ),
            ],
          ),
        ],
      ),
    ],
    exercises: <Exercise>[
      Exercise(
        exerciseId: 'ex-1',
        name: 'Squat',
      ),
    ],
  );

  group('MirroredWorkoutRepository', () {
    test('reads from secondary and seeds primary when primary is empty',
        () async {
      final InMemoryWorkoutRepository primary = InMemoryWorkoutRepository();
      final InMemoryWorkoutRepository secondary = InMemoryWorkoutRepository();
      await secondary.savePlan(samplePlan);

      final MirroredWorkoutRepository repository = MirroredWorkoutRepository(
        primary: primary,
        secondary: secondary,
      );

      final List<WorkoutPlan> loaded = await repository.getAllPlans();
      final List<WorkoutPlan> primaryLoaded = await primary.getAllPlans();

      expect(loaded, hasLength(1));
      expect(loaded.single.planId, 'plan-1');
      expect(primaryLoaded, hasLength(1));
      expect(primaryLoaded.single.planId, 'plan-1');
    });

    test('savePlan persists in primary even when secondary save fails',
        () async {
      final InMemoryWorkoutRepository primary = InMemoryWorkoutRepository();
      final _ThrowingWorkoutRepository secondary = _ThrowingWorkoutRepository();

      final MirroredWorkoutRepository repository = MirroredWorkoutRepository(
        primary: primary,
        secondary: secondary,
      );

      await repository.savePlan(samplePlan);
      final List<WorkoutPlan> primaryLoaded = await primary.getAllPlans();

      expect(primaryLoaded, hasLength(1));
      expect(primaryLoaded.single.planId, 'plan-1');
    });
  });
}

class _ThrowingWorkoutRepository implements WorkoutRepository {
  @override
  Future<void> deletePlan(String planId) async {
    throw Exception('delete failed');
  }

  @override
  Future<List<WorkoutPlan>> getAllPlans() async {
    throw Exception('getAll failed');
  }

  @override
  Future<WorkoutPlan?> getPlanById(String planId) async {
    throw Exception('getById failed');
  }

  @override
  Future<void> savePlan(WorkoutPlan plan) async {
    throw Exception('save failed');
  }
}
