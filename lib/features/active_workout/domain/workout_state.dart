import 'package:workout_app_rewrite/features/active_workout/domain/workout_phase.dart';

class WorkoutState {
  const WorkoutState({
    required this.phase,
    required this.workoutIndex,
    required this.setIndex,
    required this.lapIndex,
    required this.moveIndex,
    required this.transitionCount,
    this.pausedFrom,
  });

  const WorkoutState.idle()
      : phase = WorkoutPhase.idle,
        workoutIndex = 0,
        setIndex = 0,
        lapIndex = 0,
        moveIndex = 0,
        transitionCount = 0,
        pausedFrom = null;

  final WorkoutPhase phase;
  final int workoutIndex;
  final int setIndex;
  final int lapIndex;
  final int moveIndex;
  final int transitionCount;
  final WorkoutPhase? pausedFrom;

  bool get isTerminal =>
      phase == WorkoutPhase.completed ||
      phase == WorkoutPhase.completedEarly ||
      phase == WorkoutPhase.abandoned;

  WorkoutState copyWith({
    WorkoutPhase? phase,
    int? workoutIndex,
    int? setIndex,
    int? lapIndex,
    int? moveIndex,
    int? transitionCount,
    WorkoutPhase? pausedFrom,
    bool clearPausedFrom = false,
  }) {
    return WorkoutState(
      phase: phase ?? this.phase,
      workoutIndex: workoutIndex ?? this.workoutIndex,
      setIndex: setIndex ?? this.setIndex,
      lapIndex: lapIndex ?? this.lapIndex,
      moveIndex: moveIndex ?? this.moveIndex,
      transitionCount: transitionCount ?? this.transitionCount,
      pausedFrom: clearPausedFrom ? null : pausedFrom ?? this.pausedFrom,
    );
  }
}
