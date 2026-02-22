import 'package:workout_app_rewrite/features/active_workout/application/workout_transition_event.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_phase.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_state.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

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
  }) : _workout = workout;

  final Workout _workout;
  WorkoutState _state = const WorkoutState.idle();
  final List<WorkoutTransitionEvent> _events = <WorkoutTransitionEvent>[];

  WorkoutState get state => _state;
  Workout get workout => _workout;
  List<WorkoutTransitionEvent> get events => List<WorkoutTransitionEvent>.unmodifiable(_events);

  void start() {
    _assertPhase(<WorkoutPhase>{WorkoutPhase.idle}, 'start');
    _transitionTo(
      WorkoutPhase.prep,
      setIndex: 0,
      loopIndex: 0,
      moveIndex: 0,
    );
  }

  void startPrepNow() {
    _assertPhase(<WorkoutPhase>{WorkoutPhase.prep}, 'startPrepNow');
    _transitionTo(
      WorkoutPhase.move,
      setIndex: _state.setIndex,
      loopIndex: _state.loopIndex,
      moveIndex: _state.moveIndex,
    );
  }

  void completeMove() {
    _assertPhase(<WorkoutPhase>{WorkoutPhase.move}, 'completeMove');
    final _Cursor cursor = _cursor();
    final bool isLastMoveInSet = cursor.moveIndex == cursor.set.moves.length - 1;
    final bool isLastLoopInSet = cursor.loopIndex == cursor.set.loopCount - 1;
    final bool isLastSetInWorkout = cursor.setIndex == _workout.sets.length - 1;

    if (!isLastMoveInSet) {
      _transitionTo(
        WorkoutPhase.prep,
        setIndex: cursor.setIndex,
        loopIndex: cursor.loopIndex,
        moveIndex: cursor.moveIndex + 1,
      );
      return;
    }

    if (!isLastLoopInSet) {
      final int nextLoopIndex = cursor.loopIndex + 1;
      if (cursor.set.restBetweenLoopsSeconds > 0) {
        _transitionTo(
          WorkoutPhase.restBetweenLoops,
          setIndex: cursor.setIndex,
          loopIndex: nextLoopIndex,
          moveIndex: 0,
        );
        return;
      }

      _transitionTo(
        WorkoutPhase.prep,
        setIndex: cursor.setIndex,
        loopIndex: nextLoopIndex,
        moveIndex: 0,
      );
      return;
    }

    if (!isLastSetInWorkout) {
      _transitionTo(
        WorkoutPhase.prep,
        setIndex: cursor.setIndex + 1,
        loopIndex: 0,
        moveIndex: 0,
      );
      return;
    }

    _transitionTo(
      WorkoutPhase.completed,
      setIndex: cursor.setIndex,
      loopIndex: cursor.loopIndex,
      moveIndex: cursor.moveIndex,
    );
  }

  void completeRest() {
    _assertPhase(<WorkoutPhase>{WorkoutPhase.rest}, 'completeRest');
    final _Cursor cursor = _cursor();
    final bool isLastMoveInSet = cursor.moveIndex == cursor.set.moves.length - 1;

    if (!isLastMoveInSet) {
      _transitionTo(
        WorkoutPhase.prep,
        setIndex: cursor.setIndex,
        loopIndex: cursor.loopIndex,
        moveIndex: cursor.moveIndex + 1,
      );
      return;
    }

    final bool isLastSetInWorkout = cursor.setIndex == _workout.sets.length - 1;
    if (isLastSetInWorkout) {
      _transitionTo(
        WorkoutPhase.completed,
        setIndex: cursor.setIndex,
        loopIndex: cursor.loopIndex,
        moveIndex: cursor.moveIndex,
      );
      return;
    }

    _transitionTo(
      WorkoutPhase.prep,
      setIndex: cursor.setIndex + 1,
      loopIndex: 0,
      moveIndex: 0,
    );
  }

  void completeRestBetweenLoops() {
    _assertPhase(<WorkoutPhase>{WorkoutPhase.restBetweenLoops}, 'completeRestBetweenLoops');
    final _Cursor cursor = _cursor();
    _transitionTo(
      WorkoutPhase.prep,
      setIndex: cursor.setIndex,
      loopIndex: cursor.loopIndex,
      moveIndex: cursor.moveIndex,
    );
  }

  void skipMove() {
    _assertPhase(<WorkoutPhase>{WorkoutPhase.move}, 'skipMove');
    completeMove();
  }

  void skipRest() {
    _assertPhase(
      <WorkoutPhase>{WorkoutPhase.rest, WorkoutPhase.restBetweenLoops},
      'skipRest',
    );
    if (_state.phase == WorkoutPhase.restBetweenLoops) {
      completeRestBetweenLoops();
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
        WorkoutPhase.restBetweenLoops,
      },
      'pause',
    );
    _transitionTo(
      WorkoutPhase.paused,
      setIndex: _state.setIndex,
      loopIndex: _state.loopIndex,
      moveIndex: _state.moveIndex,
      pausedFrom: _state.phase,
    );
  }

  void resume() {
    _assertPhase(<WorkoutPhase>{WorkoutPhase.paused}, 'resume');
    final WorkoutPhase? pausedFrom = _state.pausedFrom;
    if (pausedFrom == null) {
      throw const InvalidTransitionException('Cannot resume because pausedFrom is null.');
    }
    _transitionTo(
      pausedFrom,
      setIndex: _state.setIndex,
      loopIndex: _state.loopIndex,
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
        WorkoutPhase.restBetweenLoops,
        WorkoutPhase.paused,
      },
      'abandon',
    );
    _transitionTo(
      WorkoutPhase.abandoned,
      setIndex: _state.setIndex,
      loopIndex: _state.loopIndex,
      moveIndex: _state.moveIndex,
    );
  }

  void finishEarly() {
    _assertPhase(
      <WorkoutPhase>{
        WorkoutPhase.prep,
        WorkoutPhase.move,
        WorkoutPhase.rest,
        WorkoutPhase.restBetweenLoops,
        WorkoutPhase.paused,
      },
      'finishEarly',
    );
    _transitionTo(
      WorkoutPhase.completedEarly,
      setIndex: _state.setIndex,
      loopIndex: _state.loopIndex,
      moveIndex: _state.moveIndex,
    );
  }

  _Cursor _cursor() {
    final int setIndex = _state.setIndex;
    final WorkoutSet set = _workout.sets[setIndex];
    return _Cursor(
      setIndex: setIndex,
      loopIndex: _state.loopIndex,
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
    required int loopIndex,
    required int moveIndex,
    WorkoutPhase? pausedFrom,
    bool clearPausedFrom = false,
  }) {
    final WorkoutPhase from = _state.phase;
    _state = _state.copyWith(
      phase: to,
      setIndex: setIndex,
      loopIndex: loopIndex,
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
        loopIndex: loopIndex,
        moveIndex: moveIndex,
      ),
    );
  }
}

class _Cursor {
  const _Cursor({
    required this.setIndex,
    required this.loopIndex,
    required this.moveIndex,
    required this.set,
  });

  final int setIndex;
  final int loopIndex;
  final int moveIndex;
  final WorkoutSet set;
}
