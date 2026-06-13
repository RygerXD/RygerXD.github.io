import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:workout_app_rewrite/features/active_workout/application/workout_state_machine.dart';
import 'package:workout_app_rewrite/features/active_workout/application/workout_transition_event.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_phase.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_state.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

final NotifierProvider<ActiveWorkoutController, WorkoutState>
    activeWorkoutControllerProvider =
    NotifierProvider<ActiveWorkoutController, WorkoutState>(
        ActiveWorkoutController.new);

class ActiveWorkoutController extends Notifier<WorkoutState> {
  WorkoutStateMachine? _machine;
  String? _planId;
  WorkoutPlan? _planSnapshot;
  String? _sessionId;
  DateTime? _startedAt;

  Workout? get workout => _machine?.workout;
  String? get planId => _planId;
  String? get sessionId => _sessionId;

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

  void startWithWorkout(
    Workout workout,
    String planId, {
    WorkoutPlan? planSnapshot,
  }) {
    _planId = planId;
    _planSnapshot = planSnapshot;
    _sessionId = const Uuid().v4();
    _startedAt = DateTime.now();

    final WorkoutStateMachine machine = WorkoutStateMachine(workout: workout)
      ..start();
    _machine = machine;
    state = machine.state;
  }

  List<WorkoutTransitionEvent> transitionEvents() {
    return _machine?.events ?? const <WorkoutTransitionEvent>[];
  }

  void startPrepNow() => _run((WorkoutStateMachine m) => m.startPrepNow());
  void completeMove() => _run((WorkoutStateMachine m) => m.completeMove());
  void completeRest() => _run((WorkoutStateMachine m) => m.completeRest());
  void completeRestBetweenLoops() =>
      _run((WorkoutStateMachine m) => m.completeRestBetweenLoops());
  void skipMove() => _run((WorkoutStateMachine m) => m.skipMove());
  void skipRest() => _run((WorkoutStateMachine m) => m.skipRest());
  void pause() => _run((WorkoutStateMachine m) => m.pause());
  void resume() => _run((WorkoutStateMachine m) => m.resume());

  void abandon() {
    final WorkoutStateMachine? machine = _machine;
    final String? planId = _planId;
    final WorkoutPlan? planSnapshot = _planSnapshot;
    final String? sessionId = _sessionId;
    final DateTime? startedAt = _startedAt;
    _run((WorkoutStateMachine m) => m.abandon());
    if (machine != null &&
        planId != null &&
        sessionId != null &&
        startedAt != null) {
      _saveSession(
          machine: machine,
          planId: planId,
          planSnapshot: planSnapshot,
          sessionId: sessionId,
          startedAt: startedAt,
          status: 'abandoned');
    }
  }

  void finishEarly() {
    final WorkoutStateMachine? machine = _machine;
    final String? planId = _planId;
    final WorkoutPlan? planSnapshot = _planSnapshot;
    final String? sessionId = _sessionId;
    final DateTime? startedAt = _startedAt;
    _run((WorkoutStateMachine m) => m.finishEarly());
    if (machine != null &&
        planId != null &&
        sessionId != null &&
        startedAt != null) {
      _saveSession(
          machine: machine,
          planId: planId,
          planSnapshot: planSnapshot,
          sessionId: sessionId,
          startedAt: startedAt,
          status: 'completed');
    }
  }

  void clearActiveWorkout() {
    _machine = null;
    _planId = null;
    _planSnapshot = null;
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

      // Capture session data BEFORE setting state. Setting state triggers
      // Riverpod listeners synchronously, which call _exitPlayer() and
      // clearActiveWorkout(), nulling _machine/_planId/_sessionId/_startedAt.
      final bool shouldSave = machine.state.phase == WorkoutPhase.completed;
      final String? planId = _planId;
      final WorkoutPlan? planSnapshot = _planSnapshot;
      final String? sessionId = _sessionId;
      final DateTime? startedAt = _startedAt;

      state = machine.state;

      if (shouldSave &&
          planId != null &&
          sessionId != null &&
          startedAt != null) {
        _saveSession(
            machine: machine,
            planId: planId,
            planSnapshot: planSnapshot,
            sessionId: sessionId,
            startedAt: startedAt,
            status: 'completed');
      }
    } on InvalidTransitionException {
      return;
    }
  }

  Future<void> _saveSession({
    required WorkoutStateMachine machine,
    required String planId,
    required WorkoutPlan? planSnapshot,
    required String sessionId,
    required DateTime startedAt,
    required String status,
  }) async {
    try {
      await ref.read(historyServiceProvider).saveSession(
            sessionId: sessionId,
            planId: planId,
            workoutId: machine.workout.workoutId,
            workoutName: machine.workout.title,
            workoutPlanSnapshot: planSnapshot,
            startedAt: startedAt,
            endedAt: DateTime.now(),
            status: status,
          );
    } catch (e) {
      debugPrint('[ActiveWorkoutController] Error saving session: $e');
    }
  }
}
