import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class WorkoutPlanExportResult {
  const WorkoutPlanExportResult({
    required this.fileName,
    required this.path,
  });

  final String fileName;
  final String? path;
}

class WorkoutPlanExportService {
  const WorkoutPlanExportService();

  Future<WorkoutPlanExportResult?> exportPlan(WorkoutPlan plan) async {
    final String fileName = _fileNameFor(plan);
    final Uint8List bytes = Uint8List.fromList(
      utf8.encode(
        const JsonEncoder.withIndent('  ').convert(_exportableJson(plan)),
      ),
    );

    final String? path = await FilePicker.platform.saveFile(
      dialogTitle: 'Export workout plan',
      fileName: fileName,
      type: FileType.custom,
      allowedExtensions: const <String>['json'],
      bytes: bytes,
    );

    if (!kIsWeb && path == null) {
      return null;
    }

    return WorkoutPlanExportResult(fileName: fileName, path: path);
  }

  String _fileNameFor(WorkoutPlan plan) {
    final String rawName =
        plan.name.trim().isEmpty ? plan.planId : plan.name.trim();
    final String slug = rawName
        .replaceAll(RegExp(r'[<>:"/\\|?*]+'), '-')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '')
        .toLowerCase();
    return '${slug.isEmpty ? plan.planId : slug}.plan.json';
  }

  Map<String, dynamic> _exportableJson(WorkoutPlan plan) {
    final List<Workout> workouts = plan.activeWorkouts;
    final Set<String> moveIds = plan.referencedMoveIds(fromWorkouts: workouts);

    return plan
        .copyWith(
          schemaVersion: workoutPlanSchemaVersion,
          workouts: workouts,
          moves: plan.moves
              .where((Move move) => moveIds.contains(move.moveId))
              .toList(growable: false),
        )
        .toJson();
  }
}
