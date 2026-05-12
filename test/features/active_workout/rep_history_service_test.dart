import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/active_workout/application/rep_history_service.dart';

void main() {
  group('RepHistoryService', () {
    test('saves and retrieves reps by workout/set/loop/exercise key', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final RepHistoryService service = RepHistoryService(prefs);

      await service.saveReps(
        workoutId: 'w1',
        setId: 's1',
        loopIndex: 0,
        exerciseId: 'e1',
        reps: 12,
      );

      final int? stored = await service.getLastReps(
        workoutId: 'w1',
        setId: 's1',
        loopIndex: 0,
        exerciseId: 'e1',
      );

      expect(stored, 12);
    });

    test('stores separate values per loop', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final RepHistoryService service = RepHistoryService(prefs);

      await service.saveReps(
        workoutId: 'w1',
        setId: 's1',
        loopIndex: 0,
        exerciseId: 'e1',
        reps: 10,
      );
      await service.saveReps(
        workoutId: 'w1',
        setId: 's1',
        loopIndex: 1,
        exerciseId: 'e1',
        reps: 8,
      );

      final int? loop0 = await service.getLastReps(
        workoutId: 'w1',
        setId: 's1',
        loopIndex: 0,
        exerciseId: 'e1',
      );
      final int? loop1 = await service.getLastReps(
        workoutId: 'w1',
        setId: 's1',
        loopIndex: 1,
        exerciseId: 'e1',
      );

      expect(loop0, 10);
      expect(loop1, 8);
    });

    test('falls back to empty data on malformed storage', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{
        'rep_history_v1': '{invalid-json',
      });
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final RepHistoryService service = RepHistoryService(prefs);

      final int? stored = await service.getLastReps(
        workoutId: 'w1',
        setId: 's1',
        loopIndex: 0,
        exerciseId: 'e1',
      );

      expect(stored, isNull);
    });

    test('saves and retrieves weight by workout/set/loop/exercise/unit key',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final RepHistoryService service = RepHistoryService(prefs);

      await service.saveWeight(
        workoutId: 'w1',
        setId: 's1',
        loopIndex: 0,
        exerciseId: 'e1',
        weightUnit: 'lb',
        weight: 45.5,
      );

      final double? stored = await service.getLastWeight(
        workoutId: 'w1',
        setId: 's1',
        loopIndex: 0,
        exerciseId: 'e1',
        weightUnit: 'lb',
      );

      expect(stored, 45.5);
    });

    test('stores separate weight values per unit', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final RepHistoryService service = RepHistoryService(prefs);

      await service.saveWeight(
        workoutId: 'w1',
        setId: 's1',
        loopIndex: 0,
        exerciseId: 'e1',
        weightUnit: 'lb',
        weight: 100,
      );
      await service.saveWeight(
        workoutId: 'w1',
        setId: 's1',
        loopIndex: 0,
        exerciseId: 'e1',
        weightUnit: 'kg',
        weight: 45,
      );

      final double? pounds = await service.getLastWeight(
        workoutId: 'w1',
        setId: 's1',
        loopIndex: 0,
        exerciseId: 'e1',
        weightUnit: 'lb',
      );
      final double? kilos = await service.getLastWeight(
        workoutId: 'w1',
        setId: 's1',
        loopIndex: 0,
        exerciseId: 'e1',
        weightUnit: 'kg',
      );

      expect(pounds, 100);
      expect(kilos, 45);
    });

    test('saves and retrieves duration by workout/set/loop/exercise key',
        () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final RepHistoryService service = RepHistoryService(prefs);

      await service.saveDuration(
        workoutId: 'w1',
        setId: 's1',
        loopIndex: 0,
        exerciseId: 'e1',
        seconds: 75,
      );

      final int? stored = await service.getLastDuration(
        workoutId: 'w1',
        setId: 's1',
        loopIndex: 0,
        exerciseId: 'e1',
      );

      expect(stored, 75);
    });
  });
}
