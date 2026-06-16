import 'package:workout_app_rewrite/core/utils/fuzzy_search.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class ReferencedMoveEntry {
  const ReferencedMoveEntry({
    required this.move,
    required this.planNames,
    required this.moveCount,
  });

  final Move move;
  final List<String> planNames;
  final int moveCount;
}

List<ReferencedMoveEntry> collectReferencedMoves(
  List<WorkoutPlan> plans,
) {
  final Map<String, _MutableMoveEntry> entries = <String, _MutableMoveEntry>{};

  for (final WorkoutPlan plan in plans) {
    final Map<String, int> moveCountsByMoveId = <String, int>{};
    for (final Workout workout in plan.workouts) {
      if (workout.isArchived) {
        continue;
      }
      for (final WorkoutSet set in workout.sets) {
        for (final WorkoutMove move in set.moves) {
          moveCountsByMoveId.update(
            move.moveId,
            (int count) => count + 1,
            ifAbsent: () => 1,
          );
        }
      }
    }

    for (final Move move in plan.moves) {
      final int moveCount = moveCountsByMoveId[move.moveId] ?? 0;
      if (moveCount == 0) {
        continue;
      }
      final _MutableMoveEntry entry = entries.putIfAbsent(
        move.moveId,
        () => _MutableMoveEntry(move: move),
      );
      entry.planNames.add(plan.name);
      entry.moveCount += moveCount;
    }
  }

  final List<ReferencedMoveEntry> result = entries.values
      .map((_MutableMoveEntry entry) => entry.toEntry())
      .toList(growable: false);
  result.sort(
    (ReferencedMoveEntry a, ReferencedMoveEntry b) =>
        a.move.name.toLowerCase().compareTo(b.move.name.toLowerCase()),
  );
  return result;
}

List<Move> collectUniqueReferencedMovesByName(
  List<WorkoutPlan> plans,
) {
  final Map<String, Move> movesByName = <String, Move>{};
  for (final ReferencedMoveEntry entry in collectReferencedMoves(plans)) {
    final String key = entry.move.name.trim().toLowerCase();
    movesByName.putIfAbsent(key, () => entry.move);
  }

  return movesByName.values.toList(growable: false)
    ..sort((Move a, Move b) => a.name.compareTo(b.name));
}

List<T> filterByFuzzyMoveName<T>({
  required List<T> entries,
  required String query,
  required Move Function(T entry) moveFor,
}) {
  final String normalizedQuery = query.trim().toLowerCase();
  if (normalizedQuery.isEmpty) {
    return entries;
  }

  final List<_ScoredEntry<T>> matches = <_ScoredEntry<T>>[];
  for (final T entry in entries) {
    final Move move = moveFor(entry);
    final int? score = fuzzyScore(
      move.name.toLowerCase(),
      normalizedQuery,
    );
    if (score != null) {
      matches.add(_ScoredEntry<T>(
        entry: entry,
        moveName: move.name,
        score: score,
      ));
    }
  }

  matches.sort((_ScoredEntry<T> a, _ScoredEntry<T> b) {
    final int scoreCompare = a.score.compareTo(b.score);
    if (scoreCompare != 0) {
      return scoreCompare;
    }
    return a.moveName.compareTo(b.moveName);
  });

  return matches
      .map((_ScoredEntry<T> match) => match.entry)
      .toList(growable: false);
}

class _MutableMoveEntry {
  _MutableMoveEntry({
    required this.move,
  });

  final Move move;
  final Set<String> planNames = <String>{};
  int moveCount = 0;

  ReferencedMoveEntry toEntry() {
    final List<String> sortedPlanNames = planNames.toList(growable: false)
      ..sort();
    return ReferencedMoveEntry(
      move: move,
      planNames: sortedPlanNames,
      moveCount: moveCount,
    );
  }
}

class _ScoredEntry<T> {
  const _ScoredEntry({
    required this.entry,
    required this.moveName,
    required this.score,
  });

  final T entry;
  final String moveName;
  final int score;
}
