import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  test('custom sounds round-trip with plan and workout overrides', () {
    final CustomWorkoutSound planComplete = CustomWorkoutSound.fromBytes(
      fileName: 'plan-complete.mp3',
      mimeType: 'audio/mpeg',
      bytes: Uint8List.fromList(<int>[1, 2, 3]),
    );
    final CustomWorkoutSound workoutEarly = CustomWorkoutSound.fromBytes(
      fileName: 'workout-early.wav',
      mimeType: 'audio/wav',
      bytes: Uint8List.fromList(<int>[4, 5, 6]),
    );
    final WorkoutPlan plan = WorkoutPlan(
      schemaVersion: workoutPlanSchemaVersion,
      planId: 'plan-1',
      name: 'Plan',
      workoutCompleteSound: planComplete,
      workouts: <Workout>[
        Workout(
          workoutId: 'workout-1',
          title: 'Workout',
          workoutEndedEarlySound: workoutEarly,
          sets: const <WorkoutSet>[],
        ),
      ],
      moves: const <Move>[],
    );

    final WorkoutPlan restored = WorkoutPlan.fromJson(plan.toJson());

    expect(restored.workoutCompleteSound?.fileName, 'plan-complete.mp3');
    expect(restored.workoutCompleteSound?.bytes, <int>[1, 2, 3]);
    expect(
      restored.workouts.single.workoutEndedEarlySound?.fileName,
      'workout-early.wav',
    );
    expect(
      restored.workouts.single.workoutEndedEarlySound?.bytes,
      <int>[4, 5, 6],
    );
  });

  test('rejects custom sounds larger than the portable plan limit', () {
    expect(
      () => CustomWorkoutSound.fromBytes(
        fileName: 'too-large.mp3',
        mimeType: 'audio/mpeg',
        bytes: Uint8List(maxCustomWorkoutSoundBytes + 1),
      ),
      throwsArgumentError,
    );
  });
}
