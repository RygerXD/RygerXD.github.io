import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workout_app_rewrite/features/workout_plan/application/workout_plan_providers.dart';

final Provider<RepHistoryService> repHistoryServiceProvider =
    Provider<RepHistoryService>((Ref<RepHistoryService> ref) {
  return RepHistoryService(ref.watch(sharedPreferencesProvider));
});

class RepHistoryService {
  RepHistoryService(SharedPreferences prefs)
      : _repsStore = _HistoryStore<int>(
          prefs: prefs,
          storageKey: _storageKey,
          decodeValue: _readIntValue,
        ),
        _weightStore = _HistoryStore<double>(
          prefs: prefs,
          storageKey: _weightStorageKey,
          decodeValue: _readDoubleValue,
        ),
        _durationStore = _HistoryStore<int>(
          prefs: prefs,
          storageKey: _durationStorageKey,
          decodeValue: _readIntValue,
        );

  static const String _storageKey = 'rep_history_v1';
  static const String _weightStorageKey = 'weight_history_v1';
  static const String _durationStorageKey = 'duration_history_v1';

  final _HistoryStore<int> _repsStore;
  final _HistoryStore<double> _weightStore;
  final _HistoryStore<int> _durationStore;

  Future<int?> getLastReps({
    required String workoutId,
    required String setId,
    required int lapIndex,
    required String moveId,
  }) async {
    return _repsStore.get(_key(
      workoutId: workoutId,
      setId: setId,
      lapIndex: lapIndex,
      moveId: moveId,
    ));
  }

  Future<void> saveReps({
    required String workoutId,
    required String setId,
    required int lapIndex,
    required String moveId,
    required int reps,
  }) async {
    await _repsStore.save(
      _key(
        workoutId: workoutId,
        setId: setId,
        lapIndex: lapIndex,
        moveId: moveId,
      ),
      reps,
    );
  }

  Future<double?> getLastWeight({
    required String workoutId,
    required String setId,
    required int lapIndex,
    required String moveId,
    required String weightUnit,
  }) async {
    return _weightStore.get(_weightKey(
      workoutId: workoutId,
      setId: setId,
      lapIndex: lapIndex,
      moveId: moveId,
      weightUnit: weightUnit,
    ));
  }

  Future<void> saveWeight({
    required String workoutId,
    required String setId,
    required int lapIndex,
    required String moveId,
    required String weightUnit,
    required double weight,
  }) async {
    await _weightStore.save(
      _weightKey(
        workoutId: workoutId,
        setId: setId,
        lapIndex: lapIndex,
        moveId: moveId,
        weightUnit: weightUnit,
      ),
      weight,
    );
  }

  Future<int?> getLastDuration({
    required String workoutId,
    required String setId,
    required int lapIndex,
    required String moveId,
  }) async {
    return _durationStore.get(_key(
      workoutId: workoutId,
      setId: setId,
      lapIndex: lapIndex,
      moveId: moveId,
    ));
  }

  Future<void> saveDuration({
    required String workoutId,
    required String setId,
    required int lapIndex,
    required String moveId,
    required int seconds,
  }) async {
    await _durationStore.save(
      _key(
        workoutId: workoutId,
        setId: setId,
        lapIndex: lapIndex,
        moveId: moveId,
      ),
      seconds,
    );
  }

  String _key({
    required String workoutId,
    required String setId,
    required int lapIndex,
    required String moveId,
  }) {
    return '$workoutId|$setId|$lapIndex|$moveId';
  }

  String _weightKey({
    required String workoutId,
    required String setId,
    required int lapIndex,
    required String moveId,
    required String weightUnit,
  }) {
    return '$workoutId|$setId|$lapIndex|$moveId|$weightUnit';
  }

  static int? _readIntValue(Object? value) {
    if (value is int) {
      return value;
    }
    return value is num ? value.toInt() : null;
  }

  static double? _readDoubleValue(Object? value) {
    return value is num ? value.toDouble() : null;
  }
}

class _HistoryStore<T extends num> {
  _HistoryStore({
    required SharedPreferences prefs,
    required this.storageKey,
    required this.decodeValue,
  }) : _prefs = prefs;

  final SharedPreferences _prefs;
  final String storageKey;
  final T? Function(Object? value) decodeValue;
  Map<String, T>? _cache;

  Future<T?> get(String key) async {
    await _ensureLoaded();
    return _cache![key];
  }

  Future<void> save(String key, T value) async {
    await _ensureLoaded();
    _cache![key] = value;
    await _prefs.setString(storageKey, jsonEncode(_cache));
  }

  Future<void> _ensureLoaded() async {
    if (_cache != null) {
      return;
    }

    await _prefs.reload();
    final String? raw = _prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) {
      _cache = <String, T>{};
      return;
    }

    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        _cache = <String, T>{};
        return;
      }

      _cache = <String, T>{
        for (final MapEntry<String, dynamic> entry in decoded.entries)
          if (decodeValue(entry.value) case final T value) entry.key: value,
      };
    } catch (_) {
      _cache = <String, T>{};
    }
  }
}
