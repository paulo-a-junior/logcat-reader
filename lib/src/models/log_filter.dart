import 'log_entry.dart';

class LogFilter {
  const LogFilter({
    this.text = '',
    this.useRegex = false,
    this.caseSensitive = false,
    this.process = '',
    this.tag = '',
    this.minLevel = LogLevel.verbose,
  });

  /// Matched against "tag: message" (or the raw line if unparsed).
  final String text;
  final bool useRegex;
  final bool caseSensitive;

  /// Substring of the process name, or an exact PID.
  final String process;

  /// Substring of the tag.
  final String tag;
  final LogLevel minLevel;

  LogFilter copyWith({
    String? text,
    bool? useRegex,
    bool? caseSensitive,
    String? process,
    String? tag,
    LogLevel? minLevel,
  }) =>
      LogFilter(
        text: text ?? this.text,
        useRegex: useRegex ?? this.useRegex,
        caseSensitive: caseSensitive ?? this.caseSensitive,
        process: process ?? this.process,
        tag: tag ?? this.tag,
        minLevel: minLevel ?? this.minLevel,
      );

  bool get dependsOnProcessName => process.trim().isNotEmpty;

  bool get isEmpty =>
      text.isEmpty &&
      process.trim().isEmpty &&
      tag.trim().isEmpty &&
      minLevel == LogLevel.verbose;

  CompiledFilter compile() => CompiledFilter._(this);

  Map<String, Object?> toJson() => {
        'text': text,
        'useRegex': useRegex,
        'caseSensitive': caseSensitive,
        'process': process,
        'tag': tag,
        'minLevel': minLevel.name,
      };

  factory LogFilter.fromJson(Map<String, Object?> json) => LogFilter(
        text: json['text'] as String? ?? '',
        useRegex: json['useRegex'] as bool? ?? false,
        caseSensitive: json['caseSensitive'] as bool? ?? false,
        process: json['process'] as String? ?? '',
        tag: json['tag'] as String? ?? '',
        minLevel:
            LogLevel.values.asNameMap()[json['minLevel']] ?? LogLevel.verbose,
      );
}

/// A named, user-managed filter shown as a balloon.
class SavedFilter {
  const SavedFilter({
    required this.id,
    required this.name,
    this.colorIndex = 0,
    this.enabled = false,
    this.exclude = false,
    this.criteria = const LogFilter(),
  });

  final String id;
  final String name;

  /// Index into the UI's filter colour palette.
  final int colorIndex;
  final bool enabled;

  /// Hide matching lines instead of showing them.
  final bool exclude;
  final LogFilter criteria;

  static int _counter = 0;

  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '-${(_counter++).toRadixString(36)}';

  SavedFilter copyWith({
    String? id,
    String? name,
    int? colorIndex,
    bool? enabled,
    bool? exclude,
    LogFilter? criteria,
  }) =>
      SavedFilter(
        id: id ?? this.id,
        name: name ?? this.name,
        colorIndex: colorIndex ?? this.colorIndex,
        enabled: enabled ?? this.enabled,
        exclude: exclude ?? this.exclude,
        criteria: criteria ?? this.criteria,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'colorIndex': colorIndex,
        'enabled': enabled,
        'exclude': exclude,
        'criteria': criteria.toJson(),
      };

  factory SavedFilter.fromJson(Map<String, Object?> json) => SavedFilter(
        id: json['id'] as String? ?? newId(),
        name: json['name'] as String? ?? '',
        colorIndex: json['colorIndex'] as int? ?? 0,
        enabled: json['enabled'] as bool? ?? false,
        exclude: json['exclude'] as bool? ?? false,
        criteria: json['criteria'] is Map
            ? LogFilter.fromJson(
                (json['criteria'] as Map).cast<String, Object?>())
            : const LogFilter(),
      );
}

class CompiledFilter {
  CompiledFilter._(this.filter) {
    final text = filter.text;
    if (text.isNotEmpty) {
      if (filter.useRegex) {
        try {
          _regex = RegExp(text, caseSensitive: filter.caseSensitive);
        } on FormatException catch (e) {
          error = e.message;
        }
      } else {
        _needle = filter.caseSensitive ? text : text.toLowerCase();
      }
    }
    final process = filter.process.trim();
    if (process.isNotEmpty) {
      _pid = int.tryParse(process);
      _process = process.toLowerCase();
    }
    final tag = filter.tag.trim();
    if (tag.isNotEmpty) _tag = tag.toLowerCase();
  }

  final LogFilter filter;

  /// Non-null when the regex is invalid; nothing matches in that case.
  String? error;

  RegExp? _regex;
  String? _needle;
  String? _process;
  int? _pid;
  String? _tag;

  bool matches(LogEntry e, String? processName) {
    if (error != null) return false;

    if (filter.minLevel != LogLevel.verbose &&
        (e.level == LogLevel.unknown ||
            e.level.index < filter.minLevel.index)) {
      return false;
    }

    if (_tag != null && !e.tag.toLowerCase().contains(_tag!)) return false;

    if (_process != null) {
      final byPid = _pid != null && e.pid == _pid;
      final byName =
          processName != null && processName.toLowerCase().contains(_process!);
      if (!byPid && !byName) return false;
    }

    if (_regex != null || _needle != null) {
      final haystack = e.isParsed ? '${e.tag}: ${e.message}' : e.raw;
      if (_regex != null) {
        if (!_regex!.hasMatch(haystack)) return false;
      } else {
        final h = filter.caseSensitive ? haystack : haystack.toLowerCase();
        if (!h.contains(_needle!)) return false;
      }
    }
    return true;
  }
}
