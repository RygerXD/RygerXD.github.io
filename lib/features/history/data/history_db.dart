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
  TextColumn get status => text()(); // 'completed' or 'abandoned'

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
        if (from < 3) {
          await m.createTable(workoutMovePerformances);
        }
        if (from == 3) {
          await m.addColumn(
              workoutMovePerformances, workoutMovePerformances.actualWeight);
          await m.addColumn(workoutMovePerformances,
              workoutMovePerformances.actualWeightUnit);
        }
        if (from < 5) {
          await m.addColumn(workoutSessions, workoutSessions.planName);
          await m.addColumn(workoutSessions, workoutSessions.workoutName);
          await m.addColumn(
              workoutSessions, workoutSessions.workoutSnapshotJson);
        }
        if (from < 6) {
          await m.deleteTable('workout_move_performances');
          await m.createTable(workoutMovePerformances);
        }
        if (from < 7) {
          await m.deleteTable('workout_move_performances');
          await m.createTable(workoutMovePerformances);
        }
        if (from >= 2 && from < 8) {
          await m.deleteTable('workout_plans_table');
        }
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
