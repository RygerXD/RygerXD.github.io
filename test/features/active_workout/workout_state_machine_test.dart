import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/active_workout/application/workout_state_machine.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_phase.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  group('WorkoutStateMachine', () {
    test('runs basic start -> move -> complete flow', () {
      final WorkoutStateMachine machine =
          WorkoutStateMachine(workout: _singleSetWorkout(lapCount: 1));
      machine.start();
      expect(machine.state.phase, WorkoutPhase.prep);

      machine.startPrepNow();
      expect(machine.state.phase, WorkoutPhase.move);

      machine.completeMove();
      expect(machine.state.phase, WorkoutPhase.completed);
      expect(machine.events.isNotEmpty, true);
    });

    test('supports pause and resume', () {
      final WorkoutStateMachine machine =
          WorkoutStateMachine(workout: _singleSetWorkout(lapCount: 1));
      machine.start();
      machine.startPrepNow();
      machine.pause();
      expect(machine.state.phase, WorkoutPhase.paused);

      machine.resume();
      expect(machine.state.phase, WorkoutPhase.move);
    });

    test('transitions through rest_between_laps when lapping', () {
      final WorkoutStateMachine machine =
          WorkoutStateMachine(workout: _singleSetWorkout(lapCount: 2));
      machine.start();
      machine.startPrepNow();

      machine.completeMove();
      expect(machine.state.phase, WorkoutPhase.restBetweenLaps);

      machine.completeRestBetweenLaps();
      expect(machine.state.phase, WorkoutPhase.prep);
      expect(machine.state.lapIndex, 1);

      machine.startPrepNow();
      machine.completeMove();
      expect(machine.state.phase, WorkoutPhase.completed);
    });

    test('throws for invalid transition', () {
      final WorkoutStateMachine machine =
          WorkoutStateMachine(workout: _singleSetWorkout(lapCount: 1));
      expect(() => machine.completeMove(),
          throwsA(isA<InvalidTransitionException>()));
    });

    test('moves to prep for next set after finishing a set', () {
      final Workout workout = Workout(
        workoutId: 'w2',
        title: 'W2',
        sets: <WorkoutSet>[
          WorkoutSet(
            setId: 's1',
            lapCount: 1,
            restBetweenLapsSeconds: 30,
            moves: const <Move>[
              Move(
                moveId: 'm1',
                exerciseId: 'e1',
                type: MoveType.reps,
                repCount: 8,
              ),
            ],
          ),
          WorkoutSet(
            setId: 's2',
            lapCount: 1,
            restBetweenLapsSeconds: 30,
            moves: const <Move>[
              Move(
                moveId: 'm2',
                exerciseId: 'e1',
                type: MoveType.reps,
                repCount: 6,
              ),
            ],
          ),
        ],
      );

      final WorkoutStateMachine machine = WorkoutStateMachine(workout: workout);
      machine.start();
      machine.startPrepNow();
      machine.completeMove();
      expect(machine.state.phase, WorkoutPhase.prep);
      expect(machine.state.setIndex, 1);
      expect(machine.state.moveIndex, 0);
    });

    test('returns to prep between moves in the same lap', () {
      final Workout workout = Workout(
        workoutId: 'w3',
        title: 'W3',
        sets: <WorkoutSet>[
          WorkoutSet(
            setId: 's1',
            lapCount: 1,
            restBetweenLapsSeconds: 0,
            moves: const <Move>[
              Move(
                moveId: 'm1',
                exerciseId: 'e1',
                type: MoveType.reps,
                repCount: 8,
              ),
              Move(
                moveId: 'm2',
                exerciseId: 'e2',
                type: MoveType.reps,
                repCount: 6,
              ),
            ],
          ),
        ],
      );

      final WorkoutStateMachine machine = WorkoutStateMachine(workout: workout);
      machine.start();
      machine.startPrepNow();
      machine.completeMove();
      expect(machine.state.phase, WorkoutPhase.prep);
      expect(machine.state.moveIndex, 1);
    });

    test('expands a move set count into repeated move executions', () {
      final WorkoutStateMachine machine = WorkoutStateMachine(
        workout: _singleSetWorkout(lapCount: 1, setCount: 2),
      );
      machine.start();
      expect(machine.workout.sets.single.moves, hasLength(2));

      machine.startPrepNow();
      machine.completeMove();
      expect(machine.state.phase, WorkoutPhase.prep);
      expect(machine.state.moveIndex, 1);

      machine.startPrepNow();
      machine.completeMove();
      expect(machine.state.phase, WorkoutPhase.completed);
    });

    test('expands each-side moves into left and right executions', () {
      for (final MoveType type in MoveType.values) {
        final WorkoutStateMachine machine = WorkoutStateMachine(
          workout: _singleSetWorkout(
            lapCount: 1,
            moveType: type,
            repeatEachSide: true,
          ),
        );
        final List<Move> moves = machine.workout.sets.single.moves;

        expect(moves, hasLength(2));
        expect(moves.map((Move move) => move.side), <MoveSide>[
          MoveSide.left,
          MoveSide.right,
        ]);
        expect(moves.map((Move move) => move.repeatEachSide), <bool>[
          false,
          false,
        ]);
        expect(moves.map((Move move) => move.moveId), <String>[
          'm1:left',
          'm1:right',
        ]);
      }
    });

    test('runs left then right for each-side moves', () {
      final WorkoutStateMachine machine = WorkoutStateMachine(
        workout: _singleSetWorkout(lapCount: 1, repeatEachSide: true),
      );
      machine.start();
      expect(machine.workout.sets.single.moves.first.side, MoveSide.left);

      machine.startPrepNow();
      machine.completeMove();
      expect(machine.state.phase, WorkoutPhase.prep);
      expect(machine.state.moveIndex, 1);
      expect(machine.workout.sets.single.moves[1].side, MoveSide.right);

      machine.startPrepNow();
      machine.completeMove();
      expect(machine.state.phase, WorkoutPhase.completed);
    });

    test('uses move cooldown before advancing to the next move', () {
      final Workout workout = Workout(
        workoutId: 'w4',
        title: 'W4',
        sets: <WorkoutSet>[
          WorkoutSet(
            setId: 's1',
            lapCount: 1,
            restBetweenLapsSeconds: 0,
            moves: const <Move>[
              Move(
                moveId: 'm1',
                exerciseId: 'e1',
                type: MoveType.reps,
                repCount: 8,
                finishTimeSeconds: 15,
              ),
              Move(
                moveId: 'm2',
                exerciseId: 'e2',
                type: MoveType.reps,
                repCount: 6,
              ),
            ],
          ),
        ],
      );

      final WorkoutStateMachine machine = WorkoutStateMachine(workout: workout);
      machine.start();
      machine.startPrepNow();
      machine.completeMove();
      expect(machine.state.phase, WorkoutPhase.rest);
      expect(machine.state.moveIndex, 0);

      machine.completeRest();
      expect(machine.state.phase, WorkoutPhase.prep);
      expect(machine.state.moveIndex, 1);
    });

    test('returns to lap rest after cooldown at the end of a lap', () {
      final WorkoutStateMachine machine = WorkoutStateMachine(
        workout: _singleSetWorkout(lapCount: 2, finishTimeSeconds: 10),
      );
      machine.start();
      machine.startPrepNow();
      machine.completeMove();
      expect(machine.state.phase, WorkoutPhase.rest);

      machine.completeRest();
      expect(machine.state.phase, WorkoutPhase.restBetweenLaps);
      expect(machine.state.lapIndex, 1);
      expect(machine.state.moveIndex, 0);
    });
  });
}

Workout _singleSetWorkout({
  required int lapCount,
  int finishTimeSeconds = 0,
  int setCount = 1,
  MoveType moveType = MoveType.reps,
  bool repeatEachSide = false,
}) {
  return Workout(
    workoutId: 'w1',
    title: 'W1',
    sets: <WorkoutSet>[
      WorkoutSet(
        setId: 's1',
        lapCount: lapCount,
        restBetweenLapsSeconds: 30,
        moves: <Move>[
          Move(
            moveId: 'm1',
            exerciseId: 'e1',
            type: moveType,
            repCount: moveType == MoveType.reps ? 10 : null,
            durationSeconds: moveType == MoveType.duration ? 30 : null,
            finishTimeSeconds: finishTimeSeconds,
            setCount: setCount,
            repeatEachSide: repeatEachSide,
          ),
        ],
      ),
    ],
  );
}
