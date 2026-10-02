import '../models/log_entry.dart';

/// Parses logcat lines in the `threadtime` (default), `time` and `brief`
/// formats. Unrecognised lines are kept verbatim as unparsed entries.
class LogcatParser {
  // [YYYY-]MM-DD HH:MM:SS.mmm [UID] PID TID L TAG: message
  static final _threadtime = RegExp(
    r'^((?:\d{4}-)?\d\d-\d\d\s+\d\d:\d\d:\d\d\.\d+)\s+(?:\S+\s+)??(\d+)\s+(\d+)\s+([VDIWEFS])\s+(.*?)\s*:(?: (.*))?$',
  );

  // [YYYY-]MM-DD HH:MM:SS.mmm L/TAG( PID): message
  static final _time = RegExp(
    r'^((?:\d{4}-)?\d\d-\d\d\s+\d\d:\d\d:\d\d\.\d+)\s+([VDIWEFS])/(.*?)\(\s*(\d+)\):(?: (.*))?$',
  );

  // L/TAG( PID): message
  static final _brief = RegExp(r'^([VDIWEFS])/(.*?)\(\s*(\d+)\):(?: (.*))?$');

  static final _startProc = RegExp(r'Start proc (\d+):([^\s/]+)');

  static LogEntry parse(String line, int lineNumber) {
    if (line.endsWith('\r')) line = line.substring(0, line.length - 1);

    var m = _threadtime.firstMatch(line);
    if (m != null) {
      return LogEntry(
        lineNumber: lineNumber,
        raw: line,
        timestamp: m.group(1),
        pid: int.parse(m.group(2)!),
        tid: int.parse(m.group(3)!),
        level: LogLevel.fromLetter(m.group(4)!),
        tag: m.group(5)!,
        message: m.group(6) ?? '',
      );
    }

    m = _time.firstMatch(line);
    if (m != null) {
      return LogEntry(
        lineNumber: lineNumber,
        raw: line,
        timestamp: m.group(1),
        level: LogLevel.fromLetter(m.group(2)!),
        tag: m.group(3)!.trimRight(),
        pid: int.parse(m.group(4)!),
        message: m.group(5) ?? '',
      );
    }

    m = _brief.firstMatch(line);
    if (m != null) {
      return LogEntry(
        lineNumber: lineNumber,
        raw: line,
        level: LogLevel.fromLetter(m.group(1)!),
        tag: m.group(2)!.trimRight(),
        pid: int.parse(m.group(3)!),
        message: m.group(4) ?? '',
      );
    }

    return LogEntry(lineNumber: lineNumber, raw: line);
  }

  /// Extracts a `pid -> process name` hint from ActivityManager
  /// "Start proc 1234:com.example/u0a12 ..." lines.
  static MapEntry<int, String>? processStartHint(LogEntry entry) {
    if (entry.tag != 'ActivityManager') return null;
    final m = _startProc.firstMatch(entry.message);
    if (m == null) return null;
    return MapEntry(int.parse(m.group(1)!), m.group(2)!);
  }
}
