import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_parser.dart';
import 'package:workout_app_rewrite/features/workout_plan/data/workout_repository.dart';
import 'package:workout_app_rewrite/features/workout_plan/domain/workout_plan_models.dart';

class ImportPolicyException implements Exception {
  const ImportPolicyException(this.message);

  final String message;

  @override
  String toString() {
    return 'ImportPolicyException($message)';
  }
}

class WorkoutPlanImportService {
  const WorkoutPlanImportService({
    required WorkoutPlanParser parser,
    required WorkoutRepository repository,
    this.maxImportBytes = 5 * 1024 * 1024,
    this.allowHttp = false,
  })  : _parser = parser,
        _repository = repository;

  final WorkoutPlanParser _parser;
  final WorkoutRepository _repository;
  final int maxImportBytes;
  final bool allowHttp;

  Future<WorkoutPlan> importFromJsonString(String payload) async {
    final int bytes = payload.codeUnits.length;
    if (bytes > maxImportBytes) {
      throw ImportPolicyException('Plan exceeds max size of $maxImportBytes bytes.');
    }
    final WorkoutPlan plan = _parser.parseFromString(payload);
    await _repository.savePlan(plan);
    return plan;
  }

  void validateRemoteImportUri(Uri uri) {
    final bool isHttps = uri.scheme.toLowerCase() == 'https';
    final bool isHttp = uri.scheme.toLowerCase() == 'http';
    if (isHttps) {
      return;
    }
    if (allowHttp && isHttp) {
      return;
    }
    throw const ImportPolicyException('Only https:// URLs are allowed by default.');
  }
}
