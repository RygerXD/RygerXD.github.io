import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/history/domain/workout_streak.dart';

void main() {
  group('calculateCurrentWorkoutStreakDays', () {
    test('counts consecutive workout days ending today', () {
      expect(
        calculateCurrentWorkoutStreakDays(
          <DateTime>[
            DateTime(2026, 6, 12, 18),
            DateTime(2026, 6, 13, 7),
            DateTime(2026, 6, 14, 21),
          ],
          now: DateTime(2026, 6, 14, 22),
        ),
        3,
      );
    });

    test('keeps yesterday streak alive during today', () {
      expect(
        calculateCurrentWorkoutStreakDays(
          <DateTime>[
            DateTime(2026, 6, 11),
            DateTime(2026, 6, 12),
            DateTime(2026, 6, 13),
          ],
          now: DateTime(2026, 6, 14, 9),
        ),
        3,
      );
    });

    test('returns zero after a full missed day', () {
      expect(
        calculateCurrentWorkoutStreakDays(
          <DateTime>[
            DateTime(2026, 6, 10),
            DateTime(2026, 6, 11),
            DateTime(2026, 6, 12),
          ],
          now: DateTime(2026, 6, 14),
        ),
        0,
      );
    });

    test('counts multiple workouts on the same date once', () {
      expect(
        calculateCurrentWorkoutStreakDays(
          <DateTime>[
            DateTime(2026, 6, 13, 8),
            DateTime(2026, 6, 13, 18),
            DateTime(2026, 6, 14, 8),
          ],
          now: DateTime(2026, 6, 14, 12),
        ),
        2,
      );
    });
  });
}
