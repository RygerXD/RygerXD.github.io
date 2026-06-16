import 'package:workout_app_rewrite/features/history/data/history_db.dart';

class AnalysisSessionItem {
  const AnalysisSessionItem({
    required this.session,
    required this.planName,
    required this.workoutName,
  });

  final WorkoutSessionEntity session;
  final String planName;
  final String workoutName;

  DateTime get startedAt =>
      DateTime.fromMillisecondsSinceEpoch(session.startedAt);

  DateTime? get endedAt {
    final int? endedAtMs = session.endedAt;
    if (endedAtMs == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(endedAtMs);
  }

  bool get isCompleted => session.status == 'completed';

  bool get isAbandoned => session.status == 'abandoned';
}
