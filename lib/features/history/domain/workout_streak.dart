int calculateCurrentWorkoutStreakDays(
  Iterable<DateTime> completedWorkoutDates, {
  DateTime? now,
}) {
  final Set<DateTime> completedDays = completedWorkoutDates
      .map((DateTime date) => DateTime(date.year, date.month, date.day))
      .toSet();

  if (completedDays.isEmpty) {
    return 0;
  }

  final DateTime reference = now ?? DateTime.now();
  final DateTime today =
      DateTime(reference.year, reference.month, reference.day);
  DateTime cursor = today;

  if (!completedDays.contains(cursor)) {
    final DateTime yesterday = today.subtract(const Duration(days: 1));
    if (!completedDays.contains(yesterday)) {
      return 0;
    }
    cursor = yesterday;
  }

  int streakDays = 0;
  while (completedDays.contains(cursor)) {
    streakDays += 1;
    cursor = cursor.subtract(const Duration(days: 1));
  }

  return streakDays;
}
