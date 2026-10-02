import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum LongLineMode { ellipsis, wrap }

/// User preferences, persisted with shared_preferences.
class AppSettings extends ChangeNotifier {
  AppSettings._(this._prefs) {
    _load();
  }

  static Future<AppSettings> load() async =>
      AppSettings._(await SharedPreferences.getInstance());

  static const minFontSize = 8.0;
  static const maxFontSize = 24.0;
  static const defaultFontSize = 12.5;

  /// Languages with translations; `null` in [locale] means "system".
  static const supportedLanguages = ['en', 'pt'];

  static const _kAutoReconnect = 'autoReconnect';
  static const _kLongLineMode = 'longLineMode';
  static const _kThemeMode = 'themeMode';
  static const _kFontSize = 'logFontSize';
  static const _kNotifyLost = 'notifyConnectionLost';
  static const _kNotifyReconnected = 'notifyReconnected';
  static const _kNotifyCrash = 'notifyCrash';
  static const _kLanguage = 'language';
  static const _kAdbPath = 'adbPath';
  static const _kAdbRoot = 'adbRoot';

  final SharedPreferences _prefs;

  late bool _autoReconnect;
  late LongLineMode _longLineMode;
  late ThemeMode _themeMode;
  late double _fontSize;
  late bool _notifyConnectionLost;
  late bool _notifyReconnected;
  late bool _notifyCrash;
  late String? _language;
  late String? _adbPath;
  late bool _adbRoot;

  void _load() {
    final adbPath = _prefs.getString(_kAdbPath)?.trim();
    _adbPath = adbPath == null || adbPath.isEmpty ? null : adbPath;
    _adbRoot = _prefs.getBool(_kAdbRoot) ?? false;
    _autoReconnect = _prefs.getBool(_kAutoReconnect) ?? true;
    _longLineMode =
        LongLineMode.values.asNameMap()[_prefs.getString(_kLongLineMode)] ??
            LongLineMode.ellipsis;
    _themeMode = ThemeMode.values.asNameMap()[_prefs.getString(_kThemeMode)] ??
        ThemeMode.system;
    _fontSize = (_prefs.getDouble(_kFontSize) ?? defaultFontSize)
        .clamp(minFontSize, maxFontSize);
    _notifyConnectionLost = _prefs.getBool(_kNotifyLost) ?? true;
    _notifyReconnected = _prefs.getBool(_kNotifyReconnected) ?? true;
    _notifyCrash = _prefs.getBool(_kNotifyCrash) ?? true;
    final language = _prefs.getString(_kLanguage);
    _language = supportedLanguages.contains(language) ? language : null;
  }

  Future<void> resetToDefaults() async {
    for (final key in [
      _kAutoReconnect,
      _kLongLineMode,
      _kThemeMode,
      _kFontSize,
      _kNotifyLost,
      _kNotifyReconnected,
      _kNotifyCrash,
      _kLanguage,
      _kAdbPath,
      _kAdbRoot,
    ]) {
      await _prefs.remove(key);
    }
    _load();
    notifyListeners();
  }

  /// Path to the adb executable, or `null` to use `$ADB` / `adb` on `PATH`.
  String? get adbPath => _adbPath;
  set adbPath(String? v) {
    v = v?.trim();
    if (v != null && v.isEmpty) v = null;
    if (v == _adbPath) return;
    _adbPath = v;
    if (v == null) {
      _prefs.remove(_kAdbPath);
    } else {
      _prefs.setString(_kAdbPath, v);
    }
    notifyListeners();
  }

  /// Run adbd as root (`adb root`) when reading device logs.
  bool get adbRoot => _adbRoot;
  set adbRoot(bool v) {
    if (v == _adbRoot) return;
    _adbRoot = v;
    _prefs.setBool(_kAdbRoot, v);
    notifyListeners();
  }

  /// Restart logcat automatically when the device disconnects or reboots.
  bool get autoReconnect => _autoReconnect;
  set autoReconnect(bool v) {
    if (v == _autoReconnect) return;
    _autoReconnect = v;
    _prefs.setBool(_kAutoReconnect, v);
    notifyListeners();
  }

  LongLineMode get longLineMode => _longLineMode;
  set longLineMode(LongLineMode v) {
    if (v == _longLineMode) return;
    _longLineMode = v;
    _prefs.setString(_kLongLineMode, v.name);
    notifyListeners();
  }

  ThemeMode get themeMode => _themeMode;
  set themeMode(ThemeMode v) {
    if (v == _themeMode) return;
    _themeMode = v;
    _prefs.setString(_kThemeMode, v.name);
    notifyListeners();
  }

  /// Font size of the log tables.
  double get fontSize => _fontSize;
  set fontSize(double v) {
    v = v.clamp(minFontSize, maxFontSize);
    if (v == _fontSize) return;
    _fontSize = v;
    _prefs.setDouble(_kFontSize, v);
    notifyListeners();
  }

  bool get notifyConnectionLost => _notifyConnectionLost;
  set notifyConnectionLost(bool v) {
    if (v == _notifyConnectionLost) return;
    _notifyConnectionLost = v;
    _prefs.setBool(_kNotifyLost, v);
    notifyListeners();
  }

  bool get notifyReconnected => _notifyReconnected;
  set notifyReconnected(bool v) {
    if (v == _notifyReconnected) return;
    _notifyReconnected = v;
    _prefs.setBool(_kNotifyReconnected, v);
    notifyListeners();
  }

  bool get notifyCrash => _notifyCrash;
  set notifyCrash(bool v) {
    if (v == _notifyCrash) return;
    _notifyCrash = v;
    _prefs.setBool(_kNotifyCrash, v);
    notifyListeners();
  }

  /// Language code, or `null` to follow the system.
  String? get language => _language;
  set language(String? v) {
    if (v != null && !supportedLanguages.contains(v)) v = null;
    if (v == _language) return;
    _language = v;
    if (v == null) {
      _prefs.remove(_kLanguage);
    } else {
      _prefs.setString(_kLanguage, v);
    }
    notifyListeners();
  }

  Locale? get locale => _language == null ? null : Locale(_language!);
}
