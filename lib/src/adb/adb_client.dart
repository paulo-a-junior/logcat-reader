import 'dart:async';
import 'dart:convert';
import 'dart:io';

class AdbDevice {
  const AdbDevice(this.serial, this.state, this.model);

  final String serial;
  final String state;
  final String model;

  bool get isOnline => state == 'device';

  String get label {
    final base = model.isEmpty ? serial : '$model ($serial)';
    return isOnline ? base : '$base [$state]';
  }
}

class AdbException implements Exception {
  AdbException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// The adb executable itself could not be launched.
class AdbNotFoundException extends AdbException {
  AdbNotFoundException(this.adbPath, String detail) : super(detail);
  final String adbPath;
  @override
  String toString() => message;
}

/// Reboot target for [AdbClient.reboot].
enum RebootMode { system, recovery, bootloader }

/// An installed package as reported by `pm list packages -f`.
class DevicePackage {
  const DevicePackage(this.name, this.apkPath, {required this.system});

  final String name;
  final String apkPath;
  final bool system;
}

/// One entry of a device directory listing.
class RemoteFile {
  const RemoteFile({
    required this.name,
    required this.isDirectory,
    required this.isLink,
    required this.size,
    required this.modified,
    this.linkTarget,
  });

  final String name;
  final bool isDirectory;
  final bool isLink;
  final int size;
  final String modified;
  final String? linkTarget;
}

/// Thin wrapper around the `adb` command line tool.
class AdbClient {
  AdbClient({String? adbPath})
      : adbPath = adbPath ?? Platform.environment['ADB'] ?? 'adb';

  final String adbPath;

  static const _codec = Utf8Codec(allowMalformed: true);

  Future<ProcessResult> _run(List<String> args) async {
    try {
      return await Process.run(adbPath, args,
          stdoutEncoding: _codec, stderrEncoding: _codec);
    } on ProcessException catch (e) {
      throw AdbNotFoundException(adbPath, e.message);
    }
  }

  Future<List<AdbDevice>> devices() async {
    final result = await _run(['devices', '-l']);
    if (result.exitCode != 0) {
      throw AdbException('adb devices failed: ${result.stderr}');
    }
    final devices = <AdbDevice>[];
    for (final line in LineSplitter.split(result.stdout as String)) {
      if (line.trim().isEmpty ||
          line.startsWith('List of devices') ||
          line.startsWith('*')) {
        continue;
      }
      final parts = line.trim().split(RegExp(r'\s+'));
      if (parts.length < 2) continue;
      final model = parts
          .skip(2)
          .firstWhere((p) => p.startsWith('model:'), orElse: () => '')
          .replaceFirst('model:', '');
      devices.add(AdbDevice(parts[0], parts[1], model));
    }
    return devices;
  }

  /// Runs `adb connect host[:port]` and returns adb's output.
  Future<String> connect(String address) async {
    final result = await _run(['connect', address]);
    final out = '${result.stdout}${result.stderr}'.trim();
    final lower = out.toLowerCase();
    if (result.exitCode != 0 ||
        lower.contains('failed') ||
        lower.contains('unable') ||
        lower.contains('cannot')) {
      throw AdbException(out.isEmpty ? 'adb connect failed' : out);
    }
    return out;
  }

  /// Returns a `pid -> process name` map from the device's `ps`.
  Future<Map<int, String>> processNames(String serial) async {
    var result =
        await _run(['-s', serial, 'shell', 'ps', '-A', '-o', 'PID,NAME']);
    var out = result.stdout as String;
    if (result.exitCode != 0 || !out.contains('PID')) {
      // Pre-Oreo toolbox ps.
      result = await _run(['-s', serial, 'shell', 'ps']);
      out = result.stdout as String;
    }
    final map = <int, String>{};
    final lines = LineSplitter.split(out).toList();
    if (lines.isEmpty) return map;
    final pidIdx = lines.first.trim().split(RegExp(r'\s+')).indexOf('PID');
    if (pidIdx < 0) return map;
    for (final line in lines.skip(1)) {
      final cols = line.trim().split(RegExp(r'\s+'));
      if (cols.length <= pidIdx + 1) continue;
      final pid = int.tryParse(cols[pidIdx]);
      if (pid != null) map[pid] = cols.last;
    }
    return map;
  }

  /// Runs `adb -s serial <args>` (or plain `adb <args>` if [serial] is null).
  Future<ProcessResult> run(String? serial, List<String> args) => _run([
        if (serial != null) ...['-s', serial],
        ...args
      ]);

  /// Starts `adb -s serial <args>`; the caller owns the process.
  Future<Process> start(String? serial, List<String> args) async {
    try {
      return await Process.start(adbPath, [
        if (serial != null) ...['-s', serial],
        ...args
      ]);
    } on ProcessException catch (e) {
      throw AdbNotFoundException(adbPath, e.message);
    }
  }

  /// Runs [command] in the device shell and returns stdout; throws on a
  /// non-zero exit status.
  Future<String> shell(String serial, String command) async {
    final result = await run(serial, ['shell', command]);
    final out = result.stdout as String;
    if (result.exitCode != 0) {
      final err = '${result.stderr}'.trim();
      throw AdbException(err.isNotEmpty ? err : out.trim());
    }
    return out;
  }

  Future<void> _checked(String? serial, List<String> args) async {
    final result = await run(serial, args);
    final out = '${result.stdout}${result.stderr}'
        .split('\n')
        .where((l) => !l.startsWith('Performing ') && l.trim().isNotEmpty)
        .join('\n')
        .trim();
    // `pm`/`adb install` report failures on stdout with exit code 0 on
    // older releases.
    if (result.exitCode != 0 || out.contains('Failure [')) {
      throw AdbException(out.isEmpty ? 'adb ${args.first} failed' : out);
    }
  }

  Future<void> reboot(String serial, RebootMode mode) => _checked(serial, [
        'reboot',
        if (mode != RebootMode.system) mode.name,
      ]);

  Future<void> install(String serial, String apkPath) =>
      _checked(serial, ['install', '-r', '-d', apkPath]);

  Future<void> uninstall(String serial, String package) =>
      _checked(serial, ['uninstall', package]);

  Future<List<DevicePackage>> packages(String serial) async {
    final all = await shell(serial, 'pm list packages -f');
    final thirdParty = (await shell(serial, 'pm list packages -3'))
        .split('\n')
        .map((l) => l.trim().replaceFirst('package:', ''))
        .toSet();
    final result = <DevicePackage>[];
    for (final raw in LineSplitter.split(all)) {
      final line = raw.trim();
      if (!line.startsWith('package:')) continue;
      // package:/data/app/~~x==/com.foo-y==/base.apk=com.foo
      final body = line.substring(8);
      final eq = body.lastIndexOf('=');
      if (eq < 0) continue;
      final name = body.substring(eq + 1);
      result.add(DevicePackage(name, body.substring(0, eq),
          system: !thirdParty.contains(name)));
    }
    result.sort((a, b) => a.name.compareTo(b.name));
    return result;
  }

  Future<void> launch(String serial, String package) => _checked(serial, [
        'shell',
        'monkey -p $package -c android.intent.category.LAUNCHER 1 '
            '>/dev/null 2>&1 || '
            'monkey -p $package -c android.intent.category.LEANBACK_LAUNCHER 1',
      ]);

  Future<void> forceStop(String serial, String package) =>
      shell(serial, 'am force-stop $package');

  Future<void> clearData(String serial, String package) =>
      _checked(serial, ['shell', 'pm clear $package']);

  static final _lsLine = RegExp(r'^([\-dlcbps])[rwxsStT\-]{9}\S*\s+\d+\s+\S+\s+'
      r'\S+\s+(\d+|\d+,\s*\d+)\s+(\d{4}-\d\d-\d\d \d\d:\d\d)\s(.*)$');

  /// Lists [dir] on the device (toybox `ls -la` format).
  Future<List<RemoteFile>> listDir(String serial, String dir) async {
    final result = await run(serial, ['shell', 'ls -la ${quote(dir)}/']);
    final out = result.stdout as String;
    final files = <RemoteFile>[];
    for (final line in LineSplitter.split(out)) {
      final m = _lsLine.firstMatch(line);
      if (m == null) continue;
      var name = m[4]!;
      String? target;
      final type = m[1]!;
      if (type == 'l') {
        final arrow = name.indexOf(' -> ');
        if (arrow >= 0) {
          target = name.substring(arrow + 4);
          name = name.substring(0, arrow);
        }
      }
      if (name == '.' || name == '..') continue;
      files.add(RemoteFile(
        name: name,
        isDirectory: type == 'd',
        isLink: type == 'l',
        size: int.tryParse(m[2]!) ?? 0,
        modified: m[3]!,
        linkTarget: target,
      ));
    }
    if (files.isEmpty && result.exitCode != 0) {
      final err = '${result.stderr}$out'.trim();
      throw AdbException(err.isEmpty ? 'ls failed' : err);
    }
    return files;
  }

  /// Whether [path] is a directory (following symlinks).
  Future<bool> isDirectory(String serial, String path) async {
    final result =
        await run(serial, ['shell', '[ -d ${quote(path)} ] && echo yes']);
    return (result.stdout as String).trim() == 'yes';
  }

  Future<void> pull(String serial, String remote, String local) =>
      _checked(serial, ['pull', remote, local]);

  Future<void> push(String serial, String local, String remote) =>
      _checked(serial, ['push', local, remote]);

  Future<void> mkdir(String serial, String path) =>
      _checked(serial, ['shell', 'mkdir -p ${quote(path)}']);

  Future<void> remove(String serial, String path) =>
      _checked(serial, ['shell', 'rm -rf ${quote(path)}']);

  /// Captures the screen as PNG bytes.
  Future<List<int>> screenshot(String serial) async {
    final ProcessResult result;
    try {
      result = await Process.run(
          adbPath, ['-s', serial, 'exec-out', 'screencap', '-p'],
          stdoutEncoding: null, stderrEncoding: _codec);
    } on ProcessException catch (e) {
      throw AdbNotFoundException(adbPath, e.message);
    }
    final bytes = result.stdout as List<int>;
    if (result.exitCode != 0 || bytes.length < 8) {
      throw AdbException('${result.stderr}'.trim().isEmpty
          ? 'screencap failed'
          : '${result.stderr}'.trim());
    }
    return bytes;
  }

  /// Single-quotes [s] for the device's POSIX shell.
  static String quote(String s) => "'${s.replaceAll("'", r"'\''")}'";

  Future<String> disconnect(String address) async {
    final result = await _run(['disconnect', address]);
    return '${result.stdout}${result.stderr}'.trim();
  }

  /// The kernel boot id; changes whenever the device reboots.
  Future<String?> bootId(String serial) async {
    final result = await _run(
        ['-s', serial, 'shell', 'cat', '/proc/sys/kernel/random/boot_id']);
    final out = (result.stdout as String).trim();
    return result.exitCode == 0 && out.isNotEmpty ? out : null;
  }

  /// Device wall clock in logcat's `MM-DD hh:mm:ss` format.
  Future<String?> deviceTime(String serial) async {
    final result =
        await _run(['-s', serial, 'shell', 'date', "+'%m-%d %H:%M:%S'"]);
    final out = (result.stdout as String).trim();
    return RegExp(r'^\d\d-\d\d \d\d:\d\d:\d\d$').hasMatch(out) ? out : null;
  }

  /// Starts `adb logcat -v threadtime`, optionally only from [since]
  /// (a logcat `MM-DD hh:mm:ss.mmm` timestamp). The caller owns the process.
  Future<Process> startLogcat(String serial, {String? since}) async {
    try {
      return await Process.start(adbPath, [
        '-s',
        serial,
        'logcat',
        '-v',
        'threadtime',
        if (since != null) ...['-T', since],
      ]);
    } on ProcessException catch (e) {
      throw AdbNotFoundException(adbPath, e.message);
    }
  }
}
