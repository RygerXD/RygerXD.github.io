import 'package:workout_app_rewrite/core/utils/fuzzy_search.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class ReferencedExerciseEntry {
  const ReferencedExerciseEntry({
    required this.exercise,
    required this.planNames,
    required this.moveCount,
  });

  final Exercise exercise;
  final List<String> planNames;
  final int moveCount;
}

List<ReferencedExerciseEntry> collectReferencedExercises(
  List<WorkoutPlan> plans,
) {
  final Map<String, _MutableExerciseEntry> entries =
      <String, _MutableExerciseEntry>{};

  for (final WorkoutPlan plan in plans) {
    final Map<String, int> moveCountsByExerciseId = <String, int>{};
    for (final Workout workout in plan.workouts) {
      if (workout.isArchived) {
        continue;
      }
      for (final WorkoutSet set in workout.sets) {
        for (final Move move in set.moves) {
          moveCountsByExerciseId.update(
            move.exerciseId,
            (int count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }

    for (final Exercise exercise in plan.exercises) {
      final int moveCount = moveCountsByExerciseId[exercise.exerciseId] ?? 0;
      if (moveCount == 0) {
        continue;
      }
      final _MutableExerciseEntry entry = entries.putIfAbsent(
        exercise.exerciseId,
        () => _MutableExerciseEntry(exercise: exercise),
      );
      entry.planNames.add(plan.name);
      entry.moveCount += moveCount;
    }
  }

  final List<ReferencedExerciseEntry> result = entries.values
      .map((_MutableExerciseEntry entry) => entry.toEntry())
      .toList(growable: false);
  result.sort(
    (ReferencedExerciseEntry a, ReferencedExerciseEntry b) =>
        a.exercise.name.toLowerCase().compareTo(b.exercise.name.toLowerCase()),
  );
  return result;
}

List<Exercise> collectUniqueReferencedExercisesByName(
  List<WorkoutPlan> plans,
) {
  final Map<String, Exercise> exercisesByName = <String, Exercise>{};
  for (final ReferencedExerciseEntry entry
      in collectReferencedExercises(plans)) {
    final String key = entry.exercise.name.trim().toLowerCase();
    exercisesByName.putIfAbsent(key, () => entry.exercise);
  }

  return exercisesByName.values.toList(growable: false)
    ..sort((Exercise a, Exercise b) => a.name.compareTo(b.name));
}

List<T> filterByFuzzyExerciseName<T>({
  required List<T> entries,
  required String query,
  required Exercise Function(T entry) exerciseFor,
}) {
  final String normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return entries;
  }

  final List<_ScoredEntry<T>> matches = <_ScoredEntry<T>>[];
  for (final T entry in entries) {
    final Exercise exercise = exerciseFor(entry);
    final int? score = fuzzyScore(
      exercise.name.toLowerCase(),
      normalizedQuery,
    );
    if (score != null) {
      matches.add(_ScoredEntry<T>(
        entry: entry,
        exerciseName: exercise.name,
        score: score,
      ));
    }
  }

  matches.sort((_ScoredEntry<T> a, _ScoredEntry<T> b) {
    final int scoreCompare = a.score.compareTo(b.score);
    if (scoreCompare != 0) {
      return scoreCompare;
    }
    return a.exerciseName.compareTo(b.exerciseName);
  });

  return matches
      .map((_ScoredEntry<T> match) => match.entry)
      .toList(growable: false);
}

class _MutableExerciseEntry {
  _MutableExerciseEntry({
    required this.exercise,
  });

  final Exercise exercise;
  final Set<String> planNames = <String>{};
  int moveCount = 0;

  ReferencedExerciseEntry toEntry() {
    final List<String> sortedPlanNames = planNames.toList(growable: false)
      ..sort();
    return ReferencedExerciseEntry(
      exercise: exercise,
      planNames: sortedPlanNames,
      moveCount: moveCount,
    );
  }
}

class _ScoredEntry<T> {
  const _ScoredEntry({
    required this.entry,
    required this.exerciseName,
    required this.score,
  });

  final T entry;
  final String exerciseName;
  final int score;
}
