import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_app_rewrite/features/active_workout/application/workout_state_machine.dart';
import 'package:workout_app_rewrite/features/active_workout/application/workout_transition_event.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_phase.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_state.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

final NotifierProvider<ActiveWorkoutController, WorkoutState> activeWorkoutControllerProvider =
    NotifierProvider<ActiveWorkoutController, WorkoutState>(ActiveWorkoutController.new);

class ActiveWorkoutController extends Notifier<WorkoutState> {
  WorkoutStateMachine? _machine;
  String? _planId;
  String? _sessionId;
  DateTime? _startedAt;

  Workout? get workout => _machine?.workout;
  String? get planId => _planId;

  WorkoutSet? get currentSet {
    final Workout? activeWorkout = _machine?.workout;
    if (activeWorkout == null || activeWorkout.sets.isEmpty) {
      return null;
    }
    if (state.setIndex < 0 || state.setIndex >= activeWorkout.sets.length) {
      return null;
    }
    return activeWorkout.sets[state.setIndex];
  }

  Move? get currentMove {
    final WorkoutSet? set = currentSet;
    if (set == null || set.moves.isEmpty) {
      return null;
    }
    if (state.moveIndex < 0 || state.moveIndex >= set.moves.length) {
      return null;
    }
    return set.moves[state.moveIndex];
  }

  @override
  WorkoutState build() {
    return const WorkoutState.idle();
  }

  void startWithWorkout(Workout workout, String planId) {
    _planId = planId;
    _sessionId = const Uuid().v4();
    _startedAt = DateTime.now();

    final WorkoutStateMachine machine = WorkoutStateMachine(workout: workout)..start();
    _machine = machine;
    state = machine.state;
  }

  List<WorkoutTransitionEvent> transitionEvents() {
    return _machine?.events ?? const <WorkoutTransitionEvent>[];
  }

  void startPrepNow() => _run((WorkoutStateMachine m) => m.startPrepNow());
  void completeMove() => _run((WorkoutStateMachine m) => m.completeMove());
  void completeRest() => _run((WorkoutStateMachine m) => m.completeRest());
  void completeRestBetweenLoops() => _run((WorkoutStateMachine m) => m.completeRestBetweenLoops());
  void skipMove() => _run((WorkoutStateMachine m) => m.skipMove());
  void skipRest() => _run((WorkoutStateMachine m) => m.skipRest());
  void pause() => _run((WorkoutStateMachine m) => m.pause());
  void resume() => _run((WorkoutStateMachine m) => m.resume());
  
  void abandon() {
    _run((WorkoutStateMachine m) => m.abandon());
    _saveSession('abandoned');
  }
  
  void finishEarly() {
    _run((WorkoutStateMachine m) => m.finishEarly());
    _saveSession('completed');
  }

  void clearActiveWorkout() {
    _machine = null;
    _planId = null;
    _sessionId = null;
    _startedAt = null;
    state = const WorkoutState.idle();
  }

  void _run(void Function(WorkoutStateMachine machine) action) {
    final WorkoutStateMachine? machine = _machine;
    if (machine == null) {
      return;
    }
    try {
      action(machine);
      state = machine.state;

      if (state.phase == WorkoutPhase.completed) {
        _saveSession('completed');
      }
    } on InvalidTransitionException {
      return;
    }
  }

  Future<void> _saveSession(String status) async {
    final WorkoutStateMachine? machine = _machine;
    if (machine == null || _planId == null || _sessionId == null || _startedAt == null) return;

    try {
      await ref.read(historyServiceProvider).saveSession(
        sessionId: _sessionId!,
        planId: _planId!,
        workoutId: machine.workout.workoutId,
        startedAt: _startedAt!,
        endedAt: DateTime.now(),
        status: status,
      );
    } catch (e) {
      debugPrint('[ActiveWorkoutController] Error saving session: $e');
    }
  }
}
