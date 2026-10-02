import 'package:flutter/material.dart';

import '../../l10n/gen/app_localizations.dart';
import '../adb/adb_client.dart';
import '../controller/log_events.dart';
import '../models/log_entry.dart';
import '../models/log_filter.dart';

export '../../l10n/gen/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}

extension LocalizedStrings on AppLocalizations {
  String status(LogStatus status) => switch (status) {
        StatusStarting(:final source) => statusStarting(source),
        StatusStreaming(:final source) => statusStreaming(source),
        StatusEnded(:final source) => statusEnded(source),
        StatusReconnecting(:final source, :final attempt) =>
          statusReconnecting(source, attempt),
        StatusStopped() => statusStopped,
        StatusLoading(:final path) => statusLoading(path),
        StatusLoaded(:final path, :final count) => statusLoaded(count, path),
        StatusReadFailed(:final path, :final error) =>
          statusReadFailed(path, error),
        StatusAdbError(:final error) => adbError(error),
        StatusAdbMessage(:final message) => message,
      };

  String adbError(AdbException e) =>
      e is AdbNotFoundException ? adbNotFound(e.adbPath) : e.message;

  String level(LogLevel level) => switch (level) {
        LogLevel.verbose => levelVerbose,
        LogLevel.debug => levelDebug,
        LogLevel.info => levelInfo,
        LogLevel.warn => levelWarn,
        LogLevel.error => levelError,
        LogLevel.fatal => levelFatal,
        _ => level.letter,
      };

  /// One-line, human readable description of a filter's criteria.
  String filterSummary(LogFilter f) {
    final parts = <String>[
      if (f.minLevel != LogLevel.verbose) summaryLevel(level(f.minLevel)),
      if (f.text.isNotEmpty)
        (f.useRegex ? '/${f.text}/' : '"${f.text}"') +
            (f.caseSensitive ? ' (Aa)' : ''),
      if (f.tag.trim().isNotEmpty) summaryTag(f.tag.trim()),
      if (f.process.trim().isNotEmpty) summaryProcess(f.process.trim()),
    ];
    return parts.isEmpty ? summaryMatchesAll : parts.join(' · ');
  }

  /// Endonym shown in the language picker.
  static String languageName(String code) => switch (code) {
        'en' => 'English',
        'pt' => 'Português',
        _ => code,
      };
}

/// Log level colour tuned for the current theme brightness.
Color? levelColor(LogLevel level, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  return switch (level) {
    LogLevel.verbose => dark ? Colors.grey : Colors.grey.shade700,
    LogLevel.debug =>
      dark ? Colors.lightBlue.shade300 : Colors.lightBlue.shade800,
    LogLevel.info => dark ? Colors.green.shade400 : Colors.green.shade800,
    LogLevel.warn => dark ? Colors.orange.shade400 : Colors.orange.shade900,
    LogLevel.error ||
    LogLevel.fatal =>
      dark ? Colors.red.shade400 : Colors.red.shade800,
    _ => null,
  };
}
