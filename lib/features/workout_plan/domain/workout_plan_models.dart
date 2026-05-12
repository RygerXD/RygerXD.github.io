enum MoveType {
  reps,
  duration,
}

enum WeightUnit {
  kg,
  lb,
}

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
  final double? targetWeight;
  final WeightUnit? targetWeightUnit;
  final int? metronomeSpeed;

  factory Move.fromJson(Map<String, dynamic> json) {
    return Move(
      moveId: json['moveId'] as String,
      exerciseId: json['exerciseId'] as String,
      type: MoveType.values.byName(json['type'] as String),
      repCount: json['repCount'] as int?,
      durationSeconds: json['durationSeconds'] as int?,
      prepTimeSeconds: (json['prepTimeSeconds'] as int?) ?? 0,
      finishTimeSeconds: (json['finishTimeSeconds'] as int?) ?? 0,
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
  });

  final String workoutId;
  final String title;
  final List<WorkoutSet> sets;

  factory Workout.fromJson(Map<String, dynamic> json) {
    return Workout(
      workoutId: json['workoutId'] as String,
      title: json['title'] as String,
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
