import 'package:flutter/material.dart';
import 'package:workout_app_rewrite/core/utils/app_formatters.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class ExistingMovePickerDialog extends StatefulWidget {
  const ExistingMovePickerDialog({
    super.key,
    required this.plans,
  });

  final List<WorkoutPlan> plans;

  @override
  State<ExistingMovePickerDialog> createState() =>
      _ExistingMovePickerDialogState();
}

class _ExistingMovePickerDialogState extends State<ExistingMovePickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  late final List<Exercise> _exercises = _collectExercises();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Exercise> filteredExercises = _filteredExercises();

    return AlertDialog(
      title: const Text('Select Existing Exercise'),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search exercises',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.search),
              ),
              autofocus: true,
              onChanged: (String value) {
                setState(() {
                  _query = value;
                });
              },
            ),
            const SizedBox(height: 12),
            Flexible(
              child: _exercises.isEmpty
                  ? const Center(child: Text('No existing exercises found.'))
                  : filteredExercises.isEmpty
                      ? const Center(child: Text('No matching exercises.'))
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: filteredExercises.length,
                          itemBuilder: (BuildContext context, int index) {
                            final Exercise exercise = filteredExercises[index];
                            return ListTile(
                              leading: _ExerciseThumbnail(
                                imageUrl: optionalText(exercise.imageUrl),
                              ),
                              title: Text(exercise.name),
                              onTap: () => Navigator.of(context).pop(exercise),
                            );
                          },
                        ),
            ),
          ],
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

  List<Exercise> _collectExercises() {
    final Map<String, Exercise> exercisesByName = <String, Exercise>{};

    for (final WorkoutPlan plan in widget.plans) {
      final Map<String, Exercise> exerciseMap = <String, Exercise>{
        for (final Exercise exercise in plan.exercises)
          exercise.exerciseId: exercise,
      };

      for (final Workout workout in plan.workouts) {
        for (final WorkoutSet set in workout.sets) {
          for (final Move move in set.moves) {
            final Exercise? exercise = exerciseMap[move.exerciseId];
            if (exercise == null) {
              continue;
            }
            final String key = exercise.name.trim().toLowerCase();
            exercisesByName.putIfAbsent(key, () => exercise);
          }
        }
      }
    }

    return exercisesByName.values.toList(growable: false)
      ..sort((Exercise a, Exercise b) => a.name.compareTo(b.name));
  }

  List<Exercise> _filteredExercises() {
    final String query = _query.trim().toLowerCase();
    if (query.isEmpty) {
      return _exercises;
    }

    final List<_ScoredExercise> matches = <_ScoredExercise>[];
    for (final Exercise exercise in _exercises) {
      final int? score = _fuzzyScore(exercise.name.toLowerCase(), query);
      if (score != null) {
        matches.add(_ScoredExercise(exercise: exercise, score: score));
      }
    }

    matches.sort((_ScoredExercise a, _ScoredExercise b) {
      final int scoreCompare = a.score.compareTo(b.score);
      if (scoreCompare != 0) {
        return scoreCompare;
      }
      return a.exercise.name.compareTo(b.exercise.name);
    });

    return matches
        .map((_ScoredExercise match) => match.exercise)
        .toList(growable: false);
  }

  int? _fuzzyScore(String candidate, String query) {
    if (candidate.contains(query)) {
      return candidate.indexOf(query);
    }

    int candidateIndex = 0;
    int score = 0;
    for (final int queryCodeUnit in query.codeUnits) {
      final int matchIndex =
          candidate.indexOf(String.fromCharCode(queryCodeUnit), candidateIndex);
      if (matchIndex < 0) {
        return null;
      }
      score += matchIndex - candidateIndex + 1;
      candidateIndex = matchIndex + 1;
    }
    return score + candidate.length;
  }
}

class _ExerciseThumbnail extends StatelessWidget {
  const _ExerciseThumbnail({
    required this.imageUrl,
  });

  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl == null) {
      return const CircleAvatar(child: Icon(Icons.fitness_center));
    }

    return CircleAvatar(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      foregroundImage: NetworkImage(imageUrl!),
      onForegroundImageError: (_, __) {},
      child: const Icon(Icons.fitness_center),
    );
  }
}

class _ScoredExercise {
  const _ScoredExercise({
    required this.exercise,
    required this.score,
  });

  final Exercise exercise;
  final int score;
}
