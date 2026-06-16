import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_phase.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_state.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

WorkoutPhase displayWorkoutPhase(WorkoutState state) {
  if (state.phase == WorkoutPhase.paused) {
    return state.pausedFrom ?? WorkoutPhase.move;
  }
  return state.phase;
}

bool isInactiveWorkoutState(WorkoutState state) {
  return state.phase == WorkoutPhase.idle;
}

WorkoutPlan? findWorkoutPlanById(List<WorkoutPlan>? plans, String? planId) {
  if (plans == null || planId == null) {
    return null;
  }
  for (final WorkoutPlan plan in plans) {
    if (plan.planId == planId) {
      return plan;
    }
  }
  return null;
}

Move? resolveWorkoutMove(WorkoutMove workoutMove, WorkoutPlan? plan) {
  if (plan == null) {
    return null;
  }
  for (final Move planMove in plan.moves) {
    if (planMove.moveId == workoutMove.moveId) {
      return planMove;
    }
  }
  return null;
}

String moveDisplayLabel(String moveName, WorkoutMove move) {
  return switch (move.side) {
    MoveSide.left => 'Left $moveName',
    MoveSide.right => 'Right $moveName',
    null => moveName,
  };
}

WorkoutMove? nextMoveDuringRestPhase({
  required WorkoutPhase phase,
  required WorkoutState state,
  required Workout workout,
}) {
  if (phase == WorkoutPhase.restBetweenLaps) {
    return _moveAt(
      workout: workout,
      setIndex: state.setIndex,
      moveIndex: state.moveIndex,
    );
  }
  if (phase != WorkoutPhase.rest) {
    return null;
  }

  final WorkoutSet? currentSet = _setAt(workout, state.setIndex);
  if (currentSet == null) {
    return null;
  }

  final int nextMoveIndex = state.moveIndex + 1;
  if (nextMoveIndex < currentSet.moves.length) {
    return currentSet.moves[nextMoveIndex];
  }
  if (state.lapIndex + 1 < currentSet.lapCount) {
    return currentSet.moves.isEmpty ? null : currentSet.moves.first;
  }
  return _moveAt(
    workout: workout,
    setIndex: state.setIndex + 1,
    moveIndex: 0,
  );
}

Color activeWorkoutPhaseColor(WorkoutPhase phase) {
  if (phase == WorkoutPhase.prep) {
    return Colors.orange;
  }
  if (phase == WorkoutPhase.restBetweenLaps || phase == WorkoutPhase.rest) {
    return Colors.green;
  }
  return Colors.blue;
}

String activeWorkoutPhaseLabel(WorkoutPhase phase) {
  if (phase == WorkoutPhase.prep) {
    return 'Get Ready';
  }
  if (phase == WorkoutPhase.rest) {
    return 'Cooldown';
  }
  if (phase == WorkoutPhase.restBetweenLaps) {
    return 'Rest';
  }
  return 'Go!';
}

WorkoutSet? _setAt(Workout workout, int setIndex) {
  if (setIndex < 0 || setIndex >= workout.sets.length) {
    return null;
  }
  return workout.sets[setIndex];
}

WorkoutMove? _moveAt({
  required Workout workout,
  required int setIndex,
  required int moveIndex,
}) {
  final WorkoutSet? set = _setAt(workout, setIndex);
  if (set == null || moveIndex < 0 || moveIndex >= set.moves.length) {
    return null;
  }
  return set.moves[moveIndex];
}
