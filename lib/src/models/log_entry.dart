enum LogLevel {
  verbose('V'),
  debug('D'),
  info('I'),
  warn('W'),
  error('E'),
  fatal('F'),
  silent('S'),
  unknown('?');

  const LogLevel(this.letter);

  final String letter;

  static LogLevel fromLetter(String letter) {
    for (final level in values) {
      if (level.letter == letter) return level;
    }
    return LogLevel.unknown;
  }
}

class LogEntry {
  LogEntry({
    required this.lineNumber,
    required this.raw,
    this.timestamp,
    this.pid,
    this.tid,
    this.level = LogLevel.unknown,
    this.tag = '',
    String? message,
  }) : message = message ?? raw;

  final int lineNumber;
  final String raw;
  final String? timestamp;
  final int? pid;
  final int? tid;
  final LogLevel level;
  final String tag;
  final String message;

  bool get isParsed => pid != null;

  /// Text shown in the "Log Message" column.
  late final String displayMessage = isParsed
      ? '${timestamp == null ? '' : '$timestamp  '}${level.letter}/$tag: $message'
      : raw;
}
