import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

int? metronomeRepsForElapsedTime({
  required WorkoutMove move,
  required int elapsedSeconds,
}) {
  final int? bpm = move.metronomeSpeed;
  if (move.type != MoveType.duration || bpm == null || elapsedSeconds <= 0) {
    return null;
  }

  return (elapsedSeconds * bpm / 120).round();
}
