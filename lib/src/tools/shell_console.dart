import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../adb/adb_client.dart';

/// One command run in the console and its combined output.
class ConsoleRun extends ChangeNotifier {
  ConsoleRun(this.title, this.target);

  /// What was run, as shown to the user.
  final String title;

  /// Device serial, or null for host commands.
  final String? target;
  final DateTime started = DateTime.now();

  final _output = StringBuffer();
  bool _truncated = false;
  int? exitCode;
  Process? _process;
  bool _stopped = false;

  static const _maxOutput = 2 * 1024 * 1024;

  String get output => _output.toString();
  bool get truncated => _truncated;
  bool get running => exitCode == null;
  bool get stopped => _stopped;

  void _append(String text) {
    if (_truncated) return;
    if (_output.length + text.length > _maxOutput) {
      _output.write(text.substring(0, _maxOutput - _output.length));
      _truncated = true;
    } else {
      _output.write(text);
    }
    notifyListeners();
  }

  void stop() {
    _stopped = true;
    _process?.kill();
  }
}

/// Runs adb and host commands, streaming their output, and keeps the
/// history of runs shown by the Shell view.
class ShellConsole extends ChangeNotifier {
  ShellConsole(this.adb);

  final AdbClient adb;
  final List<ConsoleRun> runs = [];

  /// Previously typed commands, most recent last.
  final List<String> history = [];

  static const _maxRuns = 200;
  static const _codec = Utf8Codec(allowMalformed: true);

  bool get anyRunning => runs.any((r) => r.running);

  void clear() {
    runs.removeWhere((r) => !r.running);
    notifyListeners();
  }

  void remember(String command) {
    history.remove(command);
    history.add(command);
    if (history.length > 100) history.removeAt(0);
  }

  /// `adb -s serial shell <command>`.
  Future<ConsoleRun> runShell(String serial, String command) => _start(
        ConsoleRun('\$ $command', serial),
        () => adb.start(serial, ['shell', command]),
      );

  /// `adb -s serial <args>`.
  Future<ConsoleRun> runAdb(String? serial, List<String> args) => _start(
        ConsoleRun('adb ${args.join(' ')}', serial),
        () => adb.start(serial, args),
      );

  /// A command on this computer, with `ANDROID_SERIAL` and `ADB` set so that
  /// scripts calling adb target the selected device.
  Future<ConsoleRun> runHost(String? serial, String command) => _start(
        ConsoleRun('> $command', null),
        () => Process.start(
          Platform.isWindows ? 'cmd' : '/bin/sh',
          Platform.isWindows ? ['/c', command] : ['-c', command],
          environment: {
            if (serial != null) 'ANDROID_SERIAL': serial,
            'ADB': adb.adbPath,
          },
        ),
      );

  Future<ConsoleRun> _start(
      ConsoleRun run, Future<Process> Function() spawn) async {
    runs.add(run);
    if (runs.length > _maxRuns) runs.removeAt(0);
    notifyListeners();
    try {
      final process = await spawn();
      run._process = process;
      if (run._stopped) process.kill();
      final done = [
        process.stdout.transform(_codec.decoder).listen(run._append).asFuture(),
        process.stderr.transform(_codec.decoder).listen(run._append).asFuture(),
      ];
      final code = await process.exitCode;
      await Future.wait(done).catchError((_) => const <void>[]);
      run.exitCode = code;
    } on Object catch (e) {
      run._append('$e\n');
      run.exitCode = -1;
    }
    run._process = null;
    run.notifyListeners();
    notifyListeners();
    return run;
  }
}

/// Splits a command line into arguments, honouring single and double quotes
/// and backslash escapes (outside single quotes).
List<String> splitArgs(String line) {
  final args = <String>[];
  final current = StringBuffer();
  var inArg = false;
  String? quote;
  for (var i = 0; i < line.length; i++) {
    final c = line[i];
    if (quote != null) {
      if (c == quote) {
        quote = null;
      } else if (c == r'\' && quote == '"' && i + 1 < line.length) {
        current.write(line[++i]);
      } else {
        current.write(c);
      }
    } else if (c == '"' || c == "'") {
      quote = c;
      inArg = true;
    } else if (c == r'\' && i + 1 < line.length) {
      current.write(line[++i]);
      inArg = true;
    } else if (c.trim().isEmpty) {
      if (inArg) {
        args.add(current.toString());
        current.clear();
        inArg = false;
      }
    } else {
      current.write(c);
      inArg = true;
    }
  }
  if (inArg) args.add(current.toString());
  return args;
}
