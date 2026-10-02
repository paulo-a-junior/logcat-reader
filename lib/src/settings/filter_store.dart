import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/log_entry.dart';
import '../models/log_filter.dart';

/// How enabled "show" filters are combined.
enum FilterCombine {
  /// A line is shown if it matches any enabled filter.
  any,

  /// A line is shown only if it matches every enabled filter.
  all,
}

/// The user's saved filters, persisted with shared_preferences.
class FilterStore extends ChangeNotifier {
  FilterStore._(this._prefs) {
    final raw = _prefs.getString(_kFilters);
    if (raw == null) {
      _filters = _defaults();
    } else {
      try {
        _filters = [
          for (final f in jsonDecode(raw) as List)
            SavedFilter.fromJson((f as Map).cast<String, Object?>()),
        ];
      } on Object {
        _filters = _defaults();
      }
    }
    _combine = FilterCombine.values.asNameMap()[_prefs.getString(_kCombine)] ??
        FilterCombine.any;
  }

  static Future<FilterStore> load() async =>
      FilterStore._(await SharedPreferences.getInstance());

  static const _kFilters = 'filters';
  static const _kCombine = 'filterCombine';

  final SharedPreferences _prefs;
  late List<SavedFilter> _filters;
  late FilterCombine _combine;

  static List<SavedFilter> _defaults() => [
        SavedFilter(
          id: SavedFilter.newId(),
          name: 'Errors',
          colorIndex: 0,
          criteria: const LogFilter(minLevel: LogLevel.error),
        ),
        SavedFilter(
          id: SavedFilter.newId(),
          name: 'Warnings',
          colorIndex: 1,
          criteria: const LogFilter(minLevel: LogLevel.warn),
        ),
        SavedFilter(
          id: SavedFilter.newId(),
          name: 'Crashes',
          colorIndex: 7,
          criteria: const LogFilter(
            text: r'FATAL EXCEPTION|ANR in |Fatal signal',
            useRegex: true,
            caseSensitive: true,
          ),
        ),
      ];

  List<SavedFilter> get filters => List.unmodifiable(_filters);

  SavedFilter? byId(String id) => _filters.where((f) => f.id == id).firstOrNull;

  FilterCombine get combine => _combine;
  set combine(FilterCombine value) {
    if (value == _combine) return;
    _combine = value;
    _prefs.setString(_kCombine, value.name);
    notifyListeners();
  }

  void add(SavedFilter filter, {int? index}) {
    _filters.insert(index ?? _filters.length, filter);
    _changed();
  }

  void update(SavedFilter filter) {
    final i = _filters.indexWhere((f) => f.id == filter.id);
    if (i < 0) return;
    _filters[i] = filter;
    _changed();
  }

  void remove(String id) {
    _filters.removeWhere((f) => f.id == id);
    _changed();
  }

  void toggle(String id) {
    final f = byId(id);
    if (f != null) update(f.copyWith(enabled: !f.enabled));
  }

  void setAllEnabled(bool enabled) {
    _filters = [for (final f in _filters) f.copyWith(enabled: enabled)];
    _changed();
  }

  /// Duplicates [id] right after it and returns the copy.
  SavedFilter? duplicate(String id, String name) {
    final i = _filters.indexWhere((f) => f.id == id);
    if (i < 0) return null;
    final copy = _filters[i].copyWith(id: SavedFilter.newId(), name: name);
    add(copy, index: i + 1);
    return copy;
  }

  /// Same semantics as [ReorderableListView.onReorder].
  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    _filters.insert(newIndex, _filters.removeAt(oldIndex));
    _changed();
  }

  void _changed() {
    _prefs.setString(
        _kFilters, jsonEncode([for (final f in _filters) f.toJson()]));
    notifyListeners();
  }
}
