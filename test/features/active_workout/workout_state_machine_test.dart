import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/active_workout/application/workout_state_machine.dart';
import 'package:workout_app_rewrite/features/active_workout/domain/workout_phase.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  group('WorkoutStateMachine', () {
    test('runs basic start -> move -> complete flow', () {
      final WorkoutStateMachine machine =
          WorkoutStateMachine(workout: _singleSetWorkout(loopCount: 1));
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
          WorkoutStateMachine(workout: _singleSetWorkout(loopCount: 1));
      machine.start();
      machine.startPrepNow();
      machine.pause();
      expect(machine.state.phase, WorkoutPhase.paused);

      machine.resume();
      expect(machine.state.phase, WorkoutPhase.move);
    });

    test('transitions through rest_between_loops when looping', () {
      final WorkoutStateMachine machine =
          WorkoutStateMachine(workout: _singleSetWorkout(loopCount: 2));
      machine.start();
      machine.startPrepNow();

      machine.completeMove();
      expect(machine.state.phase, WorkoutPhase.restBetweenLoops);

      machine.completeRestBetweenLoops();
      expect(machine.state.phase, WorkoutPhase.prep);
      expect(machine.state.loopIndex, 1);

      machine.startPrepNow();
      machine.completeMove();
      expect(machine.state.phase, WorkoutPhase.completed);
    });

    test('throws for invalid transition', () {
      final WorkoutStateMachine machine =
          WorkoutStateMachine(workout: _singleSetWorkout(loopCount: 1));
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
            loopCount: 1,
            restBetweenLoopsSeconds: 30,
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
            loopCount: 1,
            restBetweenLoopsSeconds: 30,
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

    test('returns to prep between moves in the same loop', () {
      final Workout workout = Workout(
        workoutId: 'w3',
        title: 'W3',
        sets: <WorkoutSet>[
          WorkoutSet(
            setId: 's1',
            loopCount: 1,
            restBetweenLoopsSeconds: 0,
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
        workout: _singleSetWorkout(loopCount: 1, setCount: 2),
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

    test('uses move cooldown before advancing to the next move', () {
      final Workout workout = Workout(
        workoutId: 'w4',
        title: 'W4',
        sets: <WorkoutSet>[
          WorkoutSet(
            setId: 's1',
            loopCount: 1,
            restBetweenLoopsSeconds: 0,
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

    test('returns to loop rest after cooldown at the end of a loop', () {
      final WorkoutStateMachine machine = WorkoutStateMachine(
        workout: _singleSetWorkout(loopCount: 2, finishTimeSeconds: 10),
      );
      machine.start();
      machine.startPrepNow();
      machine.completeMove();
      expect(machine.state.phase, WorkoutPhase.rest);

      machine.completeRest();
      expect(machine.state.phase, WorkoutPhase.restBetweenLoops);
      expect(machine.state.loopIndex, 1);
      expect(machine.state.moveIndex, 0);
    });
  });
}

Workout _singleSetWorkout({
  required int loopCount,
  int finishTimeSeconds = 0,
  int setCount = 1,
}) {
  return Workout(
    workoutId: 'w1',
    title: 'W1',
    sets: <WorkoutSet>[
      WorkoutSet(
        setId: 's1',
        loopCount: loopCount,
        restBetweenLoopsSeconds: 30,
        moves: <Move>[
          Move(
            moveId: 'm1',
            exerciseId: 'e1',
            type: MoveType.reps,
            repCount: 10,
            finishTimeSeconds: finishTimeSeconds,
            setCount: setCount,
          ),
        ],
      ),
    ],
  );
}
