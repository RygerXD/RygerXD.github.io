import 'package:workout_app_rewrite/features/active_workout/domain/workout_phase.dart';

class WorkoutTransitionEvent {
  const WorkoutTransitionEvent({
    required this.from,
    required this.to,
    required this.timestampUtc,
    required this.setIndex,
    required this.loopIndex,
    required this.moveIndex,
  });

  final WorkoutPhase from;
  final WorkoutPhase to;
  final DateTime timestampUtc;
  final int setIndex;
  final int loopIndex;
  final int moveIndex;
}
