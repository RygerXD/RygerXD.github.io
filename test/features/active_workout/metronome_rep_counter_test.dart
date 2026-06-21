import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/active_workout/application/metronome_rep_counter.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  group('metronomeRepsForElapsedTime', () {
    test('counts one rep per two metronome beats for duration moves', () {
      const WorkoutMove move = WorkoutMove(
        workoutMoveId: 'm1',
        moveId: 'e1',
        type: MoveType.duration,
        durationSeconds: 30,
        metronomeSpeed: 60,
      );

      expect(metronomeRepsForElapsedTime(move: move, elapsedSeconds: 30), 15);
    });

    test('uses elapsed time for early completion', () {
      const WorkoutMove move = WorkoutMove(
        workoutMoveId: 'm1',
        moveId: 'e1',
        type: MoveType.duration,
        durationSeconds: 30,
        metronomeSpeed: 120,
      );

      expect(metronomeRepsForElapsedTime(move: move, elapsedSeconds: 15), 15);
    });

    test('returns null when the move has no metronome', () {
      const WorkoutMove move = WorkoutMove(
        workoutMoveId: 'm1',
        moveId: 'e1',
        type: MoveType.duration,
        durationSeconds: 30,
      );

      expect(
          metronomeRepsForElapsedTime(move: move, elapsedSeconds: 30), isNull);
    });
  });
}
