import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/native.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/history/application/history_providers.dart';
import 'package:workout_app_rewrite/features/history/data/history_db.dart';
import 'package:workout_app_rewrite/features/settings/application/app_settings_controller.dart';
import 'package:workout_app_rewrite/features/settings/application/data_backup_service.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeFilePicker fakeFilePicker;

  setUp(() {
    fakeFilePicker = _FakeFilePicker();
    FilePicker.platform = fakeFilePicker;
  });

  group('DataBackupService', () {
    test('exports settings, plans, sessions, and move performances', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final HistoryDatabase database = HistoryDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          historyDatabaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(appSettingsProvider.notifier)
          .setThemePreference(AppThemePreference.dark);
      await container.read(workoutRepositoryProvider).savePlan(_samplePlan);
      await _seedHistory(database);

      final BackupExportResult? result =
          await container.read(dataBackupServiceProvider).exportBackup();

      expect(result, isNotNull);
      expect(result!.planCount, 1);
      expect(result.sessionCount, 1);
      expect(result.movePerformanceCount, 1);
      expect(fakeFilePicker.savedFileName, startsWith('workout-app-backup-'));
      expect(fakeFilePicker.savedBytes, isNotNull);

      final Map<String, dynamic> json = jsonDecode(
        utf8.decode(fakeFilePicker.savedBytes!),
      ) as Map<String, dynamic>;
      expect(json['format'], 'workout_app_rewrite.backup');
      expect(json['formatVersion'], 1);
      expect((json['settings'] as Map<String, dynamic>)['themePreference'],
          'dark');
      expect(json['workoutPlans'], hasLength(1));
      expect(
          (json['history'] as Map<String, dynamic>)['sessions'], hasLength(1));
      expect((json['history'] as Map<String, dynamic>)['movePerformances'],
          hasLength(1));
    });

    test('restores backup data and replaces existing local data', () async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final HistoryDatabase database = HistoryDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final ProviderContainer container = ProviderContainer(
        overrides: <Override>[
          sharedPreferencesProvider.overrideWithValue(prefs),
          historyDatabaseProvider.overrideWithValue(database),
        ],
      );
      addTearDown(container.dispose);

      final WorkoutRepository repository =
          container.read(workoutRepositoryProvider);
      await repository.savePlan(_stalePlan);
      await database.insertSession(
        const WorkoutSessionEntity(
          sessionId: 'stale-session',
          planId: 'stale-plan',
          workoutId: 'stale-workout',
          startedAt: 1,
          endedAt: 2,
          durationSeconds: 1,
          status: 'completed',
        ),
      );

      final Uint8List backupBytes = Uint8List.fromList(
        utf8.encode(jsonEncode(_backupJson())),
      );
      fakeFilePicker.pickResult = FilePickerResult(
        <PlatformFile>[
          PlatformFile(
            name: 'backup.json',
            size: backupBytes.length,
            bytes: backupBytes,
          ),
        ],
      );

      final BackupRestoreResult? result =
          await container.read(dataBackupServiceProvider).restoreBackup();

      expect(result, isNotNull);
      expect(result!.planCount, 1);
      expect(result.sessionCount, 1);
      expect(result.movePerformanceCount, 1);

      final List<WorkoutPlan> plans = await repository.getAllPlans();
      expect(plans, hasLength(1));
      expect(plans.single.planId, _samplePlan.planId);
      expect(container.read(appSettingsProvider).themePreference,
          AppThemePreference.dark);
      expect(container.read(appSettingsProvider).unitSystem,
          AppUnitSystem.imperial);

      final List<WorkoutSessionEntity> sessions =
          await database.getAllSessions();
      final List<WorkoutMovePerformanceEntity> performances =
          await database.getAllMovePerformances();
      expect(sessions.map((WorkoutSessionEntity session) => session.sessionId),
          <String>['session-1']);
      expect(
        performances.map(
          (WorkoutMovePerformanceEntity performance) =>
              performance.performanceId,
        ),
        <String>['performance-1'],
      );
    });
  });
}

const WorkoutPlan _samplePlan = WorkoutPlan(
  schemaVersion: 1,
  planId: 'plan-1',
  name: 'Plan 1',
  workouts: <Workout>[
    Workout(
      workoutId: 'workout-1',
      title: 'Workout A',
      sets: <WorkoutSet>[
        WorkoutSet(
          setId: 'set-1',
          loopCount: 1,
          restBetweenLoopsSeconds: 30,
          moves: <Move>[
            Move(
              moveId: 'move-1',
              exerciseId: 'exercise-1',
              type: MoveType.reps,
              repCount: 10,
            ),
          ],
        ),
      ],
    ),
  ],
  exercises: <Exercise>[
    Exercise(
      exerciseId: 'exercise-1',
      name: 'Squat',
    ),
  ],
);

const WorkoutPlan _stalePlan = WorkoutPlan(
  schemaVersion: 1,
  planId: 'stale-plan',
  name: 'Stale Plan',
  workouts: <Workout>[
    Workout(
      workoutId: 'stale-workout',
      title: 'Stale Workout',
      sets: <WorkoutSet>[],
    ),
  ],
  exercises: <Exercise>[],
);

Future<void> _seedHistory(HistoryDatabase database) async {
  await database.insertSession(
    const WorkoutSessionEntity(
      sessionId: 'session-1',
      planId: 'plan-1',
      workoutId: 'workout-1',
      startedAt: 1000,
      endedAt: 2000,
      durationSeconds: 1,
      status: 'completed',
    ),
  );
  await database.insertMovePerformance(
    const WorkoutMovePerformanceEntity(
      performanceId: 'performance-1',
      sessionId: 'session-1',
      workoutId: 'workout-1',
      setId: 'set-1',
      loopIndex: 0,
      moveId: 'move-1',
      exerciseId: 'exercise-1',
      repCount: 10,
      actualWeight: 35,
      actualWeightUnit: 'kg',
      elapsedSeconds: 45,
      completedAt: 2000,
    ),
  );
}

Map<String, dynamic> _backupJson() {
  return <String, dynamic>{
    'format': 'workout_app_rewrite.backup',
    'formatVersion': 1,
    'createdAt': '2026-06-10T12:00:00.000Z',
    'settings': const AppSettings(
      themePreference: AppThemePreference.dark,
      unitSystem: AppUnitSystem.imperial,
      streakWorkoutsPerWeek: 4,
      audioCuesEnabled: false,
      metronomeClickSound: MetronomeClickSound.bell,
      metronomeVolume: 0.35,
      getReadyCountdownSound: CountdownSound.wood,
      getReadyCountdownVolume: 0.25,
      getReadyDingSound: GetReadyDingSound.bright,
      getReadyDingVolume: 0.45,
      exerciseCountdownSound: CountdownSound.low,
      exerciseCountdownVolume: 0.55,
      exerciseFinishedDingSound: ExerciseFinishedDingSound.bell,
      exerciseFinishedDingVolume: 0.65,
    ).toJson(),
    'workoutPlans': <Map<String, dynamic>>[_samplePlan.toJson()],
    'history': <String, dynamic>{
      'sessions': <Map<String, dynamic>>[
        <String, dynamic>{
          'sessionId': 'session-1',
          'planId': 'plan-1',
          'workoutId': 'workout-1',
          'startedAt': 1000,
          'endedAt': 2000,
          'durationSeconds': 1,
          'status': 'completed',
        },
      ],
      'movePerformances': <Map<String, dynamic>>[
        <String, dynamic>{
          'performanceId': 'performance-1',
          'sessionId': 'session-1',
          'workoutId': 'workout-1',
          'setId': 'set-1',
          'loopIndex': 0,
          'moveId': 'move-1',
          'exerciseId': 'exercise-1',
          'repCount': 10,
          'actualWeight': 35,
          'actualWeightUnit': 'kg',
          'elapsedSeconds': 45,
          'completedAt': 2000,
        },
      ],
    },
  };
}

class _FakeFilePicker extends FilePicker {
  Uint8List? savedBytes;
  String? savedFileName;
  FilePickerResult? pickResult;

  @override
  Future<FilePickerResult?> pickFiles({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    void Function(FilePickerStatus)? onFileLoading,
    bool allowCompression = true,
    int compressionQuality = 30,
    bool allowMultiple = false,
    bool withData = false,
    bool withReadStream = false,
    bool lockParentWindow = false,
    bool readSequential = false,
  }) async {
    return pickResult;
  }

  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    savedBytes = bytes;
    savedFileName = fileName;
    return 'C:\\backup.json';
  }
}
