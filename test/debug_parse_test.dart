import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  test('WorkoutPlan JSON roundtrip', () {
    final WorkoutPlan original = WorkoutPlan(
      schemaVersion: 1,
      planId: 'plan-1',
      name: 'Test Plan',
      workouts: [
        Workout(
          workoutId: 'workout-1',
          title: 'Workout 1',
          sets: [
            WorkoutSet(
              setId: 'set-1',
              loopCount: 3,
              restBetweenLoopsSeconds: 60,
              moves: [
                Move(
                  moveId: 'move-1',
                  exerciseId: 'exercise-1',
                  type: MoveType.reps,
                  repCount: 10,
                ),
              ],
            ),
          ],
        ),
      ],
      exercises: [
        Exercise(
          exerciseId: 'exercise-1',
          name: 'Pushup',
        ),
      ],
    );

    final String jsonString = jsonEncode(original.toJson());
    final Map<String, dynamic> decoded = jsonDecode(jsonString) as Map<String, dynamic>;
    
    // This will throw if fromJson is broken
    final WorkoutPlan restored = WorkoutPlan.fromJson(decoded);
    
    expect(restored.planId, original.planId);
  });
}
