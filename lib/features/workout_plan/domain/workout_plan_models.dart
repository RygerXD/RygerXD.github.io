import 'dart:convert';
import 'dart:typed_data';

enum MoveType {
  reps,
  duration,
  stopwatch,
}

enum WeightUnit {
  kg,
  lb,
}

enum MoveSide {
  left,
  right,
}

const int workoutPlanSchemaVersion = 1;

const Object _copyWithUnset = Object();
const int maxCustomWorkoutSoundBytes = 512 * 1024;

class CustomWorkoutSound {
  const CustomWorkoutSound({
    required this.fileName,
    required this.mimeType,
    required this.base64Data,
  });

  final String fileName;
  final String mimeType;
  final String base64Data;

  Uint8List get bytes => base64Decode(base64Data);

  factory CustomWorkoutSound.fromBytes({
    required String fileName,
    required String mimeType,
    required Uint8List bytes,
  }) {
    if (fileName.trim().isEmpty ||
        !const <String>{'audio/mpeg', 'audio/wav'}.contains(mimeType) ||
        bytes.isEmpty ||
        bytes.length > maxCustomWorkoutSoundBytes) {
      throw ArgumentError.value(bytes.length, 'bytes', 'Invalid sound size.');
    }
    return CustomWorkoutSound(
      fileName: fileName,
      mimeType: mimeType,
      base64Data: base64Encode(bytes),
    );
  }

  factory CustomWorkoutSound.fromJson(Map<String, dynamic> json) {
    final CustomWorkoutSound sound = CustomWorkoutSound(
      fileName: json['fileName'] as String,
      mimeType: json['mimeType'] as String,
      base64Data: json['base64Data'] as String,
    );
    if (sound.fileName.trim().isEmpty ||
        !const <String>{'audio/mpeg', 'audio/wav'}.contains(sound.mimeType) ||
        sound.bytes.isEmpty ||
        sound.bytes.length > maxCustomWorkoutSoundBytes) {
      throw ArgumentError('Invalid custom workout sound.');
    }
    return sound;
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
        'fileName': fileName,
        'mimeType': mimeType,
        'base64Data': base64Data,
      };
}

void _putIfNotNull(Map<String, dynamic> json, String key, Object? value) {
  if (value != null) {
    json[key] = value;
  }
}

class Move {
  const Move({
    required this.moveId,
    required this.name,
    this.imageUrl,
    this.description,
  });

  final String moveId;
  final String name;
  final String? imageUrl;
  final String? description;

  Move copyWith({
    String? moveId,
    String? name,
    Object? imageUrl = _copyWithUnset,
    Object? description = _copyWithUnset,
  }) {
    return Move(
      moveId: moveId ?? this.moveId,
      name: name ?? this.name,
      imageUrl: identical(imageUrl, _copyWithUnset)
          ? this.imageUrl
          : imageUrl as String?,
      description: identical(description, _copyWithUnset)
          ? this.description
          : description as String?,
    );
  }

  factory Move.fromJson(Map<String, dynamic> json) {
    return Move(
      moveId: json['moveId'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'moveId': moveId,
      'name': name,
    };
    _putIfNotNull(json, 'imageUrl', imageUrl);
    _putIfNotNull(json, 'description', description);
    return json;
  }
}

class WorkoutMove {
  const WorkoutMove({
    required this.workoutMoveId,
    required this.moveId,
    required this.type,
    this.repCount,
    this.durationSeconds,
    this.prepTimeSeconds = 0,
    this.finishTimeSeconds = 0,
    this.setCount = 1,
    this.repeatEachSide = false,
    this.side,
    this.targetWeight,
    this.targetWeightUnit,
    this.metronomeSpeed,
  });

  final String workoutMoveId;
  final String moveId;
  final MoveType type;
  final int? repCount;
  final int? durationSeconds;
  final int prepTimeSeconds;
  final int finishTimeSeconds;
  final int setCount;
  final bool repeatEachSide;
  final MoveSide? side;
  final double? targetWeight;
  final WeightUnit? targetWeightUnit;
  final int? metronomeSpeed;

  WorkoutMove copyWith({
    String? workoutMoveId,
    String? moveId,
    MoveType? type,
    Object? repCount = _copyWithUnset,
    Object? durationSeconds = _copyWithUnset,
    int? prepTimeSeconds,
    int? finishTimeSeconds,
    int? setCount,
    bool? repeatEachSide,
    Object? side = _copyWithUnset,
    Object? targetWeight = _copyWithUnset,
    Object? targetWeightUnit = _copyWithUnset,
    Object? metronomeSpeed = _copyWithUnset,
  }) {
    return WorkoutMove(
      workoutMoveId: workoutMoveId ?? this.workoutMoveId,
      moveId: moveId ?? this.moveId,
      type: type ?? this.type,
      repCount: identical(repCount, _copyWithUnset)
          ? this.repCount
          : repCount as int?,
      durationSeconds: identical(durationSeconds, _copyWithUnset)
          ? this.durationSeconds
          : durationSeconds as int?,
      prepTimeSeconds: prepTimeSeconds ?? this.prepTimeSeconds,
      finishTimeSeconds: finishTimeSeconds ?? this.finishTimeSeconds,
      setCount: setCount ?? this.setCount,
      repeatEachSide: repeatEachSide ?? this.repeatEachSide,
      side: identical(side, _copyWithUnset) ? this.side : side as MoveSide?,
      targetWeight: identical(targetWeight, _copyWithUnset)
          ? this.targetWeight
          : targetWeight as double?,
      targetWeightUnit: identical(targetWeightUnit, _copyWithUnset)
          ? this.targetWeightUnit
          : targetWeightUnit as WeightUnit?,
      metronomeSpeed: identical(metronomeSpeed, _copyWithUnset)
          ? this.metronomeSpeed
          : metronomeSpeed as int?,
    );
  }

  factory WorkoutMove.fromJson(Map<String, dynamic> json) {
    return WorkoutMove(
      workoutMoveId: json['workoutMoveId'] as String,
      moveId: json['moveId'] as String,
      type: MoveType.values.byName(json['type'] as String),
      repCount: json['repCount'] as int?,
      durationSeconds: json['durationSeconds'] as int?,
      prepTimeSeconds: (json['prepTimeSeconds'] as int?) ?? 0,
      finishTimeSeconds: (json['finishTimeSeconds'] as int?) ?? 0,
      setCount: (json['setCount'] as int?) ?? 1,
      repeatEachSide: (json['repeatEachSide'] as bool?) ?? false,
      targetWeight: (json['targetWeight'] as num?)?.toDouble(),
      targetWeightUnit: json['targetWeightUnit'] == null
          ? null
          : WeightUnit.values.byName(json['targetWeightUnit'] as String),
      metronomeSpeed: json['metronomeSpeed'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'workoutMoveId': workoutMoveId,
      'moveId': moveId,
      'type': type.name,
    };
    switch (type) {
      case MoveType.reps:
        _putIfNotNull(json, 'repCount', repCount);
      case MoveType.duration:
        _putIfNotNull(json, 'durationSeconds', durationSeconds);
        _putIfNotNull(json, 'metronomeSpeed', metronomeSpeed);
      case MoveType.stopwatch:
        break;
    }
    if (prepTimeSeconds != 0) {
      json['prepTimeSeconds'] = prepTimeSeconds;
    }
    if (finishTimeSeconds != 0) {
      json['finishTimeSeconds'] = finishTimeSeconds;
    }
    if (setCount != 1) {
      json['setCount'] = setCount;
    }
    if (repeatEachSide) {
      json['repeatEachSide'] = true;
    }
    _putIfNotNull(json, 'targetWeight', targetWeight);
    _putIfNotNull(json, 'targetWeightUnit', targetWeightUnit?.name);
    return json;
  }
}

class WorkoutSet {
  const WorkoutSet({
    required this.setId,
    required this.moves,
    this.lapCount = 1,
    this.restBetweenLapsSeconds = 0,
    this.name,
  });

  final String setId;
  final String? name;
  final int lapCount;
  final int restBetweenLapsSeconds;
  final List<WorkoutMove> moves;

  WorkoutSet copyWith({
    String? setId,
    Object? name = _copyWithUnset,
    int? lapCount,
    int? restBetweenLapsSeconds,
    List<WorkoutMove>? moves,
  }) {
    return WorkoutSet(
      setId: setId ?? this.setId,
      name: identical(name, _copyWithUnset) ? this.name : name as String?,
      lapCount: lapCount ?? this.lapCount,
      restBetweenLapsSeconds:
          restBetweenLapsSeconds ?? this.restBetweenLapsSeconds,
      moves: moves ?? this.moves,
    );
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      setId: json['setId'] as String,
      name: json['name'] as String?,
      lapCount: (json['lapCount'] as int?) ?? 1,
      restBetweenLapsSeconds: (json['restBetweenLapsSeconds'] as int?) ?? 0,
      moves: (json['moves'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(WorkoutMove.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'setId': setId,
    };
    _putIfNotNull(json, 'name', name);
    if (lapCount != 1) {
      json['lapCount'] = lapCount;
    }
    if (restBetweenLapsSeconds != 0) {
      json['restBetweenLapsSeconds'] = restBetweenLapsSeconds;
    }
    json['moves'] =
        moves.map((WorkoutMove move) => move.toJson()).toList(growable: false);
    return json;
  }
}

class Workout {
  const Workout({
    required this.workoutId,
    required this.title,
    required this.sets,
    this.imageUrl,
    this.workoutCompleteSound,
    this.workoutEndedEarlySound,
    this.archivedAt,
  });

  final String workoutId;
  final String title;
  final String? imageUrl;
  final CustomWorkoutSound? workoutCompleteSound;
  final CustomWorkoutSound? workoutEndedEarlySound;
  final List<WorkoutSet> sets;
  final int? archivedAt;

  bool get isArchived => archivedAt != null;

  Workout copyWith({
    String? workoutId,
    String? title,
    Object? imageUrl = _copyWithUnset,
    Object? workoutCompleteSound = _copyWithUnset,
    Object? workoutEndedEarlySound = _copyWithUnset,
    List<WorkoutSet>? sets,
    Object? archivedAt = _copyWithUnset,
  }) {
    return Workout(
      workoutId: workoutId ?? this.workoutId,
      title: title ?? this.title,
      imageUrl: identical(imageUrl, _copyWithUnset)
          ? this.imageUrl
          : imageUrl as String?,
      workoutCompleteSound: identical(workoutCompleteSound, _copyWithUnset)
          ? this.workoutCompleteSound
          : workoutCompleteSound as CustomWorkoutSound?,
      workoutEndedEarlySound: identical(workoutEndedEarlySound, _copyWithUnset)
          ? this.workoutEndedEarlySound
          : workoutEndedEarlySound as CustomWorkoutSound?,
      sets: sets ?? this.sets,
      archivedAt: identical(archivedAt, _copyWithUnset)
          ? this.archivedAt
          : archivedAt as int?,
    );
  }

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      workoutId: json['workoutId'] as String,
      title: json['title'] as String,
      imageUrl: json['imageUrl'] as String?,
      workoutCompleteSound: json['workoutCompleteSound'] == null
          ? null
          : CustomWorkoutSound.fromJson(
              json['workoutCompleteSound'] as Map<String, dynamic>,
            ),
      workoutEndedEarlySound: json['workoutEndedEarlySound'] == null
          ? null
          : CustomWorkoutSound.fromJson(
              json['workoutEndedEarlySound'] as Map<String, dynamic>,
            ),
      archivedAt: (json['archivedAt'] as num?)?.toInt(),
      sets: (json['sets'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(WorkoutSet.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'workoutId': workoutId,
      'title': title,
    };
    _putIfNotNull(json, 'imageUrl', imageUrl);
    _putIfNotNull(
      json,
      'workoutCompleteSound',
      workoutCompleteSound?.toJson(),
    );
    _putIfNotNull(
      json,
      'workoutEndedEarlySound',
      workoutEndedEarlySound?.toJson(),
    );
    _putIfNotNull(json, 'archivedAt', archivedAt);
    json['sets'] =
        sets.map((WorkoutSet set) => set.toJson()).toList(growable: false);
    return json;
  }
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.schemaVersion,
    required this.planId,
    required this.name,
    required this.workouts,
    required this.moves,
    this.description,
    this.author,
    this.imageUrl,
    this.workoutCompleteSound,
    this.workoutEndedEarlySound,
    this.tags = const <String>[],
  });

  final int schemaVersion;
  final String planId;
  final String name;
  final String? description;
  final String? author;
  final String? imageUrl;
  final CustomWorkoutSound? workoutCompleteSound;
  final CustomWorkoutSound? workoutEndedEarlySound;
  final List<String> tags;
  final List<Workout> workouts;
  final List<Move> moves;

  WorkoutPlan copyWith({
    int? schemaVersion,
    String? planId,
    String? name,
    Object? description = _copyWithUnset,
    Object? author = _copyWithUnset,
    Object? imageUrl = _copyWithUnset,
    Object? workoutCompleteSound = _copyWithUnset,
    Object? workoutEndedEarlySound = _copyWithUnset,
    List<String>? tags,
    List<Workout>? workouts,
    List<Move>? moves,
  }) {
    return WorkoutPlan(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      planId: planId ?? this.planId,
      name: name ?? this.name,
      description: identical(description, _copyWithUnset)
          ? this.description
          : description as String?,
      author:
          identical(author, _copyWithUnset) ? this.author : author as String?,
      imageUrl: identical(imageUrl, _copyWithUnset)
          ? this.imageUrl
          : imageUrl as String?,
      workoutCompleteSound: identical(workoutCompleteSound, _copyWithUnset)
          ? this.workoutCompleteSound
          : workoutCompleteSound as CustomWorkoutSound?,
      workoutEndedEarlySound: identical(workoutEndedEarlySound, _copyWithUnset)
          ? this.workoutEndedEarlySound
          : workoutEndedEarlySound as CustomWorkoutSound?,
      tags: tags ?? this.tags,
      workouts: workouts ?? this.workouts,
      moves: moves ?? this.moves,
    );
  }

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) {
    return WorkoutPlan(
      schemaVersion: json['schemaVersion'] as int,
      planId: json['planId'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      author: json['author'] as String?,
      imageUrl: json['imageUrl'] as String?,
      workoutCompleteSound: json['workoutCompleteSound'] == null
          ? null
          : CustomWorkoutSound.fromJson(
              json['workoutCompleteSound'] as Map<String, dynamic>,
            ),
      workoutEndedEarlySound: json['workoutEndedEarlySound'] == null
          ? null
          : CustomWorkoutSound.fromJson(
              json['workoutEndedEarlySound'] as Map<String, dynamic>,
            ),
      tags: ((json['tags'] as List<dynamic>?) ?? <dynamic>[])
          .cast<String>()
          .toList(growable: false),
      workouts: (json['workouts'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Workout.fromJson)
          .toList(growable: false),
      moves: (json['moves'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Move.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> json = <String, dynamic>{
      'schemaVersion': schemaVersion,
      'planId': planId,
      'name': name,
    };
    _putIfNotNull(json, 'description', description);
    _putIfNotNull(json, 'author', author);
    _putIfNotNull(json, 'imageUrl', imageUrl);
    _putIfNotNull(
      json,
      'workoutCompleteSound',
      workoutCompleteSound?.toJson(),
    );
    _putIfNotNull(
      json,
      'workoutEndedEarlySound',
      workoutEndedEarlySound?.toJson(),
    );
    if (tags.isNotEmpty) {
      json['tags'] = tags;
    }
    json['workouts'] = workouts
        .map((Workout workout) => workout.toJson())
        .toList(growable: false);
    json['moves'] =
        moves.map((Move move) => move.toJson()).toList(growable: false);
    return json;
  }
}
