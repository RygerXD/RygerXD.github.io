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

@DriftDatabase(tables: <Type>[WorkoutSessions, WorkoutPlansTable])
class HistoryDatabase extends _$HistoryDatabase {
  HistoryDatabase(super.e);

  @override
  int get schemaVersion => 2;

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
      },
    );
  }

  Future<List<WorkoutSessionEntity>> getAllSessions() => select(workoutSessions).get();

  Future<void> insertSession(WorkoutSessionEntity session) => into(workoutSessions).insert(session, mode: InsertMode.insertOrReplace);

  Future<void> clearHistory() => delete(workoutSessions).go();

  Future<List<WorkoutPlanEntity>> getAllWorkoutPlans() => select(workoutPlansTable).get();

  Future<void> insertWorkoutPlan(WorkoutPlanEntity plan) => into(workoutPlansTable).insert(plan, mode: InsertMode.insertOrReplace);

  Future<void> deleteWorkoutPlan(String planId) => (delete(workoutPlansTable)..where((t) => t.planId.equals(planId))).go();
}
