import 'package:flutter/material.dart';

import '../../models/command_shortcut.dart';
import '../../tools/shell_console.dart';
import '../l10n_helpers.dart';
import 'tool_helpers.dart';

/// Runs [shortcut] against [serial] through [console] and reports the
/// outcome according to the shortcut's output setting.
Future<void> runShortcut(
  BuildContext context, {
  required CommandShortcut shortcut,
  required String? serial,
  required ShellConsole console,
  required VoidCallback showConsole,
}) async {
  final l10n = context.l10n;
  if (shortcut.kind != ShortcutKind.host && serial == null) {
    showToolMessage(context, l10n.shortcutNeedsDevice(shortcut.name),
        error: true);
    return;
  }
  if (shortcut.confirm &&
      !await confirmAction(
        context,
        title: l10n.runShortcutTitle(shortcut.name),
        message: shortcut.command,
        action: l10n.run,
      )) {
    return;
  }
  final toConsole = shortcut.output == ShortcutOutput.console;
  if (toConsole) showConsole();
  final run = await switch (shortcut.kind) {
    ShortcutKind.shell => console.runShell(serial!, shortcut.command),
    ShortcutKind.adb => console.runAdb(serial, splitArgs(shortcut.command)),
    ShortcutKind.host => console.runHost(serial, shortcut.command),
  };
  if (toConsole || !context.mounted || run.stopped) return;
  final failed = run.exitCode != 0;
  final out = run.output.trim();
  final firstLines = out.split('\n').take(3).join('\n');
  final title = failed
      ? l10n.shortcutFailed(shortcut.name, run.exitCode ?? -1)
      : l10n.shortcutDone(shortcut.name);
  showToolMessage(
    context,
    out.isEmpty ? title : '$title\n$firstLines',
    error: failed,
    action: out.isEmpty
        ? null
        : SnackBarAction(label: l10n.show, onPressed: showConsole),
  );
}
