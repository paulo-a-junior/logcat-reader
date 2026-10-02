import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../controller/log_controller.dart';
import 'l10n_helpers.dart';

/// Asks for a destination and writes the raw lines (all, or only the
/// filtered ones) of [controller] there, reporting the result in a SnackBar.
Future<void> saveLog(
  BuildContext context,
  LogController controller, {
  bool filteredOnly = false,
}) async {
  final l10n = context.l10n;
  final messenger = ScaffoldMessenger.of(context);
  if ((filteredOnly ? controller.filtered : controller.entries).isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(l10n.saveLogEmpty)));
    return;
  }
  final location = await getSaveLocation(
    suggestedName: _suggestedName(controller, filteredOnly),
    acceptedTypeGroups: [
      XTypeGroup(
          label: l10n.fileTypeLogs, extensions: const ['txt', 'log', 'logcat']),
      XTypeGroup(label: l10n.fileTypeAll),
    ],
  );
  if (location == null) return;
  try {
    final count =
        await controller.saveTo(location.path, filteredOnly: filteredOnly);
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.saveLogDone(count, location.path))));
  } catch (e) {
    messenger.showSnackBar(
        SnackBar(content: Text(l10n.saveLogFailed(location.path, '$e'))));
  }
}

String _suggestedName(LogController c, bool filteredOnly) {
  String two(int v) => v.toString().padLeft(2, '0');
  final now = DateTime.now();
  final stamp = '${now.year}${two(now.month)}${two(now.day)}-'
      '${two(now.hour)}${two(now.minute)}${two(now.second)}';
  var source = switch (c.sourceKind) {
    SourceKind.device => c.sourceLabel,
    SourceKind.file => c.sourceLabel
        .split(RegExp(r'[\\/]'))
        .last
        .replaceAll(RegExp(r'\.(txt|log|logcat)$', caseSensitive: false), ''),
    SourceKind.none => '',
  };
  source = source
      .replaceAll(RegExp(r'[^A-Za-z0-9._-]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
  final name = [
    'logcat',
    if (source.isNotEmpty) source,
    if (filteredOnly) 'filtered',
    stamp,
  ].join('-');
  return '$name.txt';
}
