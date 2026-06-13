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

const Object _copyWithUnset = Object();

class Exercise {
  const Exercise({
    required this.exerciseId,
    required this.name,
    this.imageUrl,
    this.description,
  });

  final String exerciseId;
  final String name;
  final String? imageUrl;
  final String? description;

  Exercise copyWith({
    String? exerciseId,
    String? name,
    Object? imageUrl = _copyWithUnset,
    Object? description = _copyWithUnset,
  }) {
    return Exercise(
      exerciseId: exerciseId ?? this.exerciseId,
      name: name ?? this.name,
      imageUrl: identical(imageUrl, _copyWithUnset)
          ? this.imageUrl
          : imageUrl as String?,
      description: identical(description, _copyWithUnset)
          ? this.description
          : description as String?,
    );
  }

  factory Exercise.fromJson(Map<String, dynamic> json) {
    return Exercise(
      exerciseId: json['exerciseId'] as String,
      name: json['name'] as String,
      imageUrl: json['imageUrl'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'exerciseId': exerciseId,
      'name': name,
      'imageUrl': imageUrl,
      'description': description,
    };
  }
}

class Move {
  const Move({
    required this.moveId,
    required this.exerciseId,
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

  final String moveId;
  final String exerciseId;
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

  Move copyWith({
    String? moveId,
    String? exerciseId,
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
    return Move(
      moveId: moveId ?? this.moveId,
      exerciseId: exerciseId ?? this.exerciseId,
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

  factory Move.fromJson(Map<String, dynamic> json) {
    return Move(
      moveId: json['moveId'] as String,
      exerciseId: json['exerciseId'] as String,
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
    return <String, dynamic>{
      'moveId': moveId,
      'exerciseId': exerciseId,
      'type': type.name,
      'repCount': repCount,
      'durationSeconds': durationSeconds,
      'prepTimeSeconds': prepTimeSeconds,
      'finishTimeSeconds': finishTimeSeconds,
      'setCount': setCount,
      'repeatEachSide': repeatEachSide,
      'targetWeight': targetWeight,
      'targetWeightUnit': targetWeightUnit?.name,
      'metronomeSpeed': metronomeSpeed,
    };
  }
}

class WorkoutSet {
  const WorkoutSet({
    required this.setId,
    required this.loopCount,
    required this.restBetweenLoopsSeconds,
    required this.moves,
    this.name,
  });

  final String setId;
  final String? name;
  final int loopCount;
  final int restBetweenLoopsSeconds;
  final List<Move> moves;

  WorkoutSet copyWith({
    String? setId,
    Object? name = _copyWithUnset,
    int? loopCount,
    int? restBetweenLoopsSeconds,
    List<Move>? moves,
  }) {
    return WorkoutSet(
      setId: setId ?? this.setId,
      name: identical(name, _copyWithUnset) ? this.name : name as String?,
      loopCount: loopCount ?? this.loopCount,
      restBetweenLoopsSeconds:
          restBetweenLoopsSeconds ?? this.restBetweenLoopsSeconds,
      moves: moves ?? this.moves,
    );
  }

  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      setId: json['setId'] as String,
      name: json['name'] as String?,
      loopCount: json['loopCount'] as int,
      restBetweenLoopsSeconds: json['restBetweenLoopsSeconds'] as int,
      moves: (json['moves'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Move.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'setId': setId,
      'name': name,
      'loopCount': loopCount,
      'restBetweenLoopsSeconds': restBetweenLoopsSeconds,
      'moves': moves.map((Move move) => move.toJson()).toList(growable: false),
    };
  }
}

class Workout {
  const Workout({
    required this.workoutId,
    required this.title,
    required this.sets,
    this.imageUrl,
    this.archivedAt,
  });

  final String workoutId;
  final String title;
  final String? imageUrl;
  final List<WorkoutSet> sets;
  final int? archivedAt;

  bool get isArchived => archivedAt != null;

  Workout copyWith({
    String? workoutId,
    String? title,
    Object? imageUrl = _copyWithUnset,
    List<WorkoutSet>? sets,
    Object? archivedAt = _copyWithUnset,
  }) {
    return Workout(
      workoutId: workoutId ?? this.workoutId,
      title: title ?? this.title,
      imageUrl: identical(imageUrl, _copyWithUnset)
          ? this.imageUrl
          : imageUrl as String?,
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
      archivedAt: (json['archivedAt'] as num?)?.toInt(),
      sets: (json['sets'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(WorkoutSet.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'workoutId': workoutId,
      'title': title,
      'imageUrl': imageUrl,
      'archivedAt': archivedAt,
      'sets':
          sets.map((WorkoutSet set) => set.toJson()).toList(growable: false),
    };
  }
}

class WorkoutPlan {
  const WorkoutPlan({
    required this.schemaVersion,
    required this.planId,
    required this.name,
    required this.workouts,
    required this.exercises,
    this.description,
    this.author,
    this.imageUrl,
    this.tags = const <String>[],
  });

  final int schemaVersion;
  final String planId;
  final String name;
  final String? description;
  final String? author;
  final String? imageUrl;
  final List<String> tags;
  final List<Workout> workouts;
  final List<Exercise> exercises;

  WorkoutPlan copyWith({
    int? schemaVersion,
    String? planId,
    String? name,
    Object? description = _copyWithUnset,
    Object? author = _copyWithUnset,
    Object? imageUrl = _copyWithUnset,
    List<String>? tags,
    List<Workout>? workouts,
    List<Exercise>? exercises,
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
      tags: tags ?? this.tags,
      workouts: workouts ?? this.workouts,
      exercises: exercises ?? this.exercises,
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
      tags: ((json['tags'] as List<dynamic>?) ?? <dynamic>[])
          .cast<String>()
          .toList(growable: false),
      workouts: (json['workouts'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Workout.fromJson)
          .toList(growable: false),
      exercises: (json['exercises'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Exercise.fromJson)
          .toList(growable: false),
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'schemaVersion': schemaVersion,
      'planId': planId,
      'name': name,
      'description': description,
      'author': author,
      'imageUrl': imageUrl,
      'tags': tags,
      'workouts': workouts
          .map((Workout workout) => workout.toJson())
          .toList(growable: false),
      'exercises': exercises
          .map((Exercise exercise) => exercise.toJson())
          .toList(growable: false),
    };
  }
}
