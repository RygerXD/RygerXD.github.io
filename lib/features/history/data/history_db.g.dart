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
  final int startedAt;
  final int? endedAt;
  final int durationSeconds;
  final String status;
  const WorkoutSessionEntity(
      {required this.sessionId,
      required this.planId,
      required this.workoutId,
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
          int? startedAt,
          Value<int?> endedAt = const Value.absent(),
          int? durationSeconds,
          String? status}) =>
      WorkoutSessionEntity(
        sessionId: sessionId ?? this.sessionId,
        planId: planId ?? this.planId,
        workoutId: workoutId ?? this.workoutId,
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
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('status: $status')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(sessionId, planId, workoutId, startedAt,
      endedAt, durationSeconds, status);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutSessionEntity &&
          other.sessionId == this.sessionId &&
          other.planId == this.planId &&
          other.workoutId == this.workoutId &&
          other.startedAt == this.startedAt &&
          other.endedAt == this.endedAt &&
          other.durationSeconds == this.durationSeconds &&
          other.status == this.status);
}

class WorkoutSessionsCompanion extends UpdateCompanion<WorkoutSessionEntity> {
  final Value<String> sessionId;
  final Value<String> planId;
  final Value<String> workoutId;
  final Value<int> startedAt;
  final Value<int?> endedAt;
  final Value<int> durationSeconds;
  final Value<String> status;
  final Value<int> rowid;
  const WorkoutSessionsCompanion({
    this.sessionId = const Value.absent(),
    this.planId = const Value.absent(),
    this.workoutId = const Value.absent(),
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
      Value<int>? startedAt,
      Value<int?>? endedAt,
      Value<int>? durationSeconds,
      Value<String>? status,
      Value<int>? rowid}) {
    return WorkoutSessionsCompanion(
      sessionId: sessionId ?? this.sessionId,
      planId: planId ?? this.planId,
      workoutId: workoutId ?? this.workoutId,
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
          ..write('startedAt: $startedAt, ')
          ..write('endedAt: $endedAt, ')
          ..write('durationSeconds: $durationSeconds, ')
          ..write('status: $status, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $WorkoutPlansTableTable extends WorkoutPlansTable
    with TableInfo<$WorkoutPlansTableTable, WorkoutPlanEntity> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $WorkoutPlansTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _planIdMeta = const VerificationMeta('planId');
  @override
  late final GeneratedColumn<String> planId = GeneratedColumn<String>(
      'plan_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _jsonPayloadMeta =
      const VerificationMeta('jsonPayload');
  @override
  late final GeneratedColumn<String> jsonPayload = GeneratedColumn<String>(
      'json_payload', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  @override
  List<GeneratedColumn> get $columns => [planId, jsonPayload];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'workout_plans_table';
  @override
  VerificationContext validateIntegrity(Insertable<WorkoutPlanEntity> instance,
      {bool isInserting = false}) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('plan_id')) {
      context.handle(_planIdMeta,
          planId.isAcceptableOrUnknown(data['plan_id']!, _planIdMeta));
    } else if (isInserting) {
      context.missing(_planIdMeta);
    }
    if (data.containsKey('json_payload')) {
      context.handle(
          _jsonPayloadMeta,
          jsonPayload.isAcceptableOrUnknown(
              data['json_payload']!, _jsonPayloadMeta));
    } else if (isInserting) {
      context.missing(_jsonPayloadMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {planId};
  @override
  WorkoutPlanEntity map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return WorkoutPlanEntity(
      planId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}plan_id'])!,
      jsonPayload: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}json_payload'])!,
    );
  }

  @override
  $WorkoutPlansTableTable createAlias(String alias) {
    return $WorkoutPlansTableTable(attachedDatabase, alias);
  }
}

class WorkoutPlanEntity extends DataClass
    implements Insertable<WorkoutPlanEntity> {
  final String planId;
  final String jsonPayload;
  const WorkoutPlanEntity({required this.planId, required this.jsonPayload});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['plan_id'] = Variable<String>(planId);
    map['json_payload'] = Variable<String>(jsonPayload);
    return map;
  }

  WorkoutPlansTableCompanion toCompanion(bool nullToAbsent) {
    return WorkoutPlansTableCompanion(
      planId: Value(planId),
      jsonPayload: Value(jsonPayload),
    );
  }

  factory WorkoutPlanEntity.fromJson(Map<String, dynamic> json,
      {ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return WorkoutPlanEntity(
      planId: serializer.fromJson<String>(json['planId']),
      jsonPayload: serializer.fromJson<String>(json['jsonPayload']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'planId': serializer.toJson<String>(planId),
      'jsonPayload': serializer.toJson<String>(jsonPayload),
    };
  }

  WorkoutPlanEntity copyWith({String? planId, String? jsonPayload}) =>
      WorkoutPlanEntity(
        planId: planId ?? this.planId,
        jsonPayload: jsonPayload ?? this.jsonPayload,
      );
  WorkoutPlanEntity copyWithCompanion(WorkoutPlansTableCompanion data) {
    return WorkoutPlanEntity(
      planId: data.planId.present ? data.planId.value : this.planId,
      jsonPayload:
          data.jsonPayload.present ? data.jsonPayload.value : this.jsonPayload,
    );
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutPlanEntity(')
          ..write('planId: $planId, ')
          ..write('jsonPayload: $jsonPayload')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(planId, jsonPayload);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutPlanEntity &&
          other.planId == this.planId &&
          other.jsonPayload == this.jsonPayload);
}

class WorkoutPlansTableCompanion extends UpdateCompanion<WorkoutPlanEntity> {
  final Value<String> planId;
  final Value<String> jsonPayload;
  final Value<int> rowid;
  const WorkoutPlansTableCompanion({
    this.planId = const Value.absent(),
    this.jsonPayload = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutPlansTableCompanion.insert({
    required String planId,
    required String jsonPayload,
    this.rowid = const Value.absent(),
  })  : planId = Value(planId),
        jsonPayload = Value(jsonPayload);
  static Insertable<WorkoutPlanEntity> custom({
    Expression<String>? planId,
    Expression<String>? jsonPayload,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (planId != null) 'plan_id': planId,
      if (jsonPayload != null) 'json_payload': jsonPayload,
      if (rowid != null) 'rowid': rowid,
    });
  }

  WorkoutPlansTableCompanion copyWith(
      {Value<String>? planId, Value<String>? jsonPayload, Value<int>? rowid}) {
    return WorkoutPlansTableCompanion(
      planId: planId ?? this.planId,
      jsonPayload: jsonPayload ?? this.jsonPayload,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (planId.present) {
      map['plan_id'] = Variable<String>(planId.value);
    }
    if (jsonPayload.present) {
      map['json_payload'] = Variable<String>(jsonPayload.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('WorkoutPlansTableCompanion(')
          ..write('planId: $planId, ')
          ..write('jsonPayload: $jsonPayload, ')
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
  static const VerificationMeta _loopIndexMeta =
      const VerificationMeta('loopIndex');
  @override
  late final GeneratedColumn<int> loopIndex = GeneratedColumn<int>(
      'loop_index', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
  static const VerificationMeta _moveIdMeta = const VerificationMeta('moveId');
  @override
  late final GeneratedColumn<String> moveId = GeneratedColumn<String>(
      'move_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _exerciseIdMeta =
      const VerificationMeta('exerciseId');
  @override
  late final GeneratedColumn<String> exerciseId = GeneratedColumn<String>(
      'exercise_id', aliasedName, false,
      type: DriftSqlType.string, requiredDuringInsert: true);
  static const VerificationMeta _repCountMeta =
      const VerificationMeta('repCount');
  @override
  late final GeneratedColumn<int> repCount = GeneratedColumn<int>(
      'rep_count', aliasedName, false,
      type: DriftSqlType.int, requiredDuringInsert: true);
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
        loopIndex,
        moveId,
        exerciseId,
        repCount,
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
    if (data.containsKey('loop_index')) {
      context.handle(_loopIndexMeta,
          loopIndex.isAcceptableOrUnknown(data['loop_index']!, _loopIndexMeta));
    } else if (isInserting) {
      context.missing(_loopIndexMeta);
    }
    if (data.containsKey('move_id')) {
      context.handle(_moveIdMeta,
          moveId.isAcceptableOrUnknown(data['move_id']!, _moveIdMeta));
    } else if (isInserting) {
      context.missing(_moveIdMeta);
    }
    if (data.containsKey('exercise_id')) {
      context.handle(
          _exerciseIdMeta,
          exerciseId.isAcceptableOrUnknown(
              data['exercise_id']!, _exerciseIdMeta));
    } else if (isInserting) {
      context.missing(_exerciseIdMeta);
    }
    if (data.containsKey('rep_count')) {
      context.handle(_repCountMeta,
          repCount.isAcceptableOrUnknown(data['rep_count']!, _repCountMeta));
    } else if (isInserting) {
      context.missing(_repCountMeta);
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
      loopIndex: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}loop_index'])!,
      moveId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}move_id'])!,
      exerciseId: attachedDatabase.typeMapping
          .read(DriftSqlType.string, data['${effectivePrefix}exercise_id'])!,
      repCount: attachedDatabase.typeMapping
          .read(DriftSqlType.int, data['${effectivePrefix}rep_count'])!,
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
  final int loopIndex;
  final String moveId;
  final String exerciseId;
  final int repCount;
  final int elapsedSeconds;
  final int completedAt;
  const WorkoutMovePerformanceEntity(
      {required this.performanceId,
      required this.sessionId,
      required this.workoutId,
      required this.setId,
      required this.loopIndex,
      required this.moveId,
      required this.exerciseId,
      required this.repCount,
      required this.elapsedSeconds,
      required this.completedAt});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['performance_id'] = Variable<String>(performanceId);
    map['session_id'] = Variable<String>(sessionId);
    map['workout_id'] = Variable<String>(workoutId);
    map['set_id'] = Variable<String>(setId);
    map['loop_index'] = Variable<int>(loopIndex);
    map['move_id'] = Variable<String>(moveId);
    map['exercise_id'] = Variable<String>(exerciseId);
    map['rep_count'] = Variable<int>(repCount);
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
      loopIndex: Value(loopIndex),
      moveId: Value(moveId),
      exerciseId: Value(exerciseId),
      repCount: Value(repCount),
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
      loopIndex: serializer.fromJson<int>(json['loopIndex']),
      moveId: serializer.fromJson<String>(json['moveId']),
      exerciseId: serializer.fromJson<String>(json['exerciseId']),
      repCount: serializer.fromJson<int>(json['repCount']),
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
      'loopIndex': serializer.toJson<int>(loopIndex),
      'moveId': serializer.toJson<String>(moveId),
      'exerciseId': serializer.toJson<String>(exerciseId),
      'repCount': serializer.toJson<int>(repCount),
      'elapsedSeconds': serializer.toJson<int>(elapsedSeconds),
      'completedAt': serializer.toJson<int>(completedAt),
    };
  }

  WorkoutMovePerformanceEntity copyWith(
          {String? performanceId,
          String? sessionId,
          String? workoutId,
          String? setId,
          int? loopIndex,
          String? moveId,
          String? exerciseId,
          int? repCount,
          int? elapsedSeconds,
          int? completedAt}) =>
      WorkoutMovePerformanceEntity(
        performanceId: performanceId ?? this.performanceId,
        sessionId: sessionId ?? this.sessionId,
        workoutId: workoutId ?? this.workoutId,
        setId: setId ?? this.setId,
        loopIndex: loopIndex ?? this.loopIndex,
        moveId: moveId ?? this.moveId,
        exerciseId: exerciseId ?? this.exerciseId,
        repCount: repCount ?? this.repCount,
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
      loopIndex: data.loopIndex.present ? data.loopIndex.value : this.loopIndex,
      moveId: data.moveId.present ? data.moveId.value : this.moveId,
      exerciseId:
          data.exerciseId.present ? data.exerciseId.value : this.exerciseId,
      repCount: data.repCount.present ? data.repCount.value : this.repCount,
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
          ..write('loopIndex: $loopIndex, ')
          ..write('moveId: $moveId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('repCount: $repCount, ')
          ..write('elapsedSeconds: $elapsedSeconds, ')
          ..write('completedAt: $completedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(performanceId, sessionId, workoutId, setId,
      loopIndex, moveId, exerciseId, repCount, elapsedSeconds, completedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is WorkoutMovePerformanceEntity &&
          other.performanceId == this.performanceId &&
          other.sessionId == this.sessionId &&
          other.workoutId == this.workoutId &&
          other.setId == this.setId &&
          other.loopIndex == this.loopIndex &&
          other.moveId == this.moveId &&
          other.exerciseId == this.exerciseId &&
          other.repCount == this.repCount &&
          other.elapsedSeconds == this.elapsedSeconds &&
          other.completedAt == this.completedAt);
}

class WorkoutMovePerformancesCompanion
    extends UpdateCompanion<WorkoutMovePerformanceEntity> {
  final Value<String> performanceId;
  final Value<String> sessionId;
  final Value<String> workoutId;
  final Value<String> setId;
  final Value<int> loopIndex;
  final Value<String> moveId;
  final Value<String> exerciseId;
  final Value<int> repCount;
  final Value<int> elapsedSeconds;
  final Value<int> completedAt;
  final Value<int> rowid;
  const WorkoutMovePerformancesCompanion({
    this.performanceId = const Value.absent(),
    this.sessionId = const Value.absent(),
    this.workoutId = const Value.absent(),
    this.setId = const Value.absent(),
    this.loopIndex = const Value.absent(),
    this.moveId = const Value.absent(),
    this.exerciseId = const Value.absent(),
    this.repCount = const Value.absent(),
    this.elapsedSeconds = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  WorkoutMovePerformancesCompanion.insert({
    required String performanceId,
    required String sessionId,
    required String workoutId,
    required String setId,
    required int loopIndex,
    required String moveId,
    required String exerciseId,
    required int repCount,
    required int elapsedSeconds,
    required int completedAt,
    this.rowid = const Value.absent(),
  })  : performanceId = Value(performanceId),
        sessionId = Value(sessionId),
        workoutId = Value(workoutId),
        setId = Value(setId),
        loopIndex = Value(loopIndex),
        moveId = Value(moveId),
        exerciseId = Value(exerciseId),
        repCount = Value(repCount),
        elapsedSeconds = Value(elapsedSeconds),
        completedAt = Value(completedAt);
  static Insertable<WorkoutMovePerformanceEntity> custom({
    Expression<String>? performanceId,
    Expression<String>? sessionId,
    Expression<String>? workoutId,
    Expression<String>? setId,
    Expression<int>? loopIndex,
    Expression<String>? moveId,
    Expression<String>? exerciseId,
    Expression<int>? repCount,
    Expression<int>? elapsedSeconds,
    Expression<int>? completedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (performanceId != null) 'performance_id': performanceId,
      if (sessionId != null) 'session_id': sessionId,
      if (workoutId != null) 'workout_id': workoutId,
      if (setId != null) 'set_id': setId,
      if (loopIndex != null) 'loop_index': loopIndex,
      if (moveId != null) 'move_id': moveId,
      if (exerciseId != null) 'exercise_id': exerciseId,
      if (repCount != null) 'rep_count': repCount,
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
      Value<int>? loopIndex,
      Value<String>? moveId,
      Value<String>? exerciseId,
      Value<int>? repCount,
      Value<int>? elapsedSeconds,
      Value<int>? completedAt,
      Value<int>? rowid}) {
    return WorkoutMovePerformancesCompanion(
      performanceId: performanceId ?? this.performanceId,
      sessionId: sessionId ?? this.sessionId,
      workoutId: workoutId ?? this.workoutId,
      setId: setId ?? this.setId,
      loopIndex: loopIndex ?? this.loopIndex,
      moveId: moveId ?? this.moveId,
      exerciseId: exerciseId ?? this.exerciseId,
      repCount: repCount ?? this.repCount,
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
    if (loopIndex.present) {
      map['loop_index'] = Variable<int>(loopIndex.value);
    }
    if (moveId.present) {
      map['move_id'] = Variable<String>(moveId.value);
    }
    if (exerciseId.present) {
      map['exercise_id'] = Variable<String>(exerciseId.value);
    }
    if (repCount.present) {
      map['rep_count'] = Variable<int>(repCount.value);
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
          ..write('loopIndex: $loopIndex, ')
          ..write('moveId: $moveId, ')
          ..write('exerciseId: $exerciseId, ')
          ..write('repCount: $repCount, ')
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
  late final $WorkoutPlansTableTable workoutPlansTable =
      $WorkoutPlansTableTable(this);
  late final $WorkoutMovePerformancesTable workoutMovePerformances =
      $WorkoutMovePerformancesTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities =>
      [workoutSessions, workoutPlansTable, workoutMovePerformances];
}

typedef $$WorkoutSessionsTableCreateCompanionBuilder = WorkoutSessionsCompanion
    Function({
  required String sessionId,
  required String planId,
  required String workoutId,
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
typedef $$WorkoutPlansTableTableCreateCompanionBuilder
    = WorkoutPlansTableCompanion Function({
  required String planId,
  required String jsonPayload,
  Value<int> rowid,
});
typedef $$WorkoutPlansTableTableUpdateCompanionBuilder
    = WorkoutPlansTableCompanion Function({
  Value<String> planId,
  Value<String> jsonPayload,
  Value<int> rowid,
});

class $$WorkoutPlansTableTableFilterComposer
    extends Composer<_$HistoryDatabase, $WorkoutPlansTableTable> {
  $$WorkoutPlansTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get jsonPayload => $composableBuilder(
      column: $table.jsonPayload, builder: (column) => ColumnFilters(column));
}

class $$WorkoutPlansTableTableOrderingComposer
    extends Composer<_$HistoryDatabase, $WorkoutPlansTableTable> {
  $$WorkoutPlansTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get planId => $composableBuilder(
      column: $table.planId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get jsonPayload => $composableBuilder(
      column: $table.jsonPayload, builder: (column) => ColumnOrderings(column));
}

class $$WorkoutPlansTableTableAnnotationComposer
    extends Composer<_$HistoryDatabase, $WorkoutPlansTableTable> {
  $$WorkoutPlansTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get planId =>
      $composableBuilder(column: $table.planId, builder: (column) => column);

  GeneratedColumn<String> get jsonPayload => $composableBuilder(
      column: $table.jsonPayload, builder: (column) => column);
}

class $$WorkoutPlansTableTableTableManager extends RootTableManager<
    _$HistoryDatabase,
    $WorkoutPlansTableTable,
    WorkoutPlanEntity,
    $$WorkoutPlansTableTableFilterComposer,
    $$WorkoutPlansTableTableOrderingComposer,
    $$WorkoutPlansTableTableAnnotationComposer,
    $$WorkoutPlansTableTableCreateCompanionBuilder,
    $$WorkoutPlansTableTableUpdateCompanionBuilder,
    (
      WorkoutPlanEntity,
      BaseReferences<_$HistoryDatabase, $WorkoutPlansTableTable,
          WorkoutPlanEntity>
    ),
    WorkoutPlanEntity,
    PrefetchHooks Function()> {
  $$WorkoutPlansTableTableTableManager(
      _$HistoryDatabase db, $WorkoutPlansTableTable table)
      : super(TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$WorkoutPlansTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$WorkoutPlansTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$WorkoutPlansTableTableAnnotationComposer(
                  $db: db, $table: table),
          updateCompanionCallback: ({
            Value<String> planId = const Value.absent(),
            Value<String> jsonPayload = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutPlansTableCompanion(
            planId: planId,
            jsonPayload: jsonPayload,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String planId,
            required String jsonPayload,
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutPlansTableCompanion.insert(
            planId: planId,
            jsonPayload: jsonPayload,
            rowid: rowid,
          ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ));
}

typedef $$WorkoutPlansTableTableProcessedTableManager = ProcessedTableManager<
    _$HistoryDatabase,
    $WorkoutPlansTableTable,
    WorkoutPlanEntity,
    $$WorkoutPlansTableTableFilterComposer,
    $$WorkoutPlansTableTableOrderingComposer,
    $$WorkoutPlansTableTableAnnotationComposer,
    $$WorkoutPlansTableTableCreateCompanionBuilder,
    $$WorkoutPlansTableTableUpdateCompanionBuilder,
    (
      WorkoutPlanEntity,
      BaseReferences<_$HistoryDatabase, $WorkoutPlansTableTable,
          WorkoutPlanEntity>
    ),
    WorkoutPlanEntity,
    PrefetchHooks Function()>;
typedef $$WorkoutMovePerformancesTableCreateCompanionBuilder
    = WorkoutMovePerformancesCompanion Function({
  required String performanceId,
  required String sessionId,
  required String workoutId,
  required String setId,
  required int loopIndex,
  required String moveId,
  required String exerciseId,
  required int repCount,
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
  Value<int> loopIndex,
  Value<String> moveId,
  Value<String> exerciseId,
  Value<int> repCount,
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

  ColumnFilters<int> get loopIndex => $composableBuilder(
      column: $table.loopIndex, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get moveId => $composableBuilder(
      column: $table.moveId, builder: (column) => ColumnFilters(column));

  ColumnFilters<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => ColumnFilters(column));

  ColumnFilters<int> get repCount => $composableBuilder(
      column: $table.repCount, builder: (column) => ColumnFilters(column));

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

  ColumnOrderings<int> get loopIndex => $composableBuilder(
      column: $table.loopIndex, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get moveId => $composableBuilder(
      column: $table.moveId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => ColumnOrderings(column));

  ColumnOrderings<int> get repCount => $composableBuilder(
      column: $table.repCount, builder: (column) => ColumnOrderings(column));

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

  GeneratedColumn<int> get loopIndex =>
      $composableBuilder(column: $table.loopIndex, builder: (column) => column);

  GeneratedColumn<String> get moveId =>
      $composableBuilder(column: $table.moveId, builder: (column) => column);

  GeneratedColumn<String> get exerciseId => $composableBuilder(
      column: $table.exerciseId, builder: (column) => column);

  GeneratedColumn<int> get repCount =>
      $composableBuilder(column: $table.repCount, builder: (column) => column);

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
            Value<int> loopIndex = const Value.absent(),
            Value<String> moveId = const Value.absent(),
            Value<String> exerciseId = const Value.absent(),
            Value<int> repCount = const Value.absent(),
            Value<int> elapsedSeconds = const Value.absent(),
            Value<int> completedAt = const Value.absent(),
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutMovePerformancesCompanion(
            performanceId: performanceId,
            sessionId: sessionId,
            workoutId: workoutId,
            setId: setId,
            loopIndex: loopIndex,
            moveId: moveId,
            exerciseId: exerciseId,
            repCount: repCount,
            elapsedSeconds: elapsedSeconds,
            completedAt: completedAt,
            rowid: rowid,
          ),
          createCompanionCallback: ({
            required String performanceId,
            required String sessionId,
            required String workoutId,
            required String setId,
            required int loopIndex,
            required String moveId,
            required String exerciseId,
            required int repCount,
            required int elapsedSeconds,
            required int completedAt,
            Value<int> rowid = const Value.absent(),
          }) =>
              WorkoutMovePerformancesCompanion.insert(
            performanceId: performanceId,
            sessionId: sessionId,
            workoutId: workoutId,
            setId: setId,
            loopIndex: loopIndex,
            moveId: moveId,
            exerciseId: exerciseId,
            repCount: repCount,
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
  $$WorkoutPlansTableTableTableManager get workoutPlansTable =>
      $$WorkoutPlansTableTableTableManager(_db, _db.workoutPlansTable);
  $$WorkoutMovePerformancesTableTableManager get workoutMovePerformances =>
      $$WorkoutMovePerformancesTableTableManager(
          _db, _db.workoutMovePerformances);
}
