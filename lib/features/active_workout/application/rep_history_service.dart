import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';

final Provider<RepHistoryService> repHistoryServiceProvider =
    Provider<RepHistoryService>((Ref<RepHistoryService> ref) {
  return RepHistoryService(ref.watch(sharedPreferencesProvider));
});

class RepHistoryService {
  RepHistoryService(this._prefs);

  final SharedPreferences _prefs;
  static const String _storageKey = 'rep_history_v1';
  static const String _weightStorageKey = 'weight_history_v1';
  static const String _durationStorageKey = 'duration_history_v1';
  Map<String, int>? _cache;
  Map<String, double>? _weightCache;
  Map<String, int>? _durationCache;

  Future<int?> getLastReps({
    required String workoutId,
    required String setId,
    required int loopIndex,
    required String exerciseId,
  }) async {
    await _ensureLoaded();
    return _cache![_key(
        workoutId: workoutId,
        setId: setId,
        loopIndex: loopIndex,
        exerciseId: exerciseId)];
  }

  Future<void> saveReps({
    required String workoutId,
    required String setId,
    required int loopIndex,
    required String exerciseId,
    required int reps,
  }) async {
    await _ensureLoaded();
    _cache![_key(
        workoutId: workoutId,
        setId: setId,
        loopIndex: loopIndex,
        exerciseId: exerciseId)] = reps;
    await _prefs.setString(_storageKey, jsonEncode(_cache));
  }

  Future<double?> getLastWeight({
    required String workoutId,
    required String setId,
    required int loopIndex,
    required String exerciseId,
    required String weightUnit,
  }) async {
    await _ensureWeightsLoaded();
    return _weightCache![_weightKey(
      workoutId: workoutId,
      setId: setId,
      loopIndex: loopIndex,
      exerciseId: exerciseId,
      weightUnit: weightUnit,
    )];
  }

  Future<void> saveWeight({
    required String workoutId,
    required String setId,
    required int loopIndex,
    required String exerciseId,
    required String weightUnit,
    required double weight,
  }) async {
    await _ensureWeightsLoaded();
    _weightCache![_weightKey(
      workoutId: workoutId,
      setId: setId,
      loopIndex: loopIndex,
      exerciseId: exerciseId,
      weightUnit: weightUnit,
    )] = weight;
    await _prefs.setString(_weightStorageKey, jsonEncode(_weightCache));
  }

  Future<int?> getLastDuration({
    required String workoutId,
    required String setId,
    required int loopIndex,
    required String exerciseId,
  }) async {
    await _ensureDurationsLoaded();
    return _durationCache![_key(
        workoutId: workoutId,
        setId: setId,
        loopIndex: loopIndex,
        exerciseId: exerciseId)];
  }

  Future<void> saveDuration({
    required String workoutId,
    required String setId,
    required int loopIndex,
    required String exerciseId,
    required int seconds,
  }) async {
    await _ensureDurationsLoaded();
    _durationCache![_key(
        workoutId: workoutId,
        setId: setId,
        loopIndex: loopIndex,
        exerciseId: exerciseId)] = seconds;
    await _prefs.setString(_durationStorageKey, jsonEncode(_durationCache));
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
          if (entry.value is int)
            entry.key: entry.value as int
          else if (entry.value is num)
            entry.key: (entry.value as num).toInt(),
      };
    } catch (_) {
      _cache = <String, int>{};
    }
  }

  Future<void> _ensureWeightsLoaded() async {
    if (_weightCache != null) {
      return;
    }

    await _prefs.reload();
    final String? raw = _prefs.getString(_weightStorageKey);
    if (raw == null || raw.isEmpty) {
      _weightCache = <String, double>{};
      return;
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _weightCache = <String, double>{};
        return;
      }

      _weightCache = <String, double>{
        for (final MapEntry<String, dynamic> entry in decoded.entries)
          if (entry.value is num) entry.key: (entry.value as num).toDouble(),
      };
    } catch (_) {
      _weightCache = <String, double>{};
    }
  }

  Future<void> _ensureDurationsLoaded() async {
    if (_durationCache != null) {
      return;
    }

    await _prefs.reload();
    final String? raw = _prefs.getString(_durationStorageKey);
    if (raw == null || raw.isEmpty) {
      _durationCache = <String, int>{};
      return;
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _durationCache = <String, int>{};
        return;
      }

      _durationCache = <String, int>{
        for (final MapEntry<String, dynamic> entry in decoded.entries)
          if (entry.value is int)
            entry.key: entry.value as int
          else if (entry.value is num)
            entry.key: (entry.value as num).toInt(),
      };
    } catch (_) {
      _durationCache = <String, int>{};
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

  String _weightKey({
    required String workoutId,
    required String setId,
    required int loopIndex,
    required String exerciseId,
    required String weightUnit,
  }) {
    return '$workoutId|$setId|$loopIndex|$exerciseId|$weightUnit';
  }
}
