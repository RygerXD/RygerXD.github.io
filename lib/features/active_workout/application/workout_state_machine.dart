import 'package:workout_app_rewrite/features/active_workout/application/workout_transition_event.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_phase.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_state.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_runtime_expansion.dart';

class InvalidTransitionException implements Exception {
  const InvalidTransitionException(this.message);

  final String message;

  @override
  String toString() {
    return 'InvalidTransitionException($message)';
  }
}

class WorkoutStateMachine {
  WorkoutStateMachine({
    required Workout workout,
  }) : _workout = expandRepeatedMoveSets(workout);

  final Workout _workout;
  WorkoutState _state = const WorkoutState.idle();
  final List<WorkoutTransitionEvent> _events = <WorkoutTransitionEvent>[];

  WorkoutState get state => _state;
  Workout get workout => _workout;
  List<WorkoutTransitionEvent> get events =>
      List<WorkoutTransitionEvent>.unmodifiable(_events);

  void start() {
    _assertPhase(<WorkoutPhase>{WorkoutPhase.idle}, 'start');
    _transitionTo(
      WorkoutPhase.prep,
      setIndex: 0,
      lapIndex: 0,
      moveIndex: 0,
    );
  }

  void startPrepNow() {
    _assertPhase(<WorkoutPhase>{WorkoutPhase.prep}, 'startPrepNow');
    _transitionTo(
      WorkoutPhase.move,
      setIndex: _state.setIndex,
      lapIndex: _state.lapIndex,
      moveIndex: _state.moveIndex,
    );
  }

  void completeMove() {
    _assertPhase(<WorkoutPhase>{WorkoutPhase.move}, 'completeMove');
    final _Cursor cursor = _cursor();
    final WorkoutMove move = cursor.set.moves[cursor.moveIndex];
    if (move.finishTimeSeconds > 0) {
      _transitionTo(
        WorkoutPhase.rest,
        setIndex: cursor.setIndex,
        lapIndex: cursor.lapIndex,
        moveIndex: cursor.moveIndex,
      );
      return;
    }

    _advanceAfterMove(cursor);
  }

  void completeRest() {
    _assertPhase(<WorkoutPhase>{WorkoutPhase.rest}, 'completeRest');
    _advanceAfterMove(_cursor());
  }

  void _advanceAfterMove(_Cursor cursor) {
    final bool isLastMoveInSet =
        cursor.moveIndex == cursor.set.moves.length - 1;
    final bool isLastLapInSet = cursor.lapIndex == cursor.set.lapCount - 1;
    final bool isLastSetInWorkout = cursor.setIndex == _workout.sets.length - 1;

    if (!isLastMoveInSet) {
      _transitionTo(
        WorkoutPhase.prep,
        setIndex: cursor.setIndex,
        lapIndex: cursor.lapIndex,
        moveIndex: cursor.moveIndex + 1,
      );
      return;
    }

    if (!isLastLapInSet) {
      final int nextLapIndex = cursor.lapIndex + 1;
      if (cursor.set.restBetweenLapsSeconds > 0) {
        _transitionTo(
          WorkoutPhase.restBetweenLaps,
          setIndex: cursor.setIndex,
          lapIndex: nextLapIndex,
          moveIndex: 0,
        );
        return;
      }

      _transitionTo(
        WorkoutPhase.prep,
        setIndex: cursor.setIndex,
        lapIndex: nextLapIndex,
        moveIndex: 0,
      );
      return;
    }

    if (!isLastSetInWorkout) {
      _transitionTo(
        WorkoutPhase.prep,
        setIndex: cursor.setIndex + 1,
        lapIndex: 0,
        moveIndex: 0,
      );
      return;
    }

    _transitionTo(
      WorkoutPhase.completed,
      setIndex: cursor.setIndex,
      lapIndex: cursor.lapIndex,
      moveIndex: cursor.moveIndex,
    );
  }

  void completeRestBetweenLaps() {
    _assertPhase(<WorkoutPhase>{WorkoutPhase.restBetweenLaps},
        'completeRestBetweenLaps');
    final _Cursor cursor = _cursor();
    _transitionTo(
      WorkoutPhase.prep,
      setIndex: cursor.setIndex,
      lapIndex: cursor.lapIndex,
      moveIndex: cursor.moveIndex,
    );
  }

  void skipMove() {
    _assertPhase(<WorkoutPhase>{WorkoutPhase.move}, 'skipMove');
    _advanceAfterMove(_cursor());
  }

  void skipRest() {
    _assertPhase(
      <WorkoutPhase>{WorkoutPhase.rest, WorkoutPhase.restBetweenLaps},
      'skipRest',
    );
    if (_state.phase == WorkoutPhase.restBetweenLaps) {
      completeRestBetweenLaps();
      return;
    }
    completeRest();
  }

  void pause() {
    _assertPhase(
      <WorkoutPhase>{
        WorkoutPhase.prep,
        WorkoutPhase.move,
        WorkoutPhase.rest,
        WorkoutPhase.restBetweenLaps,
      },
      'pause',
    );
    _transitionTo(
      WorkoutPhase.paused,
      setIndex: _state.setIndex,
      lapIndex: _state.lapIndex,
      moveIndex: _state.moveIndex,
      pausedFrom: _state.phase,
    );
  }

  void resume() {
    _assertPhase(<WorkoutPhase>{WorkoutPhase.paused}, 'resume');
    final WorkoutPhase? pausedFrom = _state.pausedFrom;
    if (pausedFrom == null) {
      throw const InvalidTransitionException(
          'Cannot resume because pausedFrom is null.');
    }
    _transitionTo(
      pausedFrom,
      setIndex: _state.setIndex,
      lapIndex: _state.lapIndex,
      moveIndex: _state.moveIndex,
      clearPausedFrom: true,
    );
  }

  void abandon() {
    _assertPhase(
      <WorkoutPhase>{
        WorkoutPhase.prep,
        WorkoutPhase.move,
        WorkoutPhase.rest,
        WorkoutPhase.restBetweenLaps,
        WorkoutPhase.paused,
      },
      'abandon',
    );
    _transitionTo(
      WorkoutPhase.abandoned,
      setIndex: _state.setIndex,
      lapIndex: _state.lapIndex,
      moveIndex: _state.moveIndex,
    );
  }

  void finishEarly() {
    _assertPhase(
      <WorkoutPhase>{
        WorkoutPhase.prep,
        WorkoutPhase.move,
        WorkoutPhase.rest,
        WorkoutPhase.restBetweenLaps,
        WorkoutPhase.paused,
      },
      'finishEarly',
    );
    _transitionTo(
      WorkoutPhase.completedEarly,
      setIndex: _state.setIndex,
      lapIndex: _state.lapIndex,
      moveIndex: _state.moveIndex,
    );
  }

  _Cursor _cursor() {
    final int setIndex = _state.setIndex;
    final WorkoutSet set = _workout.sets[setIndex];
    return _Cursor(
      setIndex: setIndex,
      lapIndex: _state.lapIndex,
      moveIndex: _state.moveIndex,
      set: set,
    );
  }

  void _assertPhase(Set<WorkoutPhase> allowed, String action) {
    if (!allowed.contains(_state.phase)) {
      throw InvalidTransitionException(
        'Invalid action "$action" in phase ${_state.phase.name}. Allowed: ${allowed.map((WorkoutPhase p) => p.name).join(', ')}',
      );
    }
  }

  void _transitionTo(
    WorkoutPhase to, {
    required int setIndex,
    required int lapIndex,
    required int moveIndex,
    WorkoutPhase? pausedFrom,
    bool clearPausedFrom = false,
  }) {
    final WorkoutPhase from = _state.phase;
    _state = _state.copyWith(
      phase: to,
      setIndex: setIndex,
      lapIndex: lapIndex,
      moveIndex: moveIndex,
      pausedFrom: pausedFrom,
      clearPausedFrom: clearPausedFrom,
      transitionCount: _state.transitionCount + 1,
    );
    _events.add(
      WorkoutTransitionEvent(
        from: from,
        to: to,
        timestampUtc: DateTime.now().toUtc(),
        setIndex: setIndex,
        lapIndex: lapIndex,
        moveIndex: moveIndex,
      ),
    );
  }
}

class _Cursor {
  const _Cursor({
    required this.setIndex,
    required this.lapIndex,
    required this.moveIndex,
    required this.set,
  });

  final int setIndex;
  final int lapIndex;
  final int moveIndex;
  final WorkoutSet set;
}
