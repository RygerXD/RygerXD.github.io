import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';

final Provider<RepHistoryService> repHistoryServiceProvider = Provider<RepHistoryService>((Ref<RepHistoryService> ref) {
  return RepHistoryService(ref.watch(sharedPreferencesProvider));
});

class RepHistoryService {
  RepHistoryService(this._prefs);

  final SharedPreferences _prefs;
  static const String _storageKey = 'rep_history_v1';
  Map<String, int>? _cache;

  Future<int?> getLastReps({
    required String workoutId,
    required String setId,
    required int loopIndex,
    required String exerciseId,
  }) async {
    await _ensureLoaded();
    return _cache![_key(workoutId: workoutId, setId: setId, loopIndex: loopIndex, exerciseId: exerciseId)];
  }

  Future<void> saveReps({
    required String workoutId,
    required String setId,
    required int loopIndex,
    required String exerciseId,
    required int reps,
  }) async {
    await _ensureLoaded();
    _cache![_key(workoutId: workoutId, setId: setId, loopIndex: loopIndex, exerciseId: exerciseId)] = reps;
    await _prefs.setString(_storageKey, jsonEncode(_cache));
  }

  Future<void> _ensureLoaded() async {
    if (_cache != null) {
      return;
    }

    await _prefs.reload();
    final String? raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = <String, int>{};
      return;
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _cache = <String, int>{};
        return;
      }

      _cache = <String, int>{
        for (final MapEntry<String, dynamic> entry in decoded.entries)
          if (entry.value is int) entry.key: entry.value as int else if (entry.value is num) entry.key: (entry.value as num).toInt(),
      };
    } catch (_) {
      _cache = <String, int>{};
    }
  }

  String _key({
    required String workoutId,
    required String setId,
    required int loopIndex,
    required String exerciseId,
  }) {
    return '$workoutId|$setId|$loopIndex|$exerciseId';
  }
}
