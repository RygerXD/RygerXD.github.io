// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_db.dart';

// ignore_for_file: type=lint
class $WorkoutSessionsTable extends WorkoutSessions
    with TableInfo<$WorkoutSessionsTable, WorkoutSessionEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutSessionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
      'plan_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workoutIdMeta =
      const VerificationMeta('workoutId');
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
      'workout_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _planNameMeta =
      const VerificationMeta('planName');
  @override
  late final GeneratedColumn<String> planName = GeneratedColumn<String>(
      'plan_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _workoutNameMeta =
      const VerificationMeta('workoutName');
  @override
  late final GeneratedColumn<String> workoutName = GeneratedColumn<String>(
      'workout_name', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _workoutSnapshotJsonMeta =
      const VerificationMeta('workoutSnapshotJson');
  @override
  late final GeneratedColumn<String> workoutSnapshotJson =
      GeneratedColumn<String>('workout_snapshot_json', aliasedName, true,
          type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _startedAtMeta =
      const VerificationMeta('startedAt');
  @override
  late final GeneratedColumn<int> startedAt = GeneratedColumn<int>(
      'started_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _endedAtMeta =
      const VerificationMeta('endedAt');
  @override
  late final GeneratedColumn<int> endedAt = GeneratedColumn<int>(
      'ended_at', aliasedName, true,
      type: DriftSqlType.int, requiredDuringInsert: false);
  static const VerificationMeta _durationSecondsMeta =
      const VerificationMeta('durationSeconds');
  @override
  late final GeneratedColumn<int> durationSeconds = GeneratedColumn<int>(
      'duration_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
      'status', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        sessionId,
        planId,
        workoutId,
        planName,
        workoutName,
        workoutSnapshotJson,
        startedAt,
        endedAt,
        durationSeconds,
        status
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_sessions';
  @override
  VerificationContext validateIntegrity(
      Insertable<WorkoutSessionEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('plan_id')) {
      context.handle(_planIdMeta,
          planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta));
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(_workoutIdMeta,
          workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta));
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('plan_name')) {
      context.handle(_planNameMeta,
          planName.isAcceptableOrUnknown(data['plan_name']!, _planNameMeta));
    }
    if (data.containsKey('workout_name')) {
      context.handle(
          _workoutNameMeta,
          workoutName.isAcceptableOrUnknown(
              data['workout_name']!, _workoutNameMeta));
    }
    if (data.containsKey('workout_snapshot_json')) {
      context.handle(
          _workoutSnapshotJsonMeta,
          workoutSnapshotJson.isAcceptableOrUnknown(
              data['workout_snapshot_json']!, _workoutSnapshotJsonMeta));
    }
    if (data.containsKey('started_at')) {
      context.handle(_startedAtMeta,
          startedAt.isAcceptableOrUnknown(data['started_at']!, _startedAtMeta));
    } else if (isInserting) {
      context.missing(_startedAtMeta);
    }
    if (data.containsKey('ended_at')) {
      context.handle(_endedAtMeta,
          endedAt.isAcceptableOrUnknown(data['ended_at']!, _endedAtMeta));
    }
    if (data.containsKey('duration_seconds')) {
      context.handle(
          _durationSecondsMeta,
          durationSeconds.isAcceptableOrUnknown(
              data['duration_seconds']!, _durationSecondsMeta));
    } else if (isInserting) {
      context.missing(_durationSecondsMeta);
    }
    if (data.containsKey('status')) {
      context.handle(_statusMeta,
          status.isAcceptableOrUnknown(data['status']!, _statusMeta));
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {sessionId};
  @override
  WorkoutSessionEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutSessionEntity(
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      planId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_id'])!,
      workoutId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_id'])!,
      planName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_name']),
      workoutName: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_name']),
      workoutSnapshotJson: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}workout_snapshot_json']),
      startedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}started_at'])!,
      endedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}ended_at']),
      durationSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}duration_seconds'])!,
      status: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}status'])!,
    );
  }

  @override
  $WorkoutSessionsTable createAlias(String alias) {
    return $WorkoutSessionsTable(attachedDatabase, alias);
  }
}

class WorkoutSessionEntity extends DataClass
    implements Insertable<WorkoutSessionEntity> {
  final String sessionId;
  final String planId;
  final String workoutId;
  final String? planName;
  final String? workoutName;
  final String? workoutSnapshotJson;
  final int startedAt;
  final int? endedAt;
  final int durationSeconds;
  final String status;
  const WorkoutSessionEntity(
      {required this.sessionId,
      required this.planId,
      required this.workoutId,
      this.planName,
      this.workoutName,
      this.workoutSnapshotJson,
      required this.startedAt,
      this.endedAt,
      required this.durationSeconds,
      required this.status});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['session_id'] = Variable<String>(sessionId);
    map['plan_id'] = Variable<String>(planId);
    map['workout_id'] = Variable<String>(workoutId);
    if (!nullToAbsent || planName != null) {
      map['plan_name'] = Variable<String>(planName);
    }
    if (!nullToAbsent || workoutName != null) {
      map['workout_name'] = Variable<String>(workoutName);
    }
    if (!nullToAbsent || workoutSnapshotJson != null) {
      map['workout_snapshot_json'] = Variable<String>(workoutSnapshotJson);
    }
    map['started_at'] = Variable<int>(startedAt);
    if (!nullToAbsent || endedAt != null) {
      map['ended_at'] = Variable<int>(endedAt);
    }
    map['duration_seconds'] = Variable<int>(durationSeconds);
    map['status'] = Variable<String>(status);
    return map;
  }

  WorkoutSessionsCompanion toCompanion(bool nullToAbsent) {
    return WorkoutSessionsCompanion(
      sessionId: Value(sessionId),
      planId: Value(planId),
      workoutId: Value(workoutId),
      planName: planName == null && nullToAbsent
          ? const Value.absent()
          : Value(planName),
      workoutName: workoutName == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutName),
      workoutSnapshotJson: workoutSnapshotJson == null && nullToAbsent
          ? const Value.absent()
          : Value(workoutSnapshotJson),
      startedAt: Value(startedAt),
      endedAt: endedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(endedAt),
      durationSeconds: Value(durationSeconds),
      status: Value(status),
    );
  }

  factory WorkoutSessionEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutSessionEntity(
      sessionId: serializer.fromJson<String>(json['sessionId']),
      planId: serializer.fromJson<String>(json['planId']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      planName: serializer.fromJson<String?>(json['planName']),
      workoutName: serializer.fromJson<String?>(json['workoutName']),
      workoutSnapshotJson:
          serializer.fromJson<String?>(json['workoutSnapshotJson']),
      startedAt: serializer.fromJson<int>(json['startedAt']),
      endedAt: serializer.fromJson<int?>(json['endedAt']),
      durationSeconds: serializer.fromJson<int>(json['durationSeconds']),
      status: serializer.fromJson<String>(json['status']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'sessionId': serializer.toJson<String>(sessionId),
      'planId': serializer.toJson<String>(planId),
      'workoutId': serializer.toJson<String>(workoutId),
      'planName': serializer.toJson<String?>(planName),
      'workoutName': serializer.toJson<String?>(workoutName),
      'workoutSnapshotJson': serializer.toJson<String?>(workoutSnapshotJson),
      'startedAt': serializer.toJson<int>(startedAt),
      'endedAt': serializer.toJson<int?>(endedAt),
      'durationSeconds': serializer.toJson<int>(durationSeconds),
      'status': serializer.toJson<String>(status),
    };
  }

  WorkoutSessionEntity copyWith(
          {String? sessionId,
          String? planId,
          String? workoutId,
          Value<String?> planName = const Value.absent(),
          Value<String?> workoutName = const Value.absent(),
          Value<String?> workoutSnapshotJson = const Value.absent(),
          int? startedAt,
          Value<int?> endedAt = const Value.absent(),
          int? durationSeconds,
          String? status}) =>
      WorkoutSessionEntity(
        sessionId: sessionId ?? this.sessionId,
        planId: planId ?? this.planId,
        workoutId: workoutId ?? this.workoutId,
        planName: planName.present ? planName.value : this.planName,
        workoutName: workoutName.present ? workoutName.value : this.workoutName,
        workoutSnapshotJson: workoutSnapshotJson.present
            ? workoutSnapshotJson.value
            : this.workoutSnapshotJson,
        startedAt: startedAt ?? this.startedAt,
        endedAt: endedAt.present ? endedAt.value : this.endedAt,
        durationSeconds: durationSeconds ?? this.durationSeconds,
        status: status ?? this.status,
      );
  WorkoutSessionEntity copyWithCompanion(WorkoutSessionsCompanion data) {
    return WorkoutSessionEntity(
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      planId: data.planId.present ? data.planId.value : this.planId,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      planName: data.planName.present ? data.planName.value : this.planName,
      workoutName:
          data.workoutName.present ? data.workoutName.value : this.workoutName,
      workoutSnapshotJson: data.workoutSnapshotJson.present
          ? data.workoutSnapshotJson.value
          : this.workoutSnapshotJson,
      startedAt: data.startedAt.present ? data.startedAt.value : this.startedAt,
      endedAt: data.endedAt.present ? data.endedAt.value : this.endedAt,
      durationSeconds: data.durationSeconds.present
          ? data.durationSeconds.value
          : this.durationSeconds,
      status: data.status.present ? data.status.value : this.status,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionEntity(')
          ..write('sessionId: $sessionId, ')
          ..write('planId: $planId, ')
          ..write('workoutId: $workoutId, ')
          ..write('planName: $planName, ')
          ..write('workoutName: $workoutName, ')
          ..write('workoutSnapshotJson: $workoutSnapshotJson, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      sessionId,
      planId,
      workoutId,
      planName,
      workoutName,
      workoutSnapshotJson,
      startedAt,
      endedAt,
      durationSeconds,
      status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSessionEntity &&
          other.sessionId == this.sessionId &&
          other.planId == this.planId &&
          other.workoutId == this.workoutId &&
          other.planName == this.planName &&
          other.workoutName == this.workoutName &&
          other.workoutSnapshotJson == this.workoutSnapshotJson &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationSeconds == this.durationSeconds &&
          other.status == this.status);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSessionEntity> {
  final Value<String> sessionId;
  final Value<String> planId;
  final Value<String> workoutId;
  final Value<String?> planName;
  final Value<String?> workoutName;
  final Value<String?> workoutSnapshotJson;
  final Value<int> startedAt;
  final Value<int?> endedAt;
  final Value<int> durationSeconds;
  final Value<String> status;
  final Value<int> rowid;
  const WorkoutSessionsCompanion({
    this.sessionId = const Value.absent(),
    this.planId = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.planName = const Value.absent(),
    this.workoutName = const Value.absent(),
    this.workoutSnapshotJson = const Value.absent(),
    this.startedAt = const Value.absent(),
    this.endedAt = const Value.absent(),
    this.durationSeconds = const Value.absent(),
    this.status = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutSessionsCompanion.insert({
    required String sessionId,
    required String planId,
    required String workoutId,
    this.planName = const Value.absent(),
    this.workoutName = const Value.absent(),
    this.workoutSnapshotJson = const Value.absent(),
    required int startedAt,
    this.endedAt = const Value.absent(),
    required int durationSeconds,
    required String status,
    this.rowid = const Value.absent(),
  })  : sessionId = Value(sessionId),
        planId = Value(planId),
        workoutId = Value(workoutId),
        startedAt = Value(startedAt),
        durationSeconds = Value(durationSeconds),
        status = Value(status);
  static Insertable<WorkoutSessionEntity> custom({
    Expression<String>? sessionId,
    Expression<String>? planId,
    Expression<String>? workoutId,
    Expression<String>? planName,
    Expression<String>? workoutName,
    Expression<String>? workoutSnapshotJson,
    Expression<int>? startedAt,
    Expression<int>? endedAt,
    Expression<int>? durationSeconds,
    Expression<String>? status,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (sessionId != null) 'session_id': sessionId,
      if (planId != null) 'plan_id': planId,
      if (workoutId != null) 'workout_id': workoutId,
      if (planName != null) 'plan_name': planName,
      if (workoutName != null) 'workout_name': workoutName,
      if (workoutSnapshotJson != null)
        'workout_snapshot_json': workoutSnapshotJson,
      if (startedAt != null) 'started_at': startedAt,
      if (endedAt != null) 'ended_at': endedAt,
      if (durationSeconds != null) 'duration_seconds': durationSeconds,
      if (status != null) 'status': status,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutSessionsCompanion copyWith(
      {Value<String>? sessionId,
      Value<String>? planId,
      Value<String>? workoutId,
      Value<String?>? planName,
      Value<String?>? workoutName,
      Value<String?>? workoutSnapshotJson,
      Value<int>? startedAt,
      Value<int?>? endedAt,
      Value<int>? durationSeconds,
      Value<String>? status,
      Value<int>? rowid}) {
    return WorkoutSessionsCompanion(
      sessionId: sessionId ?? this.sessionId,
      planId: planId ?? this.planId,
      workoutId: workoutId ?? this.workoutId,
      planName: planName ?? this.planName,
      workoutName: workoutName ?? this.workoutName,
      workoutSnapshotJson: workoutSnapshotJson ?? this.workoutSnapshotJson,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      durationSeconds: durationSeconds ?? this.durationSeconds,
      status: status ?? this.status,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (planName.present) {
      map['plan_name'] = Variable<String>(planName.value);
    }
    if (workoutName.present) {
      map['workout_name'] = Variable<String>(workoutName.value);
    }
    if (workoutSnapshotJson.present) {
      map['workout_snapshot_json'] =
          Variable<String>(workoutSnapshotJson.value);
    }
    if (startedAt.present) {
      map['started_at'] = Variable<int>(startedAt.value);
    }
    if (endedAt.present) {
      map['ended_at'] = Variable<int>(endedAt.value);
    }
    if (durationSeconds.present) {
      map['duration_seconds'] = Variable<int>(durationSeconds.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutSessionsCompanion(')
          ..write('sessionId: $sessionId, ')
          ..write('planId: $planId, ')
          ..write('workoutId: $workoutId, ')
          ..write('planName: $planName, ')
          ..write('workoutName: $workoutName, ')
          ..write('workoutSnapshotJson: $workoutSnapshotJson, ')
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutMovePerformancesTable extends WorkoutMovePerformances
    with
        TableInfo<$WorkoutMovePerformancesTable, WorkoutMovePerformanceEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutMovePerformancesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _performanceIdMeta =
      const VerificationMeta('performanceId');
  @override
  late final GeneratedColumn<String> performanceId = GeneratedColumn<String>(
      'performance_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _sessionIdMeta =
      const VerificationMeta('sessionId');
  @override
  late final GeneratedColumn<String> sessionId = GeneratedColumn<String>(
      'session_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _workoutIdMeta =
      const VerificationMeta('workoutId');
  @override
  late final GeneratedColumn<String> workoutId = GeneratedColumn<String>(
      'workout_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _setIdMeta = const VerificationMeta('setId');
  @override
  late final GeneratedColumn<String> setId = GeneratedColumn<String>(
      'set_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _lapIndexMeta =
      const VerificationMeta('lapIndex');
  @override
  late final GeneratedColumn<int> lapIndex = GeneratedColumn<int>(
      'lap_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _workoutMoveIdMeta =
      const VerificationMeta('workoutMoveId');
  @override
  late final GeneratedColumn<String> workoutMoveId = GeneratedColumn<String>(
      'workout_move_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _moveIdMeta = const VerificationMeta('moveId');
  @override
  late final GeneratedColumn<String> moveId = GeneratedColumn<String>(
      'move_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _repCountMeta =
      const VerificationMeta('repCount');
  @override
  late final GeneratedColumn<int> repCount = GeneratedColumn<int>(
      'rep_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _actualWeightMeta =
      const VerificationMeta('actualWeight');
  @override
  late final GeneratedColumn<double> actualWeight = GeneratedColumn<double>(
      'actual_weight', aliasedName, true,
      type: DriftSqlType.double, requiredDuringInsert: false);
  static const VerificationMeta _actualWeightUnitMeta =
      const VerificationMeta('actualWeightUnit');
  @override
  late final GeneratedColumn<String> actualWeightUnit = GeneratedColumn<String>(
      'actual_weight_unit', aliasedName, true,
      type: DriftSqlType.string, requiredDuringInsert: false);
  static const VerificationMeta _elapsedSecondsMeta =
      const VerificationMeta('elapsedSeconds');
  @override
  late final GeneratedColumn<int> elapsedSeconds = GeneratedColumn<int>(
      'elapsed_seconds', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _completedAtMeta =
      const VerificationMeta('completedAt');
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
      'completed_at', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [
        performanceId,
        sessionId,
        workoutId,
        setId,
        lapIndex,
        workoutMoveId,
        moveId,
        repCount,
        actualWeight,
        actualWeightUnit,
        elapsedSeconds,
        completedAt
      ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_move_performances';
  @override
  VerificationContext validateIntegrity(
      Insertable<WorkoutMovePerformanceEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('performance_id')) {
      context.handle(
          _performanceIdMeta,
          performanceId.isAcceptableOrUnknown(
              data['performance_id']!, _performanceIdMeta));
    } else if (isInserting) {
      context.missing(_performanceIdMeta);
    }
    if (data.containsKey('session_id')) {
      context.handle(_sessionIdMeta,
          sessionId.isAcceptableOrUnknown(data['session_id']!, _sessionIdMeta));
    } else if (isInserting) {
      context.missing(_sessionIdMeta);
    }
    if (data.containsKey('workout_id')) {
      context.handle(_workoutIdMeta,
          workoutId.isAcceptableOrUnknown(data['workout_id']!, _workoutIdMeta));
    } else if (isInserting) {
      context.missing(_workoutIdMeta);
    }
    if (data.containsKey('set_id')) {
      context.handle(
          _setIdMeta, setId.isAcceptableOrUnknown(data['set_id']!, _setIdMeta));
    } else if (isInserting) {
      context.missing(_setIdMeta);
    }
    if (data.containsKey('lap_index')) {
      context.handle(_lapIndexMeta,
          lapIndex.isAcceptableOrUnknown(data['lap_index']!, _lapIndexMeta));
    } else if (isInserting) {
      context.missing(_lapIndexMeta);
    }
    if (data.containsKey('workout_move_id')) {
      context.handle(
          _workoutMoveIdMeta,
          workoutMoveId.isAcceptableOrUnknown(
              data['workout_move_id']!, _workoutMoveIdMeta));
    } else if (isInserting) {
      context.missing(_workoutMoveIdMeta);
    }
    if (data.containsKey('move_id')) {
      context.handle(_moveIdMeta,
          moveId.isAcceptableOrUnknown(data['move_id']!, _moveIdMeta));
    } else if (isInserting) {
      context.missing(_moveIdMeta);
    }
    if (data.containsKey('rep_count')) {
      context.handle(_repCountMeta,
          repCount.isAcceptableOrUnknown(data['rep_count']!, _repCountMeta));
    } else if (isInserting) {
      context.missing(_repCountMeta);
    }
    if (data.containsKey('actual_weight')) {
      context.handle(
          _actualWeightMeta,
          actualWeight.isAcceptableOrUnknown(
              data['actual_weight']!, _actualWeightMeta));
    }
    if (data.containsKey('actual_weight_unit')) {
      context.handle(
          _actualWeightUnitMeta,
          actualWeightUnit.isAcceptableOrUnknown(
              data['actual_weight_unit']!, _actualWeightUnitMeta));
    }
    if (data.containsKey('elapsed_seconds')) {
      context.handle(
          _elapsedSecondsMeta,
          elapsedSeconds.isAcceptableOrUnknown(
              data['elapsed_seconds']!, _elapsedSecondsMeta));
    } else if (isInserting) {
      context.missing(_elapsedSecondsMeta);
    }
    if (data.containsKey('completed_at')) {
      context.handle(
          _completedAtMeta,
          completedAt.isAcceptableOrUnknown(
              data['completed_at']!, _completedAtMeta));
    } else if (isInserting) {
      context.missing(_completedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {performanceId};
  @override
  WorkoutMovePerformanceEntity map(Map<String, dynamic> data,
      {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutMovePerformanceEntity(
      performanceId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}performance_id'])!,
      sessionId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}session_id'])!,
      workoutId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}workout_id'])!,
      setId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}set_id'])!,
      lapIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}lap_index'])!,
      workoutMoveId: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}workout_move_id'])!,
      moveId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}move_id'])!,
      repCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rep_count'])!,
      actualWeight: attachedDatabase.typeMapping
          .read(DriftSqlType.double, data['${effectivePrefix}actual_weight']),
      actualWeightUnit: attachedDatabase.typeMapping.read(
          DriftSqlType.string, data['${effectivePrefix}actual_weight_unit']),
      elapsedSeconds: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}elapsed_seconds'])!,
      completedAt: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}completed_at'])!,
    );
  }

  @override
  $WorkoutMovePerformancesTable createAlias(String alias) {
    return $WorkoutMovePerformancesTable(attachedDatabase, alias);
  }
}

class WorkoutMovePerformanceEntity extends DataClass
    implements Insertable<WorkoutMovePerformanceEntity> {
  final String performanceId;
  final String sessionId;
  final String workoutId;
  final String setId;
  final int lapIndex;
  final String workoutMoveId;
  final String moveId;
  final int repCount;
  final double? actualWeight;
  final String? actualWeightUnit;
  final int elapsedSeconds;
  final int completedAt;
  const WorkoutMovePerformanceEntity(
      {required this.performanceId,
      required this.sessionId,
      required this.workoutId,
      required this.setId,
      required this.lapIndex,
      required this.workoutMoveId,
      required this.moveId,
      required this.repCount,
      this.actualWeight,
      this.actualWeightUnit,
      required this.elapsedSeconds,
      required this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['performance_id'] = Variable<String>(performanceId);
    map['session_id'] = Variable<String>(sessionId);
    map['workout_id'] = Variable<String>(workoutId);
    map['set_id'] = Variable<String>(setId);
    map['lap_index'] = Variable<int>(lapIndex);
    map['workout_move_id'] = Variable<String>(workoutMoveId);
    map['move_id'] = Variable<String>(moveId);
    map['rep_count'] = Variable<int>(repCount);
    if (!nullToAbsent || actualWeight != null) {
      map['actual_weight'] = Variable<double>(actualWeight);
    }
    if (!nullToAbsent || actualWeightUnit != null) {
      map['actual_weight_unit'] = Variable<String>(actualWeightUnit);
    }
    map['elapsed_seconds'] = Variable<int>(elapsedSeconds);
    map['completed_at'] = Variable<int>(completedAt);
    return map;
  }

  WorkoutMovePerformancesCompanion toCompanion(bool nullToAbsent) {
    return WorkoutMovePerformancesCompanion(
      performanceId: Value(performanceId),
      sessionId: Value(sessionId),
      workoutId: Value(workoutId),
      setId: Value(setId),
      lapIndex: Value(lapIndex),
      workoutMoveId: Value(workoutMoveId),
      moveId: Value(moveId),
      repCount: Value(repCount),
      actualWeight: actualWeight == null && nullToAbsent
          ? const Value.absent()
          : Value(actualWeight),
      actualWeightUnit: actualWeightUnit == null && nullToAbsent
          ? const Value.absent()
          : Value(actualWeightUnit),
      elapsedSeconds: Value(elapsedSeconds),
      completedAt: Value(completedAt),
    );
  }

  factory WorkoutMovePerformanceEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutMovePerformanceEntity(
      performanceId: serializer.fromJson<String>(json['performanceId']),
      sessionId: serializer.fromJson<String>(json['sessionId']),
      workoutId: serializer.fromJson<String>(json['workoutId']),
      setId: serializer.fromJson<String>(json['setId']),
      lapIndex: serializer.fromJson<int>(json['lapIndex']),
      workoutMoveId: serializer.fromJson<String>(json['workoutMoveId']),
      moveId: serializer.fromJson<String>(json['moveId']),
      repCount: serializer.fromJson<int>(json['repCount']),
      actualWeight: serializer.fromJson<double?>(json['actualWeight']),
      actualWeightUnit: serializer.fromJson<String?>(json['actualWeightUnit']),
      elapsedSeconds: serializer.fromJson<int>(json['elapsedSeconds']),
      completedAt: serializer.fromJson<int>(json['completedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'performanceId': serializer.toJson<String>(performanceId),
      'sessionId': serializer.toJson<String>(sessionId),
      'workoutId': serializer.toJson<String>(workoutId),
      'setId': serializer.toJson<String>(setId),
      'lapIndex': serializer.toJson<int>(lapIndex),
      'workoutMoveId': serializer.toJson<String>(workoutMoveId),
      'moveId': serializer.toJson<String>(moveId),
      'repCount': serializer.toJson<int>(repCount),
      'actualWeight': serializer.toJson<double?>(actualWeight),
      'actualWeightUnit': serializer.toJson<String?>(actualWeightUnit),
      'elapsedSeconds': serializer.toJson<int>(elapsedSeconds),
      'completedAt': serializer.toJson<int>(completedAt),
    };
  }

  WorkoutMovePerformanceEntity copyWith(
          {String? performanceId,
          String? sessionId,
          String? workoutId,
          String? setId,
          int? lapIndex,
          String? workoutMoveId,
          String? moveId,
          int? repCount,
          Value<double?> actualWeight = const Value.absent(),
          Value<String?> actualWeightUnit = const Value.absent(),
          int? elapsedSeconds,
          int? completedAt}) =>
      WorkoutMovePerformanceEntity(
        performanceId: performanceId ?? this.performanceId,
        sessionId: sessionId ?? this.sessionId,
        workoutId: workoutId ?? this.workoutId,
        setId: setId ?? this.setId,
        lapIndex: lapIndex ?? this.lapIndex,
        workoutMoveId: workoutMoveId ?? this.workoutMoveId,
        moveId: moveId ?? this.moveId,
        repCount: repCount ?? this.repCount,
        actualWeight:
            actualWeight.present ? actualWeight.value : this.actualWeight,
        actualWeightUnit: actualWeightUnit.present
            ? actualWeightUnit.value
            : this.actualWeightUnit,
        elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
        completedAt: completedAt ?? this.completedAt,
      );
  WorkoutMovePerformanceEntity copyWithCompanion(
      WorkoutMovePerformancesCompanion data) {
    return WorkoutMovePerformanceEntity(
      performanceId: data.performanceId.present
          ? data.performanceId.value
          : this.performanceId,
      sessionId: data.sessionId.present ? data.sessionId.value : this.sessionId,
      workoutId: data.workoutId.present ? data.workoutId.value : this.workoutId,
      setId: data.setId.present ? data.setId.value : this.setId,
      lapIndex: data.lapIndex.present ? data.lapIndex.value : this.lapIndex,
      workoutMoveId: data.workoutMoveId.present
          ? data.workoutMoveId.value
          : this.workoutMoveId,
      moveId: data.moveId.present ? data.moveId.value : this.moveId,
      repCount: data.repCount.present ? data.repCount.value : this.repCount,
      actualWeight: data.actualWeight.present
          ? data.actualWeight.value
          : this.actualWeight,
      actualWeightUnit: data.actualWeightUnit.present
          ? data.actualWeightUnit.value
          : this.actualWeightUnit,
      elapsedSeconds: data.elapsedSeconds.present
          ? data.elapsedSeconds.value
          : this.elapsedSeconds,
      completedAt:
          data.completedAt.present ? data.completedAt.value : this.completedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutMovePerformanceEntity(')
          ..write('performanceId: $performanceId, ')
          ..write('sessionId: $sessionId, ')
          ..write('workoutId: $workoutId, ')
          ..write('setId: $setId, ')
          ..write('lapIndex: $lapIndex, ')
          ..write('workoutMoveId: $workoutMoveId, ')
          ..write('moveId: $moveId, ')
          ..write('repCount: $repCount, ')
          ..write('actualWeight: $actualWeight, ')
          ..write('actualWeightUnit: $actualWeightUnit, ')
          ..write('elapsedSeconds: $elapsedSeconds, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
      performanceId,
      sessionId,
      workoutId,
      setId,
      lapIndex,
      workoutMoveId,
      moveId,
      repCount,
      actualWeight,
      actualWeightUnit,
      elapsedSeconds,
      completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutMovePerformanceEntity &&
          other.performanceId == this.performanceId &&
          other.sessionId == this.sessionId &&
          other.workoutId == this.workoutId &&
          other.setId == this.setId &&
          other.lapIndex == this.lapIndex &&
          other.workoutMoveId == this.workoutMoveId &&
          other.moveId == this.moveId &&
          other.repCount == this.repCount &&
          other.actualWeight == this.actualWeight &&
          other.actualWeightUnit == this.actualWeightUnit &&
          other.elapsedSeconds == this.elapsedSeconds &&
          other.completedAt == this.completedAt);
}

class WorkoutMovePerformancesCompanion
    extends UpdateCompanion<WorkoutMovePerformanceEntity> {
  final Value<String> performanceId;
  final Value<String> sessionId;
  final Value<String> workoutId;
  final Value<String> setId;
  final Value<int> lapIndex;
  final Value<String> workoutMoveId;
  final Value<String> moveId;
  final Value<int> repCount;
  final Value<double?> actualWeight;
  final Value<String?> actualWeightUnit;
  final Value<int> elapsedSeconds;
  final Value<int> completedAt;
  final Value<int> rowid;
  const WorkoutMovePerformancesCompanion({
    this.performanceId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.setId = const Value.absent(),
    this.lapIndex = const Value.absent(),
    this.workoutMoveId = const Value.absent(),
    this.moveId = const Value.absent(),
    this.repCount = const Value.absent(),
    this.actualWeight = const Value.absent(),
    this.actualWeightUnit = const Value.absent(),
    this.elapsedSeconds = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutMovePerformancesCompanion.insert({
    required String performanceId,
    required String sessionId,
    required String workoutId,
    required String setId,
    required int lapIndex,
    required String workoutMoveId,
    required String moveId,
    required int repCount,
    this.actualWeight = const Value.absent(),
    this.actualWeightUnit = const Value.absent(),
    required int elapsedSeconds,
    required int completedAt,
    this.rowid = const Value.absent(),
  })  : performanceId = Value(performanceId),
        sessionId = Value(sessionId),
        workoutId = Value(workoutId),
        setId = Value(setId),
        lapIndex = Value(lapIndex),
        workoutMoveId = Value(workoutMoveId),
        moveId = Value(moveId),
        repCount = Value(repCount),
        elapsedSeconds = Value(elapsedSeconds),
        completedAt = Value(completedAt);
  static Insertable<WorkoutMovePerformanceEntity> custom({
    Expression<String>? performanceId,
    Expression<String>? sessionId,
    Expression<String>? workoutId,
    Expression<String>? setId,
    Expression<int>? lapIndex,
    Expression<String>? workoutMoveId,
    Expression<String>? moveId,
    Expression<int>? repCount,
    Expression<double>? actualWeight,
    Expression<String>? actualWeightUnit,
    Expression<int>? elapsedSeconds,
    Expression<int>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (performanceId != null) 'performance_id': performanceId,
      if (sessionId != null) 'session_id': sessionId,
      if (workoutId != null) 'workout_id': workoutId,
      if (setId != null) 'set_id': setId,
      if (lapIndex != null) 'lap_index': lapIndex,
      if (workoutMoveId != null) 'workout_move_id': workoutMoveId,
      if (moveId != null) 'move_id': moveId,
      if (repCount != null) 'rep_count': repCount,
      if (actualWeight != null) 'actual_weight': actualWeight,
      if (actualWeightUnit != null) 'actual_weight_unit': actualWeightUnit,
      if (elapsedSeconds != null) 'elapsed_seconds': elapsedSeconds,
      if (completedAt != null) 'completed_at': completedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutMovePerformancesCompanion copyWith(
      {Value<String>? performanceId,
      Value<String>? sessionId,
      Value<String>? workoutId,
      Value<String>? setId,
      Value<int>? lapIndex,
      Value<String>? workoutMoveId,
      Value<String>? moveId,
      Value<int>? repCount,
      Value<double?>? actualWeight,
      Value<String?>? actualWeightUnit,
      Value<int>? elapsedSeconds,
      Value<int>? completedAt,
      Value<int>? rowid}) {
    return WorkoutMovePerformancesCompanion(
      performanceId: performanceId ?? this.performanceId,
      sessionId: sessionId ?? this.sessionId,
      workoutId: workoutId ?? this.workoutId,
      setId: setId ?? this.setId,
      lapIndex: lapIndex ?? this.lapIndex,
      workoutMoveId: workoutMoveId ?? this.workoutMoveId,
      moveId: moveId ?? this.moveId,
      repCount: repCount ?? this.repCount,
      actualWeight: actualWeight ?? this.actualWeight,
      actualWeightUnit: actualWeightUnit ?? this.actualWeightUnit,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      completedAt: completedAt ?? this.completedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (performanceId.present) {
      map['performance_id'] = Variable<String>(performanceId.value);
    }
    if (sessionId.present) {
      map['session_id'] = Variable<String>(sessionId.value);
    }
    if (workoutId.present) {
      map['workout_id'] = Variable<String>(workoutId.value);
    }
    if (setId.present) {
      map['set_id'] = Variable<String>(setId.value);
    }
    if (lapIndex.present) {
      map['lap_index'] = Variable<int>(lapIndex.value);
    }
    if (workoutMoveId.present) {
      map['workout_move_id'] = Variable<String>(workoutMoveId.value);
    }
    if (moveId.present) {
      map['move_id'] = Variable<String>(moveId.value);
    }
    if (repCount.present) {
      map['rep_count'] = Variable<int>(repCount.value);
    }
    if (actualWeight.present) {
      map['actual_weight'] = Variable<double>(actualWeight.value);
    }
    if (actualWeightUnit.present) {
      map['actual_weight_unit'] = Variable<String>(actualWeightUnit.value);
    }
    if (elapsedSeconds.present) {
      map['elapsed_seconds'] = Variable<int>(elapsedSeconds.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutMovePerformancesCompanion(')
          ..write('performanceId: $performanceId, ')
          ..write('sessionId: $sessionId, ')
          ..write('workoutId: $workoutId, ')
          ..write('setId: $setId, ')
          ..write('lapIndex: $lapIndex, ')
          ..write('workoutMoveId: $workoutMoveId, ')
          ..write('moveId: $moveId, ')
          ..write('repCount: $repCount, ')
          ..write('actualWeight: $actualWeight, ')
          ..write('actualWeightUnit: $actualWeightUnit, ')
          ..write('elapsedSeconds: $elapsedSeconds, ')
          ..write('completedAt: $completedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$HistoryDatabase extends GeneratedDatabase {
  _$HistoryDatabase(QueryExecutor e) : super(e);
  $HistoryDatabaseManager get managers => $HistoryDatabaseManager(this);
  late final $WorkoutSessionsTable workoutSessions =
      $WorkoutSessionsTable(this);
  late final $WorkoutMovePerformancesTable workoutMovePerformances =
      $WorkoutMovePerformancesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [workoutSessions, workoutMovePerformances];
}

typedef $$WorkoutSessionsTableCreateCompanionBuilder = WorkoutSessionsCompanion
    Function({
  required String sessionId,
  required String planId,
  required String workoutId,
  Value<String?> planName,
  Value<String?> workoutName,
  Value<String?> workoutSnapshotJson,
  required int startedAt,
  Value<int?> endedAt,
  required int durationSeconds,
  required String status,
  Value<int> rowid,
});
typedef $$WorkoutSessionsTableUpdateCompanionBuilder = WorkoutSessionsCompanion
    Function({
  Value<String> sessionId,
  Value<String> planId,
  Value<String> workoutId,
  Value<String?> planName,
  Value<String?> workoutName,
  Value<String?> workoutSnapshotJson,
  Value<int> startedAt,
  Value<int?> endedAt,
  Value<int> durationSeconds,
  Value<String> status,
  Value<int> rowid,
});

class $$WorkoutSessionsTableFilterComposer
    extends Composer<_$HistoryDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workoutId => $composableBuilder(
      column: $table.workoutId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get planName => $composableBuilder(
      column: $table.planName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workoutName => $composableBuilder(
      column: $table.workoutName, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workoutSnapshotJson => $composableBuilder(
      column: $table.workoutSnapshotJson,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnFilters(column));
}

class $$WorkoutSessionsTableOrderingComposer
    extends Composer<_$HistoryDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workoutId => $composableBuilder(
      column: $table.workoutId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get planName => $composableBuilder(
      column: $table.planName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workoutName => $composableBuilder(
      column: $table.workoutName, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workoutSnapshotJson => $composableBuilder(
      column: $table.workoutSnapshotJson,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get startedAt => $composableBuilder(
      column: $table.startedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get endedAt => $composableBuilder(
      column: $table.endedAt, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get status => $composableBuilder(
      column: $table.status, builder: (column) => ColumnOrderings(column));
}

class $$WorkoutSessionsTableAnnotationComposer
    extends Composer<_$HistoryDatabase, $WorkoutSessionsTable> {
  $$WorkoutSessionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get workoutId =>
      $composableBuilder(column: $table.workoutId, builder: (column) => column);

  GeneratedColumn<String> get planName =>
      $composableBuilder(column: $table.planName, builder: (column) => column);

  GeneratedColumn<String> get workoutName => $composableBuilder(
      column: $table.workoutName, builder: (column) => column);

  GeneratedColumn<String> get workoutSnapshotJson => $composableBuilder(
      column: $table.workoutSnapshotJson, builder: (column) => column);

  GeneratedColumn<int> get startedAt =>
      $composableBuilder(column: $table.startedAt, builder: (column) => column);

  GeneratedColumn<int> get endedAt =>
      $composableBuilder(column: $table.endedAt, builder: (column) => column);

  GeneratedColumn<int> get durationSeconds => $composableBuilder(
      column: $table.durationSeconds, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);
}

class $$WorkoutSessionsTableTableManager extends RootTableManager<
    _$HistoryDatabase,
    $WorkoutSessionsTable,
    WorkoutSessionEntity,
    $$WorkoutSessionsTableFilterComposer,
    $$WorkoutSessionsTableOrderingComposer,
    $$WorkoutSessionsTableAnnotationComposer,
    $$WorkoutSessionsTableCreateCompanionBuilder,
    $$WorkoutSessionsTableUpdateCompanionBuilder,
    (
      WorkoutSessionEntity,
      BaseReferences<_$HistoryDatabase, $WorkoutSessionsTable,
          WorkoutSessionEntity>
    ),
    WorkoutSessionEntity,
    PrefetchHooks Function()> {
  $$WorkoutSessionsTableTableManager(
      _$HistoryDatabase db, $WorkoutSessionsTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutSessionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutSessionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutSessionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> sessionId = const Value.absent(),
            Value<String> planId = const Value.absent(),
            Value<String> workoutId = const Value.absent(),
            Value<String?> planName = const Value.absent(),
            Value<String?> workoutName = const Value.absent(),
            Value<String?> workoutSnapshotJson = const Value.absent(),
            Value<int> startedAt = const Value.absent(),
            Value<int?> endedAt = const Value.absent(),
            Value<int> durationSeconds = const Value.absent(),
            Value<String> status = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutSessionsCompanion(
            sessionId: sessionId,
            planId: planId,
            workoutId: workoutId,
            planName: planName,
            workoutName: workoutName,
            workoutSnapshotJson: workoutSnapshotJson,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: durationSeconds,
            status: status,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String sessionId,
            required String planId,
            required String workoutId,
            Value<String?> planName = const Value.absent(),
            Value<String?> workoutName = const Value.absent(),
            Value<String?> workoutSnapshotJson = const Value.absent(),
            required int startedAt,
            Value<int?> endedAt = const Value.absent(),
            required int durationSeconds,
            required String status,
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutSessionsCompanion.insert(
            sessionId: sessionId,
            planId: planId,
            workoutId: workoutId,
            planName: planName,
            workoutName: workoutName,
            workoutSnapshotJson: workoutSnapshotJson,
            startedAt: startedAt,
            endedAt: endedAt,
            durationSeconds: durationSeconds,
            status: status,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WorkoutSessionsTableProcessedTableManager = ProcessedTableManager<
    _$HistoryDatabase,
    $WorkoutSessionsTable,
    WorkoutSessionEntity,
    $$WorkoutSessionsTableFilterComposer,
    $$WorkoutSessionsTableOrderingComposer,
    $$WorkoutSessionsTableAnnotationComposer,
    $$WorkoutSessionsTableCreateCompanionBuilder,
    $$WorkoutSessionsTableUpdateCompanionBuilder,
    (
      WorkoutSessionEntity,
      BaseReferences<_$HistoryDatabase, $WorkoutSessionsTable,
          WorkoutSessionEntity>
    ),
    WorkoutSessionEntity,
    PrefetchHooks Function()>;
typedef $$WorkoutMovePerformancesTableCreateCompanionBuilder
    = WorkoutMovePerformancesCompanion Function({
  required String performanceId,
  required String sessionId,
  required String workoutId,
  required String setId,
  required int lapIndex,
  required String workoutMoveId,
  required String moveId,
  required int repCount,
  Value<double?> actualWeight,
  Value<String?> actualWeightUnit,
  required int elapsedSeconds,
  required int completedAt,
  Value<int> rowid,
});
typedef $$WorkoutMovePerformancesTableUpdateCompanionBuilder
    = WorkoutMovePerformancesCompanion Function({
  Value<String> performanceId,
  Value<String> sessionId,
  Value<String> workoutId,
  Value<String> setId,
  Value<int> lapIndex,
  Value<String> workoutMoveId,
  Value<String> moveId,
  Value<int> repCount,
  Value<double?> actualWeight,
  Value<String?> actualWeightUnit,
  Value<int> elapsedSeconds,
  Value<int> completedAt,
  Value<int> rowid,
});

class $$WorkoutMovePerformancesTableFilterComposer
    extends Composer<_$HistoryDatabase, $WorkoutMovePerformancesTable> {
  $$WorkoutMovePerformancesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get performanceId => $composableBuilder(
      column: $table.performanceId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workoutId => $composableBuilder(
      column: $table.workoutId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get setId => $composableBuilder(
      column: $table.setId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get lapIndex => $composableBuilder(
      column: $table.lapIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get workoutMoveId => $composableBuilder(
      column: $table.workoutMoveId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get moveId => $composableBuilder(
      column: $table.moveId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get repCount => $composableBuilder(
      column: $table.repCount, builder: (column) => ColumnFilters(column));

  ColumnFilters<double> get actualWeight => $composableBuilder(
      column: $table.actualWeight, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get actualWeightUnit => $composableBuilder(
      column: $table.actualWeightUnit,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get elapsedSeconds => $composableBuilder(
      column: $table.elapsedSeconds,
      builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnFilters(column));
}

class $$WorkoutMovePerformancesTableOrderingComposer
    extends Composer<_$HistoryDatabase, $WorkoutMovePerformancesTable> {
  $$WorkoutMovePerformancesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get performanceId => $composableBuilder(
      column: $table.performanceId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get sessionId => $composableBuilder(
      column: $table.sessionId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workoutId => $composableBuilder(
      column: $table.workoutId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get setId => $composableBuilder(
      column: $table.setId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get lapIndex => $composableBuilder(
      column: $table.lapIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get workoutMoveId => $composableBuilder(
      column: $table.workoutMoveId,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get moveId => $composableBuilder(
      column: $table.moveId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get repCount => $composableBuilder(
      column: $table.repCount, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<double> get actualWeight => $composableBuilder(
      column: $table.actualWeight,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get actualWeightUnit => $composableBuilder(
      column: $table.actualWeightUnit,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get elapsedSeconds => $composableBuilder(
      column: $table.elapsedSeconds,
      builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => ColumnOrderings(column));
}

class $$WorkoutMovePerformancesTableAnnotationComposer
    extends Composer<_$HistoryDatabase, $WorkoutMovePerformancesTable> {
  $$WorkoutMovePerformancesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get performanceId => $composableBuilder(
      column: $table.performanceId, builder: (column) => column);

  GeneratedColumn<String> get sessionId =>
      $composableBuilder(column: $table.sessionId, builder: (column) => column);

  GeneratedColumn<String> get workoutId =>
      $composableBuilder(column: $table.workoutId, builder: (column) => column);

  GeneratedColumn<String> get setId =>
      $composableBuilder(column: $table.setId, builder: (column) => column);

  GeneratedColumn<int> get lapIndex =>
      $composableBuilder(column: $table.lapIndex, builder: (column) => column);

  GeneratedColumn<String> get workoutMoveId => $composableBuilder(
      column: $table.workoutMoveId, builder: (column) => column);

  GeneratedColumn<String> get moveId =>
      $composableBuilder(column: $table.moveId, builder: (column) => column);

  GeneratedColumn<int> get repCount =>
      $composableBuilder(column: $table.repCount, builder: (column) => column);

  GeneratedColumn<double> get actualWeight => $composableBuilder(
      column: $table.actualWeight, builder: (column) => column);

  GeneratedColumn<String> get actualWeightUnit => $composableBuilder(
      column: $table.actualWeightUnit, builder: (column) => column);

  GeneratedColumn<int> get elapsedSeconds => $composableBuilder(
      column: $table.elapsedSeconds, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
      column: $table.completedAt, builder: (column) => column);
}

class $$WorkoutMovePerformancesTableTableManager extends RootTableManager<
    _$HistoryDatabase,
    $WorkoutMovePerformancesTable,
    WorkoutMovePerformanceEntity,
    $$WorkoutMovePerformancesTableFilterComposer,
    $$WorkoutMovePerformancesTableOrderingComposer,
    $$WorkoutMovePerformancesTableAnnotationComposer,
    $$WorkoutMovePerformancesTableCreateCompanionBuilder,
    $$WorkoutMovePerformancesTableUpdateCompanionBuilder,
    (
      WorkoutMovePerformanceEntity,
      BaseReferences<_$HistoryDatabase, $WorkoutMovePerformancesTable,
          WorkoutMovePerformanceEntity>
    ),
    WorkoutMovePerformanceEntity,
    PrefetchHooks Function()> {
  $$WorkoutMovePerformancesTableTableManager(
      _$HistoryDatabase db, $WorkoutMovePerformancesTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutMovePerformancesTableFilterComposer(
                  $db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutMovePerformancesTableOrderingComposer(
                  $db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutMovePerformancesTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> performanceId = const Value.absent(),
            Value<String> sessionId = const Value.absent(),
            Value<String> workoutId = const Value.absent(),
            Value<String> setId = const Value.absent(),
            Value<int> lapIndex = const Value.absent(),
            Value<String> workoutMoveId = const Value.absent(),
            Value<String> moveId = const Value.absent(),
            Value<int> repCount = const Value.absent(),
            Value<double?> actualWeight = const Value.absent(),
            Value<String?> actualWeightUnit = const Value.absent(),
            Value<int> elapsedSeconds = const Value.absent(),
            Value<int> completedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutMovePerformancesCompanion(
            performanceId: performanceId,
            sessionId: sessionId,
            workoutId: workoutId,
            setId: setId,
            lapIndex: lapIndex,
            workoutMoveId: workoutMoveId,
            moveId: moveId,
            repCount: repCount,
            actualWeight: actualWeight,
            actualWeightUnit: actualWeightUnit,
            elapsedSeconds: elapsedSeconds,
            completedAt: completedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String performanceId,
            required String sessionId,
            required String workoutId,
            required String setId,
            required int lapIndex,
            required String workoutMoveId,
            required String moveId,
            required int repCount,
            Value<double?> actualWeight = const Value.absent(),
            Value<String?> actualWeightUnit = const Value.absent(),
            required int elapsedSeconds,
            required int completedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutMovePerformancesCompanion.insert(
            performanceId: performanceId,
            sessionId: sessionId,
            workoutId: workoutId,
            setId: setId,
            lapIndex: lapIndex,
            workoutMoveId: workoutMoveId,
            moveId: moveId,
            repCount: repCount,
            actualWeight: actualWeight,
            actualWeightUnit: actualWeightUnit,
            elapsedSeconds: elapsedSeconds,
            completedAt: completedAt,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WorkoutMovePerformancesTableProcessedTableManager
    = ProcessedTableManager<
        _$HistoryDatabase,
        $WorkoutMovePerformancesTable,
        WorkoutMovePerformanceEntity,
        $$WorkoutMovePerformancesTableFilterComposer,
        $$WorkoutMovePerformancesTableOrderingComposer,
        $$WorkoutMovePerformancesTableAnnotationComposer,
        $$WorkoutMovePerformancesTableCreateCompanionBuilder,
        $$WorkoutMovePerformancesTableUpdateCompanionBuilder,
        (
          WorkoutMovePerformanceEntity,
          BaseReferences<_$HistoryDatabase, $WorkoutMovePerformancesTable,
              WorkoutMovePerformanceEntity>
        ),
        WorkoutMovePerformanceEntity,
        PrefetchHooks Function()>;

class $HistoryDatabaseManager {
  final _$HistoryDatabase _db;
  $HistoryDatabaseManager(this._db);
  $$WorkoutSessionsTableTableManager get workoutSessions =>
      $$WorkoutSessionsTableTableManager(_db, _db.workoutSessions);
  $$WorkoutMovePerformancesTableTableManager get workoutMovePerformances =>
      $$WorkoutMovePerformancesTableTableManager(
          _db, _db.workoutMovePerformances);
}
