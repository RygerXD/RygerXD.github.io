import 'package:workout_app_rewrite/features/active_workout/domain/workout_phase.dart';

class WorkoutState {
  const WorkoutState({
    required this.phase,
    required this.workoutIndex,
    required this.setIndex,
    required this.loopIndex,
    required this.moveIndex,
    required this.transitionCount,
    this.pausedFrom,
  });

  const WorkoutState.idle()
      : phase = WorkoutPhase.idle,
        workoutIndex = 0,
        setIndex = 0,
        loopIndex = 0,
        moveIndex = 0,
        transitionCount = 0,
        pausedFrom = null;

  final WorkoutPhase phase;
  final int workoutIndex;
  final int setIndex;
  final int loopIndex;
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
    int? loopIndex,
    int? moveIndex,
    int? transitionCount,
    WorkoutPhase? pausedFrom,
    bool clearPausedFrom = false,
  }) {
    return WorkoutState(
      phase: phase ?? this.phase,
      workoutIndex: workoutIndex ?? this.workoutIndex,
      setIndex: setIndex ?? this.setIndex,
      loopIndex: loopIndex ?? this.loopIndex,
      moveIndex: moveIndex ?? this.moveIndex,
      transitionCount: transitionCount ?? this.transitionCount,
      pausedFrom: clearPausedFrom ? null : pausedFrom ?? this.pausedFrom,
    );
  }
}
