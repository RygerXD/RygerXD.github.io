import 'package:drift/drift.dart';
// ignore: deprecated_member_use
import 'package:drift/web.dart';

QueryExecutor openPlatformHistoryDatabaseConnection() {
  return WebDatabase('history_db');
}
