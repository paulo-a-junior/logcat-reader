import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../adb/adb_client.dart';
import '../models/log_entry.dart';
import '../models/log_filter.dart';
import '../parsing/logcat_parser.dart';
import 'log_events.dart';
import 'text_encoding.dart';

export 'log_events.dart';

enum SourceKind { none, device, file }

/// An enabled filter as applied by [LogController].
class FilterRule {
  FilterRule({
    required LogFilter criteria,
    this.exclude = false,
    this.mark = -1,
  }) : compiled = criteria.compile();

  final CompiledFilter compiled;

  /// Hide matching lines instead of showing them.
  final bool exclude;

  /// Opaque marker reported for rows shown because of this rule
  /// (the UI uses it as a colour index).
  final int mark;
}

/// Owns the log buffer, the active filter and the current log source.
class LogController extends ChangeNotifier {
  LogController({AdbClient? adb}) : adb = adb ?? AdbClient();

  final AdbClient adb;

  final List<LogEntry> entries = [];

  /// Bumped whenever [entries] is replaced rather than appended to (new
  /// source or clear), so views can drop state derived from row indices.
  int entriesVersion = 0;

  /// Like [entriesVersion], for [filtered]; also bumped on filter changes.
  int filteredVersion = 0;

  /// Indices into [entries] that match the active filters.
  final List<int> filtered = [];

  /// For each row of [filtered], the [FilterRule.mark] of the first "show"
  /// rule it matched, or -1.
  final List<int> filteredMarks = [];

  final Map<int, String> _processNames = {};

  /// PIDs seen since the last `ps` refresh that still need a name.
  final Set<int> _unresolvedPids = {};

  /// PIDs a `ps` refresh could not resolve (exited, or kernel); not retried.
  final Set<int> _unresolvable = {0};

  List<FilterRule> _include = const [];
  List<FilterRule> _exclude = const [];
  bool _matchAll = false;
  bool _rulesUseProcessName = false;

  SourceKind sourceKind = SourceKind.none;
  String sourceLabel = '';
  bool running = false;

  /// True while waiting for a lost device to come back.
  bool reconnecting = false;

  /// Restart logcat automatically when the device stream ends unexpectedly.
  bool _autoReconnect = true;
  LogStatus? status;

  final _events = StreamController<LogEvent>.broadcast();

  /// Connection and crash events, for notifications.
  Stream<LogEvent> get events => _events.stream;

  /// Crashes stamped before this device time (`MM-DD hh:mm:ss`) are part of
  /// the initial buffer dump and are not reported.
  String? _crashBaseline;
  final Map<String, DateTime> _lastCrashEvent = {};

  static const _reconnectInterval = Duration(seconds: 2);
  String? _bootId;
  String? _resumeTimestamp;
  Set<String> _resumeSkip = const {};

  Process? _process;
  StreamSubscription<String>? _subscription;
  String? _serial;
  final List<String> _pending = [];
  Timer? _flushTimer;
  DateTime _lastPsRefresh = DateTime.fromMillisecondsSinceEpoch(0);
  bool _psRefreshing = false;
  int _generation = 0;

  bool get autoReconnect => _autoReconnect;

  set autoReconnect(bool value) {
    _autoReconnect = value;
    if (!value && reconnecting) {
      unawaited(stop());
    }
    notifyListeners();
  }

  bool _runAsRoot = false;

  /// Set after `adb root` failed for the current device (e.g. a production
  /// build), so reconnects do not retry it.
  bool _rootFailed = false;

  /// Restart adbd as root (`adb root`) before reading device logs. Changing
  /// it while streaming restarts adbd in the new mode (`adb root` or
  /// `adb unroot`) and resumes logcat.
  bool get runAsRoot => _runAsRoot;

  set runAsRoot(bool value) {
    if (value == _runAsRoot) return;
    _runAsRoot = value;
    _rootFailed = false;
    if (sourceKind == SourceKind.device && active && _serial != null) {
      unawaited(_restartAdbd());
    }
    notifyListeners();
  }

  /// Streaming or waiting to reconnect; i.e. "Stop" is meaningful.
  bool get active => running || reconnecting;

  /// Whether any filter rule is active (otherwise no line is shown).
  bool get hasActiveFilters => _include.isNotEmpty || _exclude.isNotEmpty;

  String? processNameOf(LogEntry e) {
    final pid = e.pid;
    if (pid == null) return null;
    return _processNames[pid] ?? (pid == 0 ? 'kernel' : null);
  }

  String processLabel(LogEntry e) {
    final pid = e.pid;
    if (pid == null) return '';
    final name = _processNames[pid] ?? (pid == 0 ? 'kernel' : null);
    return name == null ? '$pid' : '$name ($pid)';
  }

  /// Replaces the active filters. "Exclude" rules always hide matching
  /// lines; the remaining lines must match any (or, with [matchAll], every)
  /// "include" rule. With only exclude rules, everything not excluded is
  /// shown; with no rules at all, nothing is shown.
  void setFilters(List<FilterRule> rules, {bool matchAll = false}) {
    _include = [
      for (final r in rules)
        if (!r.exclude) r
    ];
    _exclude = [
      for (final r in rules)
        if (r.exclude) r
    ];
    _matchAll = matchAll;
    _rulesUseProcessName =
        rules.any((r) => r.compiled.filter.dependsOnProcessName);
    _refilter();
    notifyListeners();
  }

  /// Returns -2 if [e] is filtered out, otherwise the row's mark.
  int _match(LogEntry e) {
    final name = processNameOf(e);
    for (final r in _exclude) {
      if (r.compiled.matches(e, name)) return -2;
    }
    if (_include.isEmpty) return -1;
    if (_matchAll) {
      for (final r in _include) {
        if (!r.compiled.matches(e, name)) return -2;
      }
      return _include.first.mark;
    }
    for (final r in _include) {
      if (r.compiled.matches(e, name)) return r.mark;
    }
    return -2;
  }

  void _addIfMatches(int index) {
    if (!hasActiveFilters) return;
    final mark = _match(entries[index]);
    if (mark != -2) {
      filtered.add(index);
      filteredMarks.add(mark);
    }
  }

  void _refilter() {
    filteredVersion++;
    filtered.clear();
    filteredMarks.clear();
    if (!hasActiveFilters) return;
    for (var i = 0; i < entries.length; i++) {
      _addIfMatches(i);
    }
  }

  // ---------------------------------------------------------------- sources

  Future<void> startDevice(String serial, {String? label}) async {
    await stop();
    _reset();
    final generation = _generation;
    sourceKind = SourceKind.device;
    sourceLabel = label ?? serial;
    _serial = serial;
    status = StatusStarting(sourceLabel);
    notifyListeners();

    if (_runAsRoot) {
      await _ensureRoot(serial);
      if (generation != _generation) return;
    }
    unawaited(_refreshProcessNames(force: true));
    _bootId = await adb.bootId(serial).catchError((_) => null);
    _crashBaseline = await adb.deviceTime(serial).catchError((_) => null);
    if (generation != _generation) return;
    await _runLogcat(generation);
  }

  Future<void> _runLogcat(int generation, {String? since}) async {
    final serial = _serial!;
    try {
      final process = await adb.startLogcat(serial, since: since);
      if (generation != _generation) {
        process.kill();
        return;
      }
      _process = process;
      running = true;
      reconnecting = false;
      status = StatusStreaming(sourceLabel);
      final startedAt = DateTime.now();
      process.stderr
          .transform(const Utf8Decoder(allowMalformed: true))
          .listen((err) {
        final msg = err.trim();
        if (generation == _generation &&
            msg.isNotEmpty &&
            msg != '- waiting for device -') {
          status = StatusAdbMessage(msg);
          notifyListeners();
        }
      });
      _subscription = process.stdout
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter())
          .listen(_onDeviceLine, onDone: () {
        if (generation != _generation) return;
        _flush();
        _process = null;
        _subscription = null;
        running = false;
        _emit(ConnectionLostEvent(sourceLabel));
        if (autoReconnect) {
          // Back off if logcat dies right away (e.g. device not found yet).
          final quick =
              DateTime.now().difference(startedAt) < const Duration(seconds: 2);
          unawaited(_reconnect(generation, delayFirst: quick));
        } else {
          _stopTimer();
          status = StatusEnded(sourceLabel);
        }
        notifyListeners();
      });
      _startTimer();
    } on AdbException catch (e) {
      status = StatusAdbError(e);
      running = false;
      reconnecting = false;
    }
    notifyListeners();
  }

  /// Waits until [_serial] is back online (running `adb connect` for
  /// network devices) and resumes logcat where it left off.
  /// Puts adbd in root mode; reports a failure once per device session.
  Future<void> _ensureRoot(String serial) async {
    if (_rootFailed) return;
    try {
      await adb.setRoot(serial, true);
    } on AdbException catch (e) {
      _rootFailed = true;
      _emit(RootFailedEvent(sourceLabel, e.message));
    }
  }

  /// Restarts adbd according to [runAsRoot] and resumes logcat.
  Future<void> _restartAdbd() async {
    final serial = _serial!;
    final root = _runAsRoot;
    _generation++;
    final generation = _generation;
    await _subscription?.cancel();
    _subscription = null;
    _process?.kill();
    _process = null;
    _flush();
    running = false;
    reconnecting = true;
    status = StatusStarting(sourceLabel);
    notifyListeners();

    if (root) {
      await _ensureRoot(serial);
    } else {
      try {
        await adb.setRoot(serial, false);
      } on AdbException catch (e) {
        _emit(RootFailedEvent(sourceLabel, e.message));
      }
    }
    if (generation != _generation) return;
    await _reconnect(generation,
        announce: false,
        marker: root ? 'adbd restarted as root' : 'adbd restarted as non-root');
  }

  /// [marker] replaces the "reconnected" line added to the log; with
  /// [announce] false no [ReconnectedEvent] is sent.
  Future<void> _reconnect(int generation,
      {bool delayFirst = false, bool announce = true, String? marker}) async {
    final serial = _serial!;
    final isNetwork = serial.contains(':');
    reconnecting = true;
    var attempt = 0;
    while (generation == _generation) {
      attempt++;
      status = StatusReconnecting(sourceLabel, attempt);
      notifyListeners();
      if (delayFirst || attempt > 1) {
        await Future<void>.delayed(_reconnectInterval);
        if (generation != _generation) return;
      }
      try {
        final device =
            (await adb.devices()).where((d) => d.serial == serial).firstOrNull;
        if (generation != _generation) return;
        if (device != null && device.isOnline) break;
        if (isNetwork) {
          if (device != null) await adb.disconnect(serial);
          await adb.connect(serial);
        }
      } on AdbException {
        // Keep retrying until the user stops.
      }
    }
    if (generation != _generation) return;

    // adbd comes back as non-root after a reboot.
    if (_runAsRoot) {
      await _ensureRoot(serial);
      if (generation != _generation) return;
    }
    final bootId = await adb.bootId(serial).catchError((_) => null);
    if (generation != _generation) return;
    final rebooted = bootId != null && _bootId != null && bootId != _bootId;
    _bootId = bootId ?? _bootId;
    _crashBaseline =
        await adb.deviceTime(serial).catchError((_) => null) ?? _crashBaseline;
    if (generation != _generation) return;
    if (announce) _emit(ReconnectedEvent(sourceLabel, rebooted: rebooted));

    String? since;
    if (rebooted) {
      _pending.add('--------- device $sourceLabel rebooted ---------');
      _unresolvable
        ..clear()
        ..add(0);
    } else {
      _pending.add('--------- ${marker ?? 'reconnected to $sourceLabel'} '
          '---------');
      since = entries.reversed
          .map((e) => e.timestamp)
          .firstWhere((t) => t != null, orElse: () => null);
      if (since != null) {
        _resumeTimestamp = since;
        _resumeSkip = {
          for (final e in entries.reversed
              .takeWhile((e) => e.timestamp == since || e.timestamp == null))
            e.raw,
        };
      }
    }
    unawaited(_refreshProcessNames(force: true));
    await _runLogcat(generation, since: since);
  }

  /// Drops lines already received before a reconnect: `logcat -T` repeats
  /// every line stamped with the resume timestamp.
  void _onDeviceLine(String line) {
    final ts = _resumeTimestamp;
    if (ts != null) {
      if (line.startsWith('--------- beginning of')) return;
      if (line.startsWith(ts)) {
        if (_resumeSkip.contains(line)) return;
      } else {
        _resumeTimestamp = null;
        _resumeSkip = const {};
      }
    }
    _pending.add(line);
  }

  Future<void> openFile(String path) async {
    await stop();
    _reset();
    final generation = _generation;
    sourceKind = SourceKind.file;
    sourceLabel = path;
    running = true;
    status = StatusLoading(path);
    notifyListeners();
    _startTimer();

    void finish(LogStatus Function() message) {
      if (generation != _generation) return;
      _flush();
      _stopTimer();
      _subscription = null;
      running = false;
      status = message();
      notifyListeners();
    }

    final file = File(path);
    DetectedEncoding detected;
    try {
      detected = await detectEncoding(file);
    } on FileSystemException catch (e) {
      finish(() => StatusReadFailed(path, '$e'));
      return;
    }
    if (generation != _generation) return;
    if (detected.encoding.isWide) {
      _emit(WideEncodingEvent(path, detected.encoding.label));
    }

    _subscription = file
        .openRead(detected.bomLength)
        .transform(detected.encoding.decoder)
        .transform(const LineSplitter())
        .listen(
          _pending.add,
          onError: (Object e) => finish(() => StatusReadFailed(path, '$e')),
          onDone: () => finish(() => StatusLoaded(path, entries.length)),
          cancelOnError: true,
        );
  }

  Future<void> stop() async {
    _generation++;
    _stopTimer();
    await _subscription?.cancel();
    _subscription = null;
    _process?.kill();
    _process = null;
    _flush();
    if (running || reconnecting) {
      running = false;
      reconnecting = false;
      status = const StatusStopped();
      notifyListeners();
    }
  }

  void clear() {
    entriesVersion++;
    filteredVersion++;
    entries.clear();
    filtered.clear();
    filteredMarks.clear();
    notifyListeners();
  }

  /// Writes the raw text of all lines, or only the filtered ones, to [path]
  /// and returns how many lines were written. The output can be reopened
  /// with [openFile].
  Future<int> saveTo(String path, {bool filteredOnly = false}) async {
    // Snapshot first: a live source keeps appending while we write.
    final lines = filteredOnly
        ? [for (final i in filtered) entries[i].raw]
        : [for (final e in entries) e.raw];
    final sink = File(path).openWrite();
    try {
      const chunk = 4096;
      for (var i = 0; i < lines.length; i += chunk) {
        final end = i + chunk < lines.length ? i + chunk : lines.length;
        sink.write(lines.sublist(i, end).join('\n'));
        sink.write('\n');
        await sink.flush();
      }
    } finally {
      await sink.close();
    }
    return lines.length;
  }

  void _reset() {
    entriesVersion++;
    filteredVersion++;
    entries.clear();
    filtered.clear();
    filteredMarks.clear();
    _pending.clear();
    _processNames.clear();
    _unresolvedPids.clear();
    _unresolvable
      ..clear()
      ..add(0);
    _serial = null;
    _bootId = null;
    _resumeTimestamp = null;
    _resumeSkip = const {};
    _crashBaseline = null;
    _lastCrashEvent.clear();
    _rootFailed = false;
    status = null;
  }

  // ------------------------------------------------------------- ingestion

  void _startTimer() {
    _flushTimer?.cancel();
    _flushTimer =
        Timer.periodic(const Duration(milliseconds: 100), (_) => _flush());
  }

  void _stopTimer() {
    _flushTimer?.cancel();
    _flushTimer = null;
  }

  void _flush() {
    if (_pending.isEmpty) return;
    var learnedName = false;
    for (final line in _pending) {
      final entry = LogcatParser.parse(line, entries.length + 1);
      final hint = LogcatParser.processStartHint(entry);
      if (hint != null) {
        _processNames[hint.key] = hint.value;
        learnedName = true;
      }
      final pid = entry.pid;
      if (pid != null &&
          !_processNames.containsKey(pid) &&
          !_unresolvable.contains(pid)) {
        _unresolvedPids.add(pid);
      }
      entries.add(entry);
      if (sourceKind == SourceKind.device) _detectCrash(entry);
      _addIfMatches(entries.length - 1);
    }
    _pending.clear();
    if (learnedName && _rulesUseProcessName) _refilter();
    if (_unresolvedPids.isNotEmpty) unawaited(_refreshProcessNames());
    notifyListeners();
  }

  static final _anrProcess = RegExp(r'^ANR in (\S+)');
  static final _nativeProcess = RegExp(r'pid \d+ \(([^)]+)\)');

  void _detectCrash(LogEntry e) {
    CrashKind? kind;
    String? process;
    if (e.tag == 'AndroidRuntime' && e.message.startsWith('FATAL EXCEPTION')) {
      kind = CrashKind.java;
    } else if (e.tag == 'ActivityManager' && e.message.startsWith('ANR in ')) {
      kind = CrashKind.anr;
      process = _anrProcess.firstMatch(e.message)?.group(1);
    } else if (e.tag == 'libc' &&
        e.level == LogLevel.fatal &&
        e.message.startsWith('Fatal signal')) {
      kind = CrashKind.native;
      process = _nativeProcess.firstMatch(e.message)?.group(1);
    }
    if (kind == null) return;

    final baseline = _crashBaseline;
    final ts = e.timestamp;
    if (baseline != null && ts != null) {
      // Strip an optional year so both sides are `MM-DD hh:mm:ss`.
      final stamp = ts.length > 18 ? ts.substring(5) : ts;
      if (stamp.compareTo(baseline) < 0) return;
    }

    process ??= processNameOf(e) ?? '${e.pid}';
    final key = '${kind.name}/$process';
    final now = DateTime.now();
    final last = _lastCrashEvent[key];
    if (last != null && now.difference(last) < const Duration(seconds: 5)) {
      return;
    }
    _lastCrashEvent[key] = now;
    _emit(CrashEvent(sourceLabel, kind, process, e));
  }

  void _emit(LogEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  Future<void> _refreshProcessNames({bool force = false}) async {
    final serial = _serial;
    if (serial == null || _psRefreshing) return;
    final now = DateTime.now();
    if (!force && now.difference(_lastPsRefresh) < const Duration(seconds: 3)) {
      return;
    }
    _psRefreshing = true;
    _lastPsRefresh = now;
    final asked = {..._unresolvedPids};
    _unresolvedPids.clear();
    try {
      final names = await adb.processNames(serial);
      if (serial != _serial) return;
      _processNames.addAll(names);
      _unresolvable.addAll(asked.where((p) => !names.containsKey(p)));
      if (_rulesUseProcessName) _refilter();
      notifyListeners();
    } on AdbException {
      // Process names are best effort.
    } finally {
      _psRefreshing = false;
    }
  }

  @override
  void dispose() {
    _generation++;
    _stopTimer();
    _subscription?.cancel();
    _process?.kill();
    _events.close();
    super.dispose();
  }
}
