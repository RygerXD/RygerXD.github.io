import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';
import 'package:workout_app_rewrite/features/settings/application/sound_settings_transfer.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_parser.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

final Provider<DataBackupService> dataBackupServiceProvider =
    Provider<DataBackupService>((Ref<DataBackupService> ref) {
  return DataBackupService(ref);
});

class BackupExportResult {
  const BackupExportResult({
    required this.planCount,
    required this.sessionCount,
    required this.movePerformanceCount,
    required this.path,
  });

  final int planCount;
  final int sessionCount;
  final int movePerformanceCount;
  final String? path;
}

class BackupRestoreResult {
  const BackupRestoreResult({
    required this.planCount,
    required this.sessionCount,
    required this.movePerformanceCount,
  });

  final int planCount;
  final int sessionCount;
  final int movePerformanceCount;
}

class DataBackupException implements Exception {
  const DataBackupException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DataBackupService {
  DataBackupService(this._ref);

  static const String _format = 'workout_app_rewrite.backup';
  static const int _formatVersion = 1;

  final Ref _ref;

  Future<BackupExportResult?> exportBackup() async {
    final WorkoutRepository repository = _ref.read(workoutRepositoryProvider);
    final HistoryDatabase database = _ref.read(historyDatabaseProvider);
    final AppSettings settings = _ref.read(appSettingsProvider);

    final List<WorkoutPlan> plans = await repository.getAllPlans();
    final List<WorkoutSessionEntity> sessions = await database.getAllSessions();
    final List<WorkoutMovePerformanceEntity> movePerformances =
        await database.getAllMovePerformances();

    final Map<String, dynamic> backup = <String, dynamic>{
      'format': _format,
      'formatVersion': _formatVersion,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
      'settings': _settingsWithoutSoundData(settings),
      'soundSettings': encodeSoundSettings(settings),
      'workoutPlans': plans
          .map((WorkoutPlan plan) => plan.toJson())
          .toList(growable: false),
      'history': <String, dynamic>{
        'sessions': sessions.map(_workoutSessionToJson).toList(growable: false),
        'movePerformances': movePerformances
            .map(_movePerformanceToJson)
            .toList(growable: false),
      },
    };

    final Uint8List bytes = Uint8List.fromList(
      utf8.encode(const JsonEncoder.withIndent('  ').convert(backup)),
    );
    final String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'Back up workout data',
      fileName: _backupFileName(DateTime.now()),
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
      bytes: bytes,
    );

    if (!kIsWeb && path == null) {
      return null;
    }

    return BackupExportResult(
      planCount: plans.length,
      sessionCount: sessions.length,
      movePerformanceCount: movePerformances.length,
      path: path,
    );
  }

  Future<BackupRestoreResult?> restoreBackup() async {
    final FilePickerResult? result = await FilePicker.platform.pickFiles(
      dialogTitle: 'Restore workout backup',
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
      withData: true,
    );
    if (result == null || result.files.isEmpty) {
      return null;
    }

    final Uint8List? bytes = result.files.single.bytes;
    if (bytes == null) {
      throw const DataBackupException('Could not read the selected backup.');
    }

    final _BackupData backup = _parseBackup(bytes);
    await _replacePlans(backup.plans);
    await _ref
        .read(appSettingsProvider.notifier)
        .applySettings(backup.settings);
    await _ref
        .read(appSettingsProvider.notifier)
        .applyAudioSettings(backup.soundSettings);
    await _ref.read(historyDatabaseProvider).replaceHistory(
          sessions: backup.sessions,
          movePerformances: backup.movePerformances,
        );

    _ref.invalidate(loadedWorkoutPlansNotifierProvider);
    _ref.invalidate(allSessionsProvider);
    _ref.invalidate(allMovePerformancesProvider);

    return BackupRestoreResult(
      planCount: backup.plans.length,
      sessionCount: backup.sessions.length,
      movePerformanceCount: backup.movePerformances.length,
    );
  }

  Future<void> _replacePlans(List<WorkoutPlan> plans) async {
    final WorkoutRepository repository = _ref.read(workoutRepositoryProvider);
    final List<WorkoutPlan> existingPlans = await repository.getAllPlans();
    for (final WorkoutPlan plan in existingPlans) {
      await repository.deletePlan(plan.planId);
    }
    for (final WorkoutPlan plan in plans) {
      await repository.savePlan(plan);
    }
  }

  _BackupData _parseBackup(Uint8List bytes) {
    try {
      final Object? decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is! Map<String, dynamic>) {
        throw const DataBackupException('Backup file is not valid JSON.');
      }
      if (decoded['format'] != _format ||
          decoded['formatVersion'] != _formatVersion) {
        throw const DataBackupException('Backup file is not supported.');
      }

      final Object? settingsJson = decoded['settings'];
      final Object? plansJson = decoded['workoutPlans'];
      final Object? historyJson = decoded['history'];
      if (settingsJson is! Map<String, dynamic> ||
          plansJson is! List<dynamic> ||
          historyJson is! Map<String, dynamic>) {
        throw const DataBackupException('Backup file is missing data.');
      }

      final WorkoutPlanParser parser = _ref.read(workoutPlanParserProvider);
      final List<WorkoutPlan> plans = plansJson
          .cast<Map<String, dynamic>>()
          .map(parser.parseFromJson)
          .toList(growable: false);

      final Object? sessionsJson = historyJson['sessions'];
      final Object? movePerformancesJson = historyJson['movePerformances'];
      if (sessionsJson is! List<dynamic> ||
          movePerformancesJson is! List<dynamic>) {
        throw const DataBackupException('Backup file is missing history data.');
      }

      return _BackupData(
        settings: AppSettings.fromJson(settingsJson),
        soundSettings: decodeSoundSettings(decoded['soundSettings']),
        plans: plans,
        sessions: sessionsJson
            .cast<Map<String, dynamic>>()
            .map(_workoutSessionFromJson)
            .toList(growable: false),
        movePerformances: movePerformancesJson
            .cast<Map<String, dynamic>>()
            .map(_movePerformanceFromJson)
            .toList(growable: false),
      );
    } on DataBackupException {
      rethrow;
    } catch (_) {
      throw const DataBackupException('Backup file could not be restored.');
    }
  }

  static Map<String, dynamic> _workoutSessionToJson(
    WorkoutSessionEntity session,
  ) {
    return <String, dynamic>{
      'sessionId': session.sessionId,
      'planId': session.planId,
      'workoutId': session.workoutId,
      'planName': session.planName,
      'workoutName': session.workoutName,
      'workoutSnapshotJson': session.workoutSnapshotJson,
      'startedAt': session.startedAt,
      'endedAt': session.endedAt,
      'durationSeconds': session.durationSeconds,
      'status': session.status,
    };
  }

  static WorkoutSessionEntity _workoutSessionFromJson(
    Map<String, dynamic> json,
  ) {
    return WorkoutSessionEntity(
      sessionId: _string(json, 'sessionId'),
      planId: _string(json, 'planId'),
      workoutId: _string(json, 'workoutId'),
      planName: _nullableString(json, 'planName'),
      workoutName: _nullableString(json, 'workoutName'),
      workoutSnapshotJson: _nullableString(json, 'workoutSnapshotJson'),
      startedAt: _int(json, 'startedAt'),
      endedAt: _nullableInt(json, 'endedAt'),
      durationSeconds: _int(json, 'durationSeconds'),
      status: _string(json, 'status'),
    );
  }

  static Map<String, dynamic> _movePerformanceToJson(
    WorkoutMovePerformanceEntity performance,
  ) {
    return <String, dynamic>{
      'performanceId': performance.performanceId,
      'sessionId': performance.sessionId,
      'workoutId': performance.workoutId,
      'setId': performance.setId,
      'lapIndex': performance.lapIndex,
      'workoutMoveId': performance.workoutMoveId,
      'moveId': performance.moveId,
      'repCount': performance.repCount,
      'actualWeight': performance.actualWeight,
      'actualWeightUnit': performance.actualWeightUnit,
      'elapsedSeconds': performance.elapsedSeconds,
      'completedAt': performance.completedAt,
    };
  }

  static WorkoutMovePerformanceEntity _movePerformanceFromJson(
    Map<String, dynamic> json,
  ) {
    return WorkoutMovePerformanceEntity(
      performanceId: _string(json, 'performanceId'),
      sessionId: _string(json, 'sessionId'),
      workoutId: _string(json, 'workoutId'),
      setId: _string(json, 'setId'),
      lapIndex: _int(json, 'lapIndex'),
      workoutMoveId: _string(json, 'workoutMoveId'),
      moveId: _string(json, 'moveId'),
      repCount: _int(json, 'repCount'),
      actualWeight: _nullableDouble(json, 'actualWeight'),
      actualWeightUnit: _nullableString(json, 'actualWeightUnit'),
      elapsedSeconds: _int(json, 'elapsedSeconds'),
      completedAt: _int(json, 'completedAt'),
    );
  }

  static String _backupFileName(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    final String date = '${local.year}${_two(local.month)}${_two(local.day)}';
    final String time =
        '${_two(local.hour)}${_two(local.minute)}${_two(local.second)}';
    return 'workout-app-backup-$date-$time.json';
  }

  static Map<String, dynamic> _settingsWithoutSoundData(AppSettings settings) {
    final Map<String, dynamic> json = settings.toJson();
    for (final String key in <String>[
      'customSoundLibrary',
      'metronomeClickCustomSound',
      'getReadyCountdownCustomSound',
      'getReadyDingCustomSound',
      'moveCountdownCustomSound',
      'moveFinishedDingCustomSound',
      'moveHalfwayCustomSound',
      'restFinishedCustomSound',
      'workoutCompleteCustomSound',
      'workoutEndedEarlyCustomSound',
    ]) {
      json.remove(key);
    }
    return json;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  static String _string(Map<String, dynamic> json, String key) {
    final Object? value = json[key];
    if (value is String) {
      return value;
    }
    throw DataBackupException('Backup field $key is invalid.');
  }

  static String? _nullableString(Map<String, dynamic> json, String key) {
    final Object? value = json[key];
    if (value == null || value is String) {
      return value as String?;
    }
    throw DataBackupException('Backup field $key is invalid.');
  }

  static int _int(Map<String, dynamic> json, String key) {
    final Object? value = json[key];
    if (value is num) {
      return value.toInt();
    }
    throw DataBackupException('Backup field $key is invalid.');
  }

  static int? _nullableInt(Map<String, dynamic> json, String key) {
    final Object? value = json[key];
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toInt();
    }
    throw DataBackupException('Backup field $key is invalid.');
  }

  static double? _nullableDouble(Map<String, dynamic> json, String key) {
    final Object? value = json[key];
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    throw DataBackupException('Backup field $key is invalid.');
  }
}

class _BackupData {
  const _BackupData({
    required this.settings,
    required this.soundSettings,
    required this.plans,
    required this.sessions,
    required this.movePerformances,
  });

  final AppSettings settings;
  final AppSettings soundSettings;
  final List<WorkoutPlan> plans;
  final List<WorkoutSessionEntity> sessions;
  final List<WorkoutMovePerformanceEntity> movePerformances;
}
