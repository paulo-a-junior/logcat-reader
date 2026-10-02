import 'package:flutter/material.dart';

import '../../adb/adb_client.dart';
import '../l10n_helpers.dart';

/// Shown by device views while no online device is selected.
class NoDevicePlaceholder extends StatelessWidget {
  const NoDevicePlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.phonelink_off, size: 48, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(context.l10n.noDeviceSelected, style: theme.textTheme.bodyLarge),
        ],
      ),
    );
  }
}

/// Floating SnackBar used for the result of device operations.
void showToolMessage(BuildContext context, String message,
    {bool error = false, SnackBarAction? action}) {
  final colors = Theme.of(context).colorScheme;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message,
          style: error ? TextStyle(color: colors.onErrorContainer) : null),
      backgroundColor: error ? colors.errorContainer : null,
      behavior: SnackBarBehavior.floating,
      width: 560,
      duration: Duration(seconds: error || action != null ? 8 : 4),
      action: action,
    ));
}

/// Asks the user to confirm an action; returns true if confirmed.
Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async {
  final colors = Theme.of(context).colorScheme;
  final ok = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(context.l10n.cancel),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: colors.error,
                  foregroundColor: colors.onError)
              : null,
          autofocus: true,
          onPressed: () => Navigator.pop(context, true),
          child: Text(action),
        ),
      ],
    ),
  );
  return ok ?? false;
}

/// Runs [task], showing [success] or the adb error as a SnackBar.
Future<bool> runDeviceTask(
  BuildContext context,
  Future<void> Function() task, {
  String? success,
}) async {
  try {
    await task();
    if (context.mounted && success != null) showToolMessage(context, success);
    return true;
  } on AdbException catch (e) {
    if (context.mounted) {
      showToolMessage(context, context.l10n.adbError(e), error: true);
    }
    return false;
  }
}

/// Human readable byte size.
String formatBytes(int bytes) {
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var size = bytes.toDouble();
  var unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit++;
  }
  return unit == 0
      ? '$bytes B'
      : '${size.toStringAsFixed(size < 10 ? 1 : 0)} ${units[unit]}';
}
