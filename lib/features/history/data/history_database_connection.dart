import 'package:drift/drift.dart';
import 'package:workout_app_rewrite/features/history/data/history_database_connection_unsupported.dart'
    if (dart.library.io) 'package:workout_app_rewrite/features/history/data/history_database_connection_io.dart'
    if (dart.library.html) 'package:workout_app_rewrite/features/history/data/history_database_connection_web.dart';

QueryExecutor openHistoryDatabaseConnection() {
  return openPlatformHistoryDatabaseConnection();
}
