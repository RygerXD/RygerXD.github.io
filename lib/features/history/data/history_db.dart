import 'package:drift/drift.dart';

part 'history_db.g.dart';

@DataClassName('WorkoutSessionEntity')
class WorkoutSessions extends Table {
  TextColumn get sessionId => text()();
  TextColumn get planId => text()();
  TextColumn get workoutId => text()();
  TextColumn get planName => text().nullable()();
  TextColumn get workoutName => text().nullable()();
  TextColumn get workoutSnapshotJson => text().nullable()();
  IntColumn get startedAt => integer()();
  IntColumn get endedAt => integer().nullable()();
  IntColumn get durationSeconds => integer()();
  TextColumn get status =>
      text()(); // 'completed', 'completedEarly', or 'abandoned'

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{sessionId};
}

@DataClassName('WorkoutMovePerformanceEntity')
class WorkoutMovePerformances extends Table {
  TextColumn get performanceId => text()();
  TextColumn get sessionId => text()();
  TextColumn get workoutId => text()();
  TextColumn get setId => text()();
  IntColumn get lapIndex => integer()();
  TextColumn get workoutMoveId => text()();
  TextColumn get moveId => text()();
  IntColumn get repCount => integer()();
  RealColumn get actualWeight => real().nullable()();
  TextColumn get actualWeightUnit => text().nullable()();
  IntColumn get elapsedSeconds => integer()();
  IntColumn get completedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{performanceId};
}

@DriftDatabase(tables: <Type>[WorkoutSessions, WorkoutMovePerformances])
class HistoryDatabase extends _$HistoryDatabase {
  HistoryDatabase(super.e);

  @override
  int get schemaVersion => 8;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        final Set<String> sessionColumns = (await customSelect(
          'PRAGMA table_info(workout_sessions)',
        ).get())
            .map((QueryRow row) => row.read<String>('name'))
            .toSet();
        if (!sessionColumns.contains('plan_name')) {
          await m.addColumn(workoutSessions, workoutSessions.planName);
        }
        if (!sessionColumns.contains('workout_name')) {
          await m.addColumn(workoutSessions, workoutSessions.workoutName);
        }
        if (!sessionColumns.contains('workout_snapshot_json')) {
          await m.addColumn(
              workoutSessions, workoutSessions.workoutSnapshotJson);
        }

        final Set<String> performanceColumns = (await customSelect(
          'PRAGMA table_info(workout_move_performances)',
        ).get())
            .map((QueryRow row) => row.read<String>('name'))
            .toSet();
        const Set<String> currentPerformanceColumns = <String>{
          'performance_id',
          'session_id',
          'workout_id',
          'set_id',
          'lap_index',
          'workout_move_id',
          'move_id',
          'rep_count',
          'actual_weight',
          'actual_weight_unit',
          'elapsed_seconds',
          'completed_at',
        };
        if (!performanceColumns.containsAll(currentPerformanceColumns)) {
          await customStatement(
              'DROP TABLE IF EXISTS workout_move_performances');
          await m.createTable(workoutMovePerformances);
        }

        await customStatement('DROP TABLE IF EXISTS workout_plans_table');
      },
    );
  }

  Future<List<WorkoutSessionEntity>> getAllSessions() =>
      select(workoutSessions).get();

  Stream<List<WorkoutSessionEntity>> watchAllSessions() =>
      select(workoutSessions).watch();

  Future<void> insertSession(WorkoutSessionEntity session) =>
      into(workoutSessions).insert(session, mode: InsertMode.insertOrReplace);

  Future<void> clearHistory() async {
    await transaction(() async {
      await delete(workoutMovePerformances).go();
      await delete(workoutSessions).go();
    });
  }

  Future<void> deleteWorkoutSession(String sessionId) async {
    await transaction(() async {
      await (delete(workoutMovePerformances)
            ..where((t) => t.sessionId.equals(sessionId)))
          .go();
      await (delete(workoutSessions)
            ..where((t) => t.sessionId.equals(sessionId)))
          .go();
    });
  }

  Stream<List<WorkoutMovePerformanceEntity>> watchAllMovePerformances() =>
      select(workoutMovePerformances).watch();

  Future<List<WorkoutMovePerformanceEntity>> getAllMovePerformances() =>
      select(workoutMovePerformances).get();

  Future<void> insertMovePerformance(
          WorkoutMovePerformanceEntity performance) =>
      into(workoutMovePerformances)
          .insert(performance, mode: InsertMode.insertOrReplace);

  Future<void> replaceHistory({
    required List<WorkoutSessionEntity> sessions,
    required List<WorkoutMovePerformanceEntity> movePerformances,
  }) async {
    await transaction(() async {
      await delete(workoutMovePerformances).go();
      await delete(workoutSessions).go();
      for (final WorkoutSessionEntity session in sessions) {
        await insertSession(session);
      }
      for (final WorkoutMovePerformanceEntity performance in movePerformances) {
        await insertMovePerformance(performance);
      }
    });
  }
}
