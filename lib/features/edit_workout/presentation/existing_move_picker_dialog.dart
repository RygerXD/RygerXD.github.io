import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class ExistingMovePickerDialog extends StatelessWidget {
  const ExistingMovePickerDialog({
    super.key,
    required this.plans,
  });

  final List<WorkoutPlan> plans;

  @override
  Widget build(BuildContext context) {
    // Extract all moves with their associated exercise
    final Map<String, MoveWithExercise> uniqueMoves = <String, MoveWithExercise>{};

    for (final WorkoutPlan plan in plans) {
      final Map<String, Exercise> exerciseMap = <String, Exercise>{
        for (final Exercise e in plan.exercises) e.exerciseId: e,
      };

      for (final Workout workout in plan.workouts) {
        for (final WorkoutSet set in workout.sets) {
          for (final Move move in set.moves) {
            final Exercise? exercise = exerciseMap[move.exerciseId];
            if (exercise != null) {
              // Create a signature so we don't show identical moves multiple times
              final String signature = '${exercise.name}_${move.type.name}_${move.repCount}_${move.durationSeconds}';
              if (!uniqueMoves.containsKey(signature)) {
                uniqueMoves[signature] = MoveWithExercise(move: move, exercise: exercise);
              }
            }
          }
        }
      }
    }

    final List<MoveWithExercise> movesList = uniqueMoves.values.toList()
      ..sort((MoveWithExercise a, MoveWithExercise b) => a.exercise.name.compareTo(b.exercise.name));

    return AlertDialog(
      title: const Text('Select Existing Move'),
      content: SizedBox(
        width: double.maxFinite,
        child: movesList.isEmpty
            ? const Center(child: Text('No existing moves found.'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: movesList.length,
                itemBuilder: (BuildContext context, int index) {
                  final MoveWithExercise item = movesList[index];
                  final Move move = item.move;
                  final Exercise exercise = item.exercise;

                  return ListTile(
                    title: Text(exercise.name),
                    subtitle: Text(
                      move.type == MoveType.reps
                          ? '${move.repCount ?? 0} reps'
                          : '${move.durationSeconds ?? 0} seconds',
                    ),
                    onTap: () {
                      // Return a new move duplicating the properties but giving a new moveId
                      final Move duplicatedMove = Move(
                        moveId: const Uuid().v4(),
                        exerciseId: move.exerciseId,
                        type: move.type,
                        prepTimeSeconds: move.prepTimeSeconds,
                        repCount: move.repCount,
                        durationSeconds: move.durationSeconds,
                        finishTimeSeconds: move.finishTimeSeconds,
                        targetWeight: move.targetWeight,
                        targetWeightUnit: move.targetWeightUnit,
                        metronomeSpeed: move.metronomeSpeed,
                      );
                      
                      // We must return both the Move and the Exercise in case the Workout Plan
                      // doesn't have this exercise yet.
                      Navigator.of(context).pop(MoveWithExercise(move: duplicatedMove, exercise: exercise));
                    },
                  );
                },
              ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
      ],
    );
  }
}

class MoveWithExercise {
  const MoveWithExercise({
    required this.move,
    required this.exercise,
  });

  final Move move;
  final Exercise exercise;
}
