import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/command_shortcut.dart';

/// The user's command shortcuts, persisted with shared_preferences.
class ShortcutStore extends ChangeNotifier {
  ShortcutStore._(this._prefs) {
    final raw = _prefs.getString(_kShortcuts);
    if (raw == null) {
      _shortcuts = _defaults();
    } else {
      try {
        _shortcuts = [
          for (final s in jsonDecode(raw) as List)
            CommandShortcut.fromJson((s as Map).cast<String, Object?>()),
        ];
      } on Object {
        _shortcuts = _defaults();
      }
    }
  }

  static Future<ShortcutStore> load() async =>
      ShortcutStore._(await SharedPreferences.getInstance());

  static const _kShortcuts = 'shortcuts';

  final SharedPreferences _prefs;
  late List<CommandShortcut> _shortcuts;

  static List<CommandShortcut> _defaults() => [
        CommandShortcut(
          id: CommandShortcut.newId(),
          name: 'Home',
          command: 'input keyevent KEYCODE_HOME',
          iconIndex: 1,
          pinned: true,
        ),
        CommandShortcut(
          id: CommandShortcut.newId(),
          name: 'Current activity',
          command: "dumpsys activity activities | grep -E "
              "'mResumedActivity|topResumedActivity'",
          output: ShortcutOutput.console,
          iconIndex: 4,
        ),
        CommandShortcut(
          id: CommandShortcut.newId(),
          name: 'Device properties',
          command: 'getprop',
          output: ShortcutOutput.console,
          iconIndex: 5,
        ),
      ];

  List<CommandShortcut> get shortcuts => List.unmodifiable(_shortcuts);

  CommandShortcut? byId(String id) =>
      _shortcuts.where((s) => s.id == id).firstOrNull;

  void add(CommandShortcut s) {
    _shortcuts.add(s);
    _changed();
  }

  void update(CommandShortcut s) {
    final i = _shortcuts.indexWhere((e) => e.id == s.id);
    if (i < 0) return;
    _shortcuts[i] = s;
    _changed();
  }

  void remove(String id) {
    _shortcuts.removeWhere((s) => s.id == id);
    _changed();
  }

  /// [ReorderableListView] semantics: [newIndex] is computed before removal.
  void reorder(int oldIndex, int newIndex) {
    if (newIndex > oldIndex) newIndex--;
    _shortcuts.insert(newIndex, _shortcuts.removeAt(oldIndex));
    _changed();
  }

  void _changed() {
    _prefs.setString(
        _kShortcuts, jsonEncode([for (final s in _shortcuts) s.toJson()]));
    notifyListeners();
  }
}
