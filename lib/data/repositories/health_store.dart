import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:sehatiku_mobile/data/models/health_record.dart';

/// Holds every saved [HealthRecord] and persists them to device storage.
/// Screens listen via [HealthScope] and rebuild whenever data changes.
class HealthStore extends ChangeNotifier {
  HealthStore();

  static const _storageKey = 'sehatiku_records_v1';

  final List<HealthRecord> _records = [];
  bool _loaded = false;

  bool get isLoaded => _loaded;

  /// Newest first.
  List<HealthRecord> get records {
    final sorted = [..._records]..sort((a, b) => b.date.compareTo(a.date));
    return sorted;
  }

  bool get isEmpty => _records.isEmpty;

  HealthRecord? get latest => records.isEmpty ? null : records.first;

  HealthRecord? recordFor(DateTime day) {
    final key = HealthRecord.dayOf(day);
    for (final r in _records) {
      if (r.date == key) return r;
    }
    return null;
  }

  HealthRecord? get today => recordFor(DateTime.now());

  /// The last [count] records ordered oldest -> newest (for charts).
  List<HealthRecord> recent(int count) {
    final desc = records;
    final slice = desc.take(count).toList();
    return slice.reversed.toList();
  }

  /// Average adherence (medicine taken) across the last [count] days that have
  /// records, as a percentage.
  int adherencePercent({int count = 7}) {
    final slice = recent(count);
    if (slice.isEmpty) return 0;
    final taken = slice.where((r) => r.medicineTaken).length;
    return ((taken / slice.length) * 100).round();
  }

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = jsonDecode(raw) as List<dynamic>;
        _records
          ..clear()
          ..addAll(
            list.map(
              (e) => HealthRecord.fromJson(e as Map<String, dynamic>),
            ),
          );
      } catch (_) {
        // Corrupt data — start clean rather than crash.
        _records.clear();
      }
    }
    _loaded = true;
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = jsonEncode(_records.map((e) => e.toJson()).toList());
    await prefs.setString(_storageKey, raw);
  }

  /// Insert or replace the record for its calendar day.
  Future<void> upsert(HealthRecord record) async {
    final key = HealthRecord.dayOf(record.date);
    _records.removeWhere((r) => r.date == key);
    _records.add(record);
    notifyListeners();
    await _persist();
  }

  Future<void> deleteFor(DateTime day) async {
    final key = HealthRecord.dayOf(day);
    _records.removeWhere((r) => r.date == key);
    notifyListeners();
    await _persist();
  }

  Future<void> clear() async {
    _records.clear();
    _loaded = false;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }
}

/// Exposes the [HealthStore] to the widget subtree and rebuilds dependents when
/// it notifies. Use [HealthScope.of] to read it.
class HealthScope extends InheritedNotifier<HealthStore> {
  const HealthScope({
    super.key,
    required HealthStore store,
    required super.child,
  }) : super(notifier: store);

  static HealthStore of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<HealthScope>();
    assert(scope != null, 'HealthScope not found in widget tree');
    return scope!.notifier!;
  }
}
