import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_app_rewrite/features/history/data/history_database_connection.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/history/domain/history_workout_snapshot.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

// Provides the singleton instance of the HistoryDatabase
final Provider<HistoryDatabase> historyDatabaseProvider =
    Provider<HistoryDatabase>((ref) {
  final HistoryDatabase database =
      HistoryDatabase(openHistoryDatabaseConnection());
  ref.onDispose(database.close);
  return database;
});

// A stream provider that reactively watches all sessions in the database.
// Drift's .watch() emits a new list whenever the table changes.
final StreamProvider<List<WorkoutSessionEntity>> allSessionsProvider =
    StreamProvider<List<WorkoutSessionEntity>>((ref) {
  final HistoryDatabase db = ref.watch(historyDatabaseProvider);
  return db.watchAllSessions();
});

final StreamProvider<List<WorkoutMovePerformanceEntity>>
    allMovePerformancesProvider =
    StreamProvider<List<WorkoutMovePerformanceEntity>>((ref) {
  final HistoryDatabase db = ref.watch(historyDatabaseProvider);
  return db.watchAllMovePerformances();
});

// A service provider to expose saving functionality
final Provider<HistoryService> historyServiceProvider =
    Provider<HistoryService>((ref) {
  return HistoryService(ref.watch(historyDatabaseProvider));
});

class HistoryService {
  HistoryService(this._db);

  final HistoryDatabase _db;

  Future<void> saveSession({
    required String sessionId,
    required String planId,
    required String workoutId,
    required String workoutName,
    WorkoutPlan? workoutPlanSnapshot,
    required DateTime startedAt,
    required DateTime endedAt,
    required String status,
  }) async {
    final int duration = endedAt.difference(startedAt).inSeconds;

    await _db.insertSession(
      WorkoutSessionEntity(
        sessionId: sessionId,
        planId: planId,
        workoutId: workoutId,
        planName: workoutPlanSnapshot?.name,
        workoutName: workoutName,
        workoutSnapshotJson:
            encodeHistoryWorkoutSnapshot(workoutPlanSnapshot, workoutId),
        startedAt: startedAt.millisecondsSinceEpoch,
        endedAt: endedAt.millisecondsSinceEpoch,
        durationSeconds: duration,
        status: status,
      ),
    );

    debugPrint('[HistoryService] Session saved: $sessionId ($status)');
  }

  Future<void> saveMovePerformance({
    required String sessionId,
    required String workoutId,
    required String setId,
    required int loopIndex,
    required String moveId,
    required String exerciseId,
    required int repCount,
    double? actualWeight,
    String? actualWeightUnit,
    required int elapsedSeconds,
    required DateTime completedAt,
  }) async {
    await _db.insertMovePerformance(
      WorkoutMovePerformanceEntity(
        performanceId: '$sessionId|$setId|$loopIndex|$moveId',
        sessionId: sessionId,
        workoutId: workoutId,
        setId: setId,
        loopIndex: loopIndex,
        moveId: moveId,
        exerciseId: exerciseId,
        repCount: repCount,
        actualWeight: actualWeight,
        actualWeightUnit: actualWeightUnit,
        elapsedSeconds: elapsedSeconds,
        completedAt: completedAt.millisecondsSinceEpoch,
      ),
    );
  }

  Future<void> deleteSession(String sessionId) async {
    await _db.deleteWorkoutSession(sessionId);
    debugPrint('[HistoryService] Session deleted: $sessionId');
  }
}
