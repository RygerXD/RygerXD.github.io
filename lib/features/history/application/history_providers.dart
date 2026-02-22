import 'package:drift/web.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';

// Provides the singleton instance of the HistoryDatabase
final Provider<HistoryDatabase> historyDatabaseProvider = Provider<HistoryDatabase>((ref) {
  // We use WebDatabase to ensure it compiles successfully for flutter build web.
  // In a full production app, we would use conditional imports or WasmDatabase.
  return HistoryDatabase(WebDatabase('history_db'));
});

// A future provider to fetch all sessions
final FutureProvider<List<WorkoutSessionEntity>> allSessionsProvider = FutureProvider<List<WorkoutSessionEntity>>((ref) {
  final HistoryDatabase db = ref.watch(historyDatabaseProvider);
  return db.getAllSessions();
});

// A service provider to expose saving functionality
final Provider<HistoryService> historyServiceProvider = Provider<HistoryService>((ref) {
  return HistoryService(ref.watch(historyDatabaseProvider), ref);
});

class HistoryService {
  HistoryService(this._db, this._ref);

  final HistoryDatabase _db;
  final Ref _ref;

  Future<void> saveSession({
    required String sessionId,
    required String planId,
    required String workoutId,
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
        startedAt: startedAt.millisecondsSinceEpoch,
        endedAt: endedAt.millisecondsSinceEpoch,
        durationSeconds: duration,
        status: status,
      ),
    );

    // Refresh the sessions list so UI updates automatically
    _ref.invalidate(allSessionsProvider);
  }
}
