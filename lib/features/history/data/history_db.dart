import 'package:drift/drift.dart';

part 'history_db.g.dart';

@DataClassName('WorkoutSessionEntity')
class WorkoutSessions extends Table {
  TextColumn get sessionId => text()();
  TextColumn get planId => text()();
  TextColumn get workoutId => text()();
  IntColumn get startedAt => integer()();
  IntColumn get endedAt => integer().nullable()();
  IntColumn get durationSeconds => integer()();
  TextColumn get status => text()(); // 'completed' or 'abandoned'

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{sessionId};
}

@DataClassName('WorkoutPlanEntity')
class WorkoutPlansTable extends Table {
  TextColumn get planId => text()();
  TextColumn get jsonPayload => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{planId};
}

@DataClassName('WorkoutMovePerformanceEntity')
class WorkoutMovePerformances extends Table {
  TextColumn get performanceId => text()();
  TextColumn get sessionId => text()();
  TextColumn get workoutId => text()();
  TextColumn get setId => text()();
  IntColumn get loopIndex => integer()();
  TextColumn get moveId => text()();
  TextColumn get exerciseId => text()();
  IntColumn get repCount => integer()();
  RealColumn get actualWeight => real().nullable()();
  TextColumn get actualWeightUnit => text().nullable()();
  IntColumn get elapsedSeconds => integer()();
  IntColumn get completedAt => integer()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{performanceId};
}

@DriftDatabase(
    tables: <Type>[WorkoutSessions, WorkoutPlansTable, WorkoutMovePerformances])
class HistoryDatabase extends _$HistoryDatabase {
  HistoryDatabase(super.e);

  @override
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from == 1) {
          await m.createTable(workoutPlansTable);
        }
        if (from < 3) {
          await m.createTable(workoutMovePerformances);
        }
        if (from == 3) {
          await m.addColumn(
              workoutMovePerformances, workoutMovePerformances.actualWeight);
          await m.addColumn(workoutMovePerformances,
              workoutMovePerformances.actualWeightUnit);
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

  Stream<List<WorkoutMovePerformanceEntity>> watchAllMovePerformances() =>
      select(workoutMovePerformances).watch();

  Future<void> insertMovePerformance(
          WorkoutMovePerformanceEntity performance) =>
      into(workoutMovePerformances)
          .insert(performance, mode: InsertMode.insertOrReplace);

  Future<List<WorkoutPlanEntity>> getAllWorkoutPlans() =>
      select(workoutPlansTable).get();

  Future<void> insertWorkoutPlan(WorkoutPlanEntity plan) =>
      into(workoutPlansTable).insert(plan, mode: InsertMode.insertOrReplace);

  Future<void> deleteWorkoutPlan(String planId) =>
      (delete(workoutPlansTable)..where((t) => t.planId.equals(planId))).go();
}
