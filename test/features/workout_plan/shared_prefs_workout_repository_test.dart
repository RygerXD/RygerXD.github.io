import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/shared_prefs_workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const WorkoutPlan samplePlan = WorkoutPlan(
    schemaVersion: 1,
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
            moves: <WorkoutMove>[
              WorkoutMove(
                workoutMoveId: 'm-1',
                moveId: 'ex-1',
                type: MoveType.reps,
                repCount: 10,
              ),
            ],
          ),
        ],
      ),
    ],
    moves: <Move>[
      Move(
        moveId: 'ex-1',
        name: 'Squat',
      ),
    ],
  );

  group('SharedPrefsWorkoutRepository', () {
    test('persists plans across repository instances', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs1 = await SharedPreferences.getInstance();
      final repo1 = SharedPrefsWorkoutRepository(prefs1);

      await repo1.savePlan(samplePlan);

      final prefs2 = await SharedPreferences.getInstance();
      final repo2 = SharedPrefsWorkoutRepository(prefs2);
      final plans = await repo2.getAllPlans();

      expect(plans, hasLength(1));
      expect(plans.single.planId, 'plan-1');
      expect(plans.single.name, 'Plan 1');
    });

    test('deletes plans by id', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final prefs = await SharedPreferences.getInstance();
      final repository = SharedPrefsWorkoutRepository(prefs);

      await repository.savePlan(samplePlan);
      await repository.deletePlan('plan-1');

      final plans = await repository.getAllPlans();
      expect(plans, isEmpty);
    });
  });
}
