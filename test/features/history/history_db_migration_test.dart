import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';

void main() {
  test('migrates schema 2 database without duplicate move performance columns',
      () async {
    final HistoryDatabase db = HistoryDatabase(
      NativeDatabase.memory(
        setup: (database) {
          database
            ..execute('''
              CREATE TABLE workout_sessions (
                session_id TEXT NOT NULL PRIMARY KEY,
                plan_id TEXT NOT NULL,
                workout_id TEXT NOT NULL,
                started_at INTEGER NOT NULL,
                ended_at INTEGER,
                duration_seconds INTEGER NOT NULL,
                status TEXT NOT NULL
              )
            ''')
            ..execute('''
              CREATE TABLE workout_plans_table (
                plan_id TEXT NOT NULL PRIMARY KEY,
                json_payload TEXT NOT NULL
              )
            ''')
            ..execute('PRAGMA user_version = 2');
        },
      ),
    );
    addTearDown(db.close);

    await db.getAllSessions();

    final List<QueryRow> columns = await db
        .customSelect('PRAGMA table_info(workout_move_performances)')
        .get();
    final List<String> columnNames = columns
        .map((QueryRow row) => row.data['name']! as String)
        .toList(growable: false);

    expect(columnNames, contains('actual_weight'));
    expect(columnNames, contains('actual_weight_unit'));
  });

  test('schema 7 migration preserves history and drops obsolete plan table',
      () async {
    final HistoryDatabase db = HistoryDatabase(
      NativeDatabase.memory(
        setup: (database) {
          database
            ..execute('''
              CREATE TABLE workout_sessions (
                session_id TEXT NOT NULL PRIMARY KEY,
                plan_id TEXT NOT NULL,
                workout_id TEXT NOT NULL,
                plan_name TEXT,
                workout_name TEXT,
                workout_snapshot_json TEXT,
                started_at INTEGER NOT NULL,
                ended_at INTEGER,
                duration_seconds INTEGER NOT NULL,
                status TEXT NOT NULL
              )
            ''')
            ..execute('''
              CREATE TABLE workout_move_performances (
                performance_id TEXT NOT NULL PRIMARY KEY,
                session_id TEXT NOT NULL,
                workout_id TEXT NOT NULL,
                set_id TEXT NOT NULL,
                lap_index INTEGER NOT NULL,
                workout_move_id TEXT NOT NULL,
                move_id TEXT NOT NULL,
                rep_count INTEGER NOT NULL,
                actual_weight REAL,
                actual_weight_unit TEXT,
                elapsed_seconds INTEGER NOT NULL,
                completed_at INTEGER NOT NULL
              )
            ''')
            ..execute('''
              CREATE TABLE workout_plans_table (
                plan_id TEXT NOT NULL PRIMARY KEY,
                json_payload TEXT NOT NULL
              )
            ''')
            ..execute('''
              INSERT INTO workout_sessions (
                session_id, plan_id, workout_id, plan_name, workout_name,
                workout_snapshot_json, started_at, ended_at, duration_seconds,
                status
              ) VALUES (
                'session-1', 'plan-1', 'workout-1', 'Plan', 'Workout', NULL,
                1000, 1060, 60, 'completed'
              )
            ''')
            ..execute('PRAGMA user_version = 7');
        },
      ),
    );
    addTearDown(db.close);

    final List<WorkoutSessionEntity> sessions = await db.getAllSessions();
    final QueryRow obsoleteTable = await db.customSelect('''
      SELECT COUNT(*) AS table_count
      FROM sqlite_master
      WHERE type = 'table' AND name = 'workout_plans_table'
    ''').getSingle();

    expect(sessions, hasLength(1));
    expect(sessions.single.sessionId, 'session-1');
    expect(obsoleteTable.data['table_count'], 0);
  });
}
