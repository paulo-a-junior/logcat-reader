import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../adb/adb_client.dart';
import '../adb/device_selection.dart';
import '../controller/log_controller.dart';
import 'l10n_helpers.dart';

/// Source selection: adb device (USB or TCP/IP) or an offline log file.
class SourceToolbar extends StatefulWidget {
  const SourceToolbar({
    super.key,
    required this.controller,
    required this.devices,
    required this.onOpenPreferences,
    this.actions = const [],
  });

  final LogController controller;
  final DeviceSelection devices;
  final VoidCallback onOpenPreferences;

  /// Extra widgets shown before the preferences button.
  final List<Widget> actions;

  @override
  State<SourceToolbar> createState() => _SourceToolbarState();
}

class _SourceToolbarState extends State<SourceToolbar> {
  LogController get _c => widget.controller;
  DeviceSelection get _d => widget.devices;

  @override
  void initState() {
    super.initState();
    _d.refresh();
  }

  Future<void> _connectByIp() async {
    final address = await showDialog<String>(
      context: context,
      builder: (context) => const _ConnectDialog(),
    );
    if (address == null || address.isEmpty || !mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final out = await _c.adb.connect(address);
      messenger.showSnackBar(SnackBar(content: Text(out)));
      await _d.refresh();
      final serial = address.contains(':') ? address : '$address:5555';
      if (_d.devices.any((d) => d.serial == serial)) {
        _d.selectedSerial = serial;
      }
    } on AdbException catch (e) {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(content: Text(context.l10n.adbError(e))));
    }
  }

  Future<void> _openFile() async {
    final l10n = context.l10n;
    final file = await openFile(acceptedTypeGroups: [
      XTypeGroup(
          label: l10n.fileTypeLogs, extensions: const ['txt', 'log', 'logcat']),
      XTypeGroup(label: l10n.fileTypeAll),
    ]);
    if (file != null) await _c.openFile(file.path);
  }

  void _start() {
    final device = _d.selected;
    if (device == null) return;
    _c.startDevice(device.serial, label: device.label);
  }

  @override
  Widget build(BuildContext context) =>
      ListenableBuilder(listenable: _d, builder: (context, _) => _build());

  Widget _build() {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final status = _c.status;
    final streaming = _c.active && _c.sourceKind == SourceKind.device;
    final selected = _d.selected;
    final deviceError = _d.error;
    final devices = _d.devices;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          const Icon(Icons.phone_android, size: 20),
          const SizedBox(width: 8),
          SizedBox(
            width: 320,
            child: DropdownButton<String>(
              isExpanded: true,
              value: selected?.serial,
              hint: Text(
                deviceError != null
                    ? l10n.adbError(deviceError)
                    : devices.isEmpty
                        ? l10n.noDevicesFound
                        : l10n.selectDevice,
                overflow: TextOverflow.ellipsis,
              ),
              items: [
                for (final d in devices)
                  DropdownMenuItem(
                    value: d.serial,
                    enabled: d.isOnline,
                    child: Text(d.label, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged:
                  streaming ? null : (serial) => _d.selectedSerial = serial,
            ),
          ),
          IconButton(
            tooltip: l10n.refreshDevices,
            onPressed: _d.loading ? null : _d.refresh,
            icon: _d.loading
                ? const SizedBox.square(
                    dimension: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: l10n.connectViaIp,
            onPressed: _connectByIp,
            icon: const Icon(Icons.wifi),
          ),
          const SizedBox(width: 4),
          if (streaming)
            FilledButton.tonalIcon(
              onPressed: _c.stop,
              icon: const Icon(Icons.stop),
              label: Text(l10n.stop),
            )
          else
            FilledButton.icon(
              onPressed: selected?.isOnline == true ? _start : null,
              icon: const Icon(Icons.play_arrow),
              label: Text(l10n.startLogcat),
            ),
          const SizedBox(width: 8),
          OutlinedButton.icon(
            onPressed: _openFile,
            icon: const Icon(Icons.folder_open),
            label: Text(l10n.openFile),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: l10n.clearLogs,
            onPressed: _c.entries.isEmpty ? null : _c.clear,
            icon: const Icon(Icons.delete_sweep),
          ),
          const SizedBox(width: 12),
          if (_c.reconnecting) ...[
            const SizedBox.square(
                dimension: 14,
                child: CircularProgressIndicator(strokeWidth: 2)),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              status == null ? '' : l10n.status(status),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodySmall,
            ),
          ),
          ...widget.actions,
          IconButton(
            tooltip: l10n.preferences,
            onPressed: widget.onOpenPreferences,
            icon: const Icon(Icons.settings),
          ),
        ],
      ),
    );
  }
}

class _ConnectDialog extends StatefulWidget {
  const _ConnectDialog();

  @override
  State<_ConnectDialog> createState() => _ConnectDialogState();
}

class _ConnectDialogState extends State<_ConnectDialog> {
  final _address = TextEditingController();

  @override
  void dispose() {
    _address.dispose();
    super.dispose();
  }

  void _submit() => Navigator.pop(context, _address.text.trim());

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(context.l10n.connectDialogTitle),
      content: SizedBox(
        width: 320,
        child: TextField(
          controller: _address,
          autofocus: true,
          decoration: InputDecoration(
            labelText: context.l10n.address,
            hintText: '192.168.1.10:5555',
          ),
          onSubmitted: (_) => _submit(),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.cancel)),
        FilledButton(onPressed: _submit, child: Text(context.l10n.connect)),
      ],
    );
  }
}
