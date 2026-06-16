import 'dart:developer';

enum LogLevel {
  debug,
  info,
  warning,
  error,
}

class AppLogger {
  const AppLogger();

  void logMessage(
    String message, {
    LogLevel level = LogLevel.info,
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?> context = const <String, Object?>{},
  }) {
    final String enriched =
        '[${level.name.toUpperCase()}] $message | context=$context';
    log(
      enriched,
      error: error,
      stackTrace: stackTrace,
      name: 'WorkoutApp',
    );
  }
}
