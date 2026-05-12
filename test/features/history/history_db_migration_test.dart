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
}
