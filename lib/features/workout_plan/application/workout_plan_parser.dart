import 'dart:convert';

import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class PlanValidationIssue {
  const PlanValidationIssue({
    required this.path,
    required this.message,
  });

  final String path;
  final String message;
}

class WorkoutPlanParseException implements Exception {
  const WorkoutPlanParseException({
    required this.message,
    required this.issues,
  });

  final String message;
  final List<PlanValidationIssue> issues;

  @override
  String toString() {
    return 'WorkoutPlanParseException(message: $message, issues: $issues)';
  }
}

class WorkoutPlanParser {
  const WorkoutPlanParser({
    this.supportedSchemaVersions = const <int>{1},
  });

  final Set<int> supportedSchemaVersions;

  WorkoutPlan parseFromString(String jsonString) {
    final Object? decoded;
    try {
      decoded = jsonDecode(jsonString);
    } on FormatException catch (error) {
      throw WorkoutPlanParseException(
        message: 'Invalid JSON format.',
        issues: <PlanValidationIssue>[
          PlanValidationIssue(path: r'$', message: error.message),
        ],
      );
    }
    if (decoded is! Map<String, dynamic>) {
      throw const WorkoutPlanParseException(
        message: 'Root JSON object is invalid.',
        issues: <PlanValidationIssue>[
          PlanValidationIssue(path: r'$', message: 'Expected object.'),
        ],
      );
    }
    return parseFromJson(decoded);
  }

  WorkoutPlan parseFromJson(Map<String, dynamic> json) {
    final List<PlanValidationIssue> issues = <PlanValidationIssue>[];
    final int? schemaVersion = json['schemaVersion'] as int?;
    if (schemaVersion == null) {
      issues.add(const PlanValidationIssue(
        path: r'$.schemaVersion',
        message: 'schemaVersion is required.',
      ));
    } else if (!supportedSchemaVersions.contains(schemaVersion)) {
      issues.add(PlanValidationIssue(
        path: r'$.schemaVersion',
        message: 'Unsupported schemaVersion: $schemaVersion',
      ));
    }

    _validateRequiredString(json, 'planId', issues);
    _validateRequiredString(json, 'name', issues);
    _validateList(json, 'workouts', issues);
    _validateList(json, 'exercises', issues);

    if (issues.isNotEmpty) {
      throw WorkoutPlanParseException(
        message: 'Plan JSON validation failed.',
        issues: issues,
      );
    }

    final WorkoutPlan plan;
    try {
      plan = WorkoutPlan.fromJson(json);
    } on ArgumentError catch (error) {
      throw WorkoutPlanParseException(
        message: 'Plan JSON has invalid data types.',
        issues: <PlanValidationIssue>[
          PlanValidationIssue(path: r'$', message: error.message.toString()),
        ],
      );
    } on TypeError {
      throw const WorkoutPlanParseException(
        message: 'Plan JSON has invalid data types.',
        issues: <PlanValidationIssue>[
          PlanValidationIssue(
              path: r'$', message: 'Unexpected JSON type mismatch.'),
        ],
      );
    }
    _validateDomain(plan);
    return plan;
  }

  void _validateRequiredString(
    Map<String, dynamic> json,
    String key,
    List<PlanValidationIssue> issues,
  ) {
    final Object? value = json[key];
    if (value is! String || value.trim().isEmpty) {
      issues.add(PlanValidationIssue(
        path: '\$.$key',
        message: '$key must be a non-empty string.',
      ));
    }
  }

  void _validateList(
    Map<String, dynamic> json,
    String key,
    List<PlanValidationIssue> issues,
  ) {
    final Object? value = json[key];
    if (value is! List<dynamic>) {
      issues.add(PlanValidationIssue(
        path: '\$.$key',
        message: '$key must be a list.',
      ));
    }
  }

  void _validateDomain(WorkoutPlan plan) {
    final List<PlanValidationIssue> issues = <PlanValidationIssue>[];
    final Set<String> exerciseIds =
        plan.exercises.map((Exercise e) => e.exerciseId).toSet();

    if (plan.workouts.isEmpty) {
      issues.add(const PlanValidationIssue(
        path: r'$.workouts',
        message: 'At least one workout is required.',
      ));
    }
    if (plan.exercises.isEmpty) {
      issues.add(const PlanValidationIssue(
        path: r'$.exercises',
        message: 'At least one exercise is required.',
      ));
    }

    for (int workoutIndex = 0;
        workoutIndex < plan.workouts.length;
        workoutIndex++) {
      final Workout workout = plan.workouts[workoutIndex];
      if (workout.sets.isEmpty) {
        issues.add(PlanValidationIssue(
          path: '\$.workouts[$workoutIndex].sets',
          message: 'Workout must contain at least one set.',
        ));
      }
      for (int setIndex = 0; setIndex < workout.sets.length; setIndex++) {
        final WorkoutSet set = workout.sets[setIndex];
        if (set.name != null && set.name!.trim().isEmpty) {
          issues.add(PlanValidationIssue(
            path: '\$.workouts[$workoutIndex].sets[$setIndex].name',
            message: 'set name must be non-empty when provided.',
          ));
        }
        if (set.loopCount < 1) {
          issues.add(PlanValidationIssue(
            path: '\$.workouts[$workoutIndex].sets[$setIndex].loopCount',
            message: 'loopCount must be >= 1.',
          ));
        }
        if (set.moves.isEmpty) {
          issues.add(PlanValidationIssue(
            path: '\$.workouts[$workoutIndex].sets[$setIndex].moves',
            message: 'Set must contain at least one move.',
          ));
        }
        for (int moveIndex = 0; moveIndex < set.moves.length; moveIndex++) {
          final Move move = set.moves[moveIndex];
          if (!exerciseIds.contains(move.exerciseId)) {
            issues.add(PlanValidationIssue(
              path:
                  '\$.workouts[$workoutIndex].sets[$setIndex].moves[$moveIndex].exerciseId',
              message: 'exerciseId does not exist in plan.exercises.',
            ));
          }
          if (move.prepTimeSeconds < 0) {
            issues.add(PlanValidationIssue(
              path:
                  '\$.workouts[$workoutIndex].sets[$setIndex].moves[$moveIndex].prepTimeSeconds',
              message: 'prepTimeSeconds must be >= 0.',
            ));
          }
          if (move.finishTimeSeconds < 0) {
            issues.add(PlanValidationIssue(
              path:
                  '\$.workouts[$workoutIndex].sets[$setIndex].moves[$moveIndex].finishTimeSeconds',
              message: 'finishTimeSeconds must be >= 0.',
            ));
          }
          if (move.setCount < 1) {
            issues.add(PlanValidationIssue(
              path:
                  '\$.workouts[$workoutIndex].sets[$setIndex].moves[$moveIndex].setCount',
              message: 'setCount must be >= 1.',
            ));
          }
          if (move.type == MoveType.reps &&
              (move.repCount == null || move.repCount! < 1)) {
            issues.add(PlanValidationIssue(
              path:
                  '\$.workouts[$workoutIndex].sets[$setIndex].moves[$moveIndex].repCount',
              message: 'rep-based move requires repCount >= 1.',
            ));
          }
          if (move.type == MoveType.duration &&
              (move.durationSeconds == null || move.durationSeconds! < 1)) {
            issues.add(PlanValidationIssue(
              path:
                  '\$.workouts[$workoutIndex].sets[$setIndex].moves[$moveIndex].durationSeconds',
              message: 'time-based move requires durationSeconds >= 1.',
            ));
          }
          if (move.repeatEachSide && move.type != MoveType.duration) {
            issues.add(PlanValidationIssue(
              path:
                  '\$.workouts[$workoutIndex].sets[$setIndex].moves[$moveIndex].repeatEachSide',
              message: 'repeatEachSide is only supported for time-based moves.',
            ));
          }
          if (move.metronomeSpeed != null) {
            if (move.type != MoveType.duration) {
              issues.add(PlanValidationIssue(
                path:
                    '\$.workouts[$workoutIndex].sets[$setIndex].moves[$moveIndex].metronomeSpeed',
                message:
                    'metronomeSpeed is only supported for time-based moves.',
              ));
            } else if (move.metronomeSpeed! < 20 ||
                move.metronomeSpeed! > 300) {
              issues.add(PlanValidationIssue(
                path:
                    '\$.workouts[$workoutIndex].sets[$setIndex].moves[$moveIndex].metronomeSpeed',
                message: 'metronomeSpeed must be between 20 and 300 BPM.',
              ));
            }
          }
          if (move.type == MoveType.stopwatch && move.durationSeconds != null) {
            issues.add(PlanValidationIssue(
              path:
                  '\$.workouts[$workoutIndex].sets[$setIndex].moves[$moveIndex].durationSeconds',
              message:
                  'stopwatch moves count up and should not set durationSeconds.',
            ));
          }
        }
      }
    }

    if (issues.isNotEmpty) {
      throw WorkoutPlanParseException(
        message: 'Domain validation failed.',
        issues: issues,
      );
    }
  }
}
