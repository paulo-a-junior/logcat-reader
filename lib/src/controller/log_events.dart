import '../adb/adb_client.dart';
import '../models/log_entry.dart';

/// What the status bar should show. Localized by the UI.
sealed class LogStatus {
  const LogStatus();
}

class StatusStarting extends LogStatus {
  const StatusStarting(this.source);
  final String source;
}

class StatusStreaming extends LogStatus {
  const StatusStreaming(this.source);
  final String source;
}

class StatusEnded extends LogStatus {
  const StatusEnded(this.source);
  final String source;
}

class StatusReconnecting extends LogStatus {
  const StatusReconnecting(this.source, this.attempt);
  final String source;
  final int attempt;
}

class StatusStopped extends LogStatus {
  const StatusStopped();
}

class StatusLoading extends LogStatus {
  const StatusLoading(this.path);
  final String path;
}

class StatusLoaded extends LogStatus {
  const StatusLoaded(this.path, this.count);
  final String path;
  final int count;
}

class StatusReadFailed extends LogStatus {
  const StatusReadFailed(this.path, this.error);
  final String path;
  final String error;
}

class StatusAdbError extends LogStatus {
  const StatusAdbError(this.error);
  final AdbException error;
}

/// Verbatim message from adb (stderr), not translated.
class StatusAdbMessage extends LogStatus {
  const StatusAdbMessage(this.message);
  final String message;
}

/// Noteworthy things that happen while streaming; used for notifications.
sealed class LogEvent {
  const LogEvent(this.source);
  final String source;
}

class ConnectionLostEvent extends LogEvent {
  const ConnectionLostEvent(super.source);
}

class ReconnectedEvent extends LogEvent {
  const ReconnectedEvent(super.source, {required this.rebooted});
  final bool rebooted;
}

enum CrashKind { java, anr, native }

/// `adb root` or `adb unroot` did not take effect; [message] is adb's.
class RootFailedEvent extends LogEvent {
  const RootFailedEvent(super.source, this.message);
  final String message;
}

class CrashEvent extends LogEvent {
  const CrashEvent(super.source, this.kind, this.process, this.entry);
  final CrashKind kind;
  final String process;
  final LogEntry entry;
}

/// A log file was not UTF-8; it is converted while loading, in memory
/// only. [encoding] is the detected encoding, e.g. `UTF-16LE`.
class WideEncodingEvent extends LogEvent {
  const WideEncodingEvent(super.source, this.encoding);
  final String encoding;
}
