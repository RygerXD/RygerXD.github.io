import 'dart:convert';

import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class HistoryWorkoutSnapshot {
  const HistoryWorkoutSnapshot({
    required this.planId,
    required this.planName,
    required this.workout,
    required this.moves,
  });

  final String planId;
  final String planName;
  final Workout workout;
  final List<Move> moves;

  WorkoutPlan toWorkoutPlan() {
    return WorkoutPlan(
      schemaVersion: 4,
      planId: planId,
      name: planName,
      workouts: <Workout>[workout],
      moves: moves,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'planId': planId,
      'planName': planName,
      'workout': workout.toJson(),
      'moves': moves.map((Move move) => move.toJson()).toList(growable: false),
    };
  }

  factory HistoryWorkoutSnapshot.fromJson(Map<String, dynamic> json) {
    return HistoryWorkoutSnapshot(
      planId: json['planId'] as String,
      planName: json['planName'] as String,
      workout: Workout.fromJson(json['workout'] as Map<String, dynamic>),
      moves: (json['moves'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map(Move.fromJson)
          .toList(growable: false),
    );
  }
}

String? encodeHistoryWorkoutSnapshot(WorkoutPlan? plan, String workoutId) {
  if (plan == null) {
    return null;
  }
  final Workout? workout = plan.workouts
      .where((Workout workout) => workout.workoutId == workoutId)
      .firstOrNull;
  if (workout == null) {
    return null;
  }
  return jsonEncode(
    HistoryWorkoutSnapshot(
      planId: plan.planId,
      planName: plan.name,
      workout: workout,
      moves: plan.moves,
    ).toJson(),
  );
}

HistoryWorkoutSnapshot? decodeHistoryWorkoutSnapshot(String? jsonPayload) {
  if (jsonPayload == null || jsonPayload.trim().isEmpty) {
    return null;
  }
  try {
    final Object? decoded = jsonDecode(jsonPayload);
    if (decoded is! Map<String, dynamic>) {
      return null;
    }
    return HistoryWorkoutSnapshot.fromJson(decoded);
  } catch (_) {
    return null;
  }
}
