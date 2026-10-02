import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../adb/adb_client.dart';
import '../../adb/device_selection.dart';
import '../l10n_helpers.dart';
import 'tool_helpers.dart';

enum _DeviceAction { install, screenshot, reboot, recovery, bootloader }

/// Toolbar menu with device-wide operations for the selected device.
class DeviceMenu extends StatelessWidget {
  const DeviceMenu({super.key, required this.devices});

  final DeviceSelection devices;

  AdbClient get _adb => devices.adb;

  Future<void> _onSelected(BuildContext context, _DeviceAction action) async {
    final device = devices.selected;
    if (device == null || !device.isOnline) return;
    final serial = device.serial;
    final l10n = context.l10n;
    switch (action) {
      case _DeviceAction.install:
        await installApkWithPicker(context, _adb, serial);
      case _DeviceAction.screenshot:
        await _screenshot(context, serial);
      case _DeviceAction.reboot ||
            _DeviceAction.recovery ||
            _DeviceAction.bootloader:
        final (mode, label) = switch (action) {
          _DeviceAction.recovery => (RebootMode.recovery, l10n.rebootRecovery),
          _DeviceAction.bootloader => (
              RebootMode.bootloader,
              l10n.rebootBootloader
            ),
          _ => (RebootMode.system, l10n.reboot),
        };
        if (!await confirmAction(
          context,
          title: l10n.rebootConfirmTitle,
          message: l10n.rebootConfirm(device.label, label),
          action: label,
          destructive: true,
        )) {
          return;
        }
        if (!context.mounted) return;
        await runDeviceTask(context, () => _adb.reboot(serial, mode),
            success: l10n.rebootSent(device.label));
    }
  }

  Future<void> _screenshot(BuildContext context, String serial) async {
    final l10n = context.l10n;
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .substring(0, 19);
    final location = await getSaveLocation(
      suggestedName: 'screenshot-$stamp.png',
      acceptedTypeGroups: [
        XTypeGroup(label: l10n.fileTypePng, extensions: const ['png']),
      ],
    );
    if (location == null || !context.mounted) return;
    await runDeviceTask(context, () async {
      final bytes = await _adb.screenshot(serial);
      try {
        await File(location.path).writeAsBytes(bytes);
      } on FileSystemException catch (e) {
        throw AdbException(e.toString());
      }
    }, success: l10n.screenshotSaved(location.path));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: devices,
      builder: (context, _) => PopupMenuButton<_DeviceAction>(
        tooltip: l10n.deviceMenu,
        enabled: devices.onlineSerial != null,
        icon: const Icon(Icons.developer_mode),
        onSelected: (a) => _onSelected(context, a),
        itemBuilder: (context) => [
          PopupMenuItem(
            value: _DeviceAction.install,
            child: ListTile(
              leading: const Icon(Icons.install_mobile),
              title: Text(l10n.installApk),
            ),
          ),
          PopupMenuItem(
            value: _DeviceAction.screenshot,
            child: ListTile(
              leading: const Icon(Icons.screenshot_monitor),
              title: Text(l10n.takeScreenshot),
            ),
          ),
          const PopupMenuDivider(),
          PopupMenuItem(
            value: _DeviceAction.reboot,
            child: ListTile(
              leading: const Icon(Icons.restart_alt),
              title: Text(l10n.reboot),
            ),
          ),
          PopupMenuItem(
            value: _DeviceAction.recovery,
            child: ListTile(
              leading: const Icon(Icons.healing),
              title: Text(l10n.rebootRecovery),
            ),
          ),
          PopupMenuItem(
            value: _DeviceAction.bootloader,
            child: ListTile(
              leading: const Icon(Icons.memory),
              title: Text(l10n.rebootBootloader),
            ),
          ),
        ],
      ),
    );
  }
}

/// Lets the user pick one or more APKs and installs them on [serial].
/// Returns true if at least one install succeeded.
Future<bool> installApkWithPicker(
    BuildContext context, AdbClient adb, String serial) async {
  final l10n = context.l10n;
  final files = await openFiles(acceptedTypeGroups: [
    XTypeGroup(label: l10n.fileTypeApk, extensions: const ['apk']),
  ]);
  var any = false;
  for (final file in files) {
    if (!context.mounted) break;
    showToolMessage(context, l10n.installing(file.name));
    any |= await runDeviceTask(context, () => adb.install(serial, file.path),
        success: l10n.installed(file.name));
  }
  return any;
}
