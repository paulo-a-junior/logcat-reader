import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../adb/adb_client.dart';
import '../../adb/device_selection.dart';
import '../l10n_helpers.dart';
import 'device_menu.dart';
import 'tool_helpers.dart';

enum _AppAction { launch, forceStop, clearData, saveApk, uninstall }

/// Installed packages of the selected device, with common package actions.
class AppsView extends StatefulWidget {
  const AppsView({super.key, required this.devices, required this.active});

  final DeviceSelection devices;

  /// Whether the view is visible; packages load lazily when it becomes so.
  final bool active;

  @override
  State<AppsView> createState() => _AppsViewState();
}

class _AppsViewState extends State<AppsView> {
  final _search = TextEditingController();
  List<DevicePackage> _packages = const [];
  String? _loadedFor;
  bool _loading = false;
  AdbException? _error;
  bool _showSystem = false;

  AdbClient get _adb => widget.devices.adb;

  @override
  void initState() {
    super.initState();
    widget.devices.addListener(_maybeLoad);
    _search.addListener(() => setState(() {}));
    _maybeLoad();
  }

  @override
  void didUpdateWidget(AppsView old) {
    super.didUpdateWidget(old);
    _maybeLoad();
  }

  @override
  void dispose() {
    widget.devices.removeListener(_maybeLoad);
    _search.dispose();
    super.dispose();
  }

  void _maybeLoad() {
    final serial = widget.devices.onlineSerial;
    if (widget.active && serial != null && serial != _loadedFor && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _load());
    }
  }

  Future<void> _load() async {
    final serial = widget.devices.onlineSerial;
    if (serial == null || _loading || !mounted) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final packages = await _adb.packages(serial);
      if (!mounted) return;
      setState(() {
        _packages = packages;
        _loadedFor = serial;
      });
    } on AdbException catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _loadedFor = serial;
        });
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _install(String serial) async {
    if (await installApkWithPicker(context, _adb, serial)) await _load();
  }

  Future<void> _onAction(
      String serial, DevicePackage p, _AppAction action) async {
    final l10n = context.l10n;
    switch (action) {
      case _AppAction.launch:
        await runDeviceTask(context, () => _adb.launch(serial, p.name),
            success: l10n.doneMessage(l10n.launchApp, p.name));
      case _AppAction.forceStop:
        await runDeviceTask(context, () => _adb.forceStop(serial, p.name),
            success: l10n.doneMessage(l10n.forceStop, p.name));
      case _AppAction.clearData:
        if (!await confirmAction(context,
            title: l10n.clearDataTitle(p.name),
            message: l10n.cannotUndo,
            action: l10n.clearData,
            destructive: true)) {
          return;
        }
        if (!mounted) return;
        await runDeviceTask(context, () => _adb.clearData(serial, p.name),
            success: l10n.doneMessage(l10n.clearData, p.name));
      case _AppAction.saveApk:
        final location = await getSaveLocation(suggestedName: '${p.name}.apk');
        if (location == null || !mounted) return;
        showToolMessage(context, l10n.transferring(p.name));
        await runDeviceTask(
            context, () => _adb.pull(serial, p.apkPath, location.path),
            success: l10n.pullDone(location.path));
      case _AppAction.uninstall:
        if (!await confirmAction(context,
            title: l10n.uninstallTitle(p.name),
            message: l10n.cannotUndo,
            action: l10n.uninstall,
            destructive: true)) {
          return;
        }
        if (!mounted) return;
        if (await runDeviceTask(context, () => _adb.uninstall(serial, p.name),
            success: l10n.doneMessage(l10n.uninstall, p.name))) {
          setState(() =>
              _packages = _packages.where((e) => e.name != p.name).toList());
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: widget.devices,
      builder: (context, _) {
        final serial = widget.devices.onlineSerial;
        if (serial == null) return const NoDevicePlaceholder();
        final query = _search.text.trim().toLowerCase();
        final visible = [
          for (final p in _packages)
            if ((_showSystem || !p.system) &&
                (query.isEmpty || p.name.toLowerCase().contains(query)))
              p
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Text(l10n.navApps, style: theme.textTheme.titleMedium),
                  const SizedBox(width: 16),
                  SizedBox(
                    width: 320,
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        isDense: true,
                        prefixIcon: const Icon(Icons.search),
                        hintText: l10n.searchPackages,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(l10n.showSystemApps),
                    selected: _showSystem,
                    onSelected: (v) => setState(() => _showSystem = v),
                  ),
                  const SizedBox(width: 12),
                  Text(l10n.packageCount(visible.length),
                      style: theme.textTheme.bodySmall),
                  const Spacer(),
                  IconButton(
                    tooltip: l10n.refresh,
                    onPressed: _loading ? null : _load,
                    icon: const Icon(Icons.refresh),
                  ),
                  const SizedBox(width: 4),
                  FilledButton.icon(
                    onPressed: () => _install(serial),
                    icon: const Icon(Icons.install_mobile),
                    label: Text(l10n.installApk),
                  ),
                ],
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            const Divider(height: 1),
            Expanded(
              child: _error != null
                  ? Center(child: Text(l10n.adbError(_error!)))
                  : ListView.builder(
                      itemCount: visible.length,
                      itemExtent: 52,
                      itemBuilder: (context, i) {
                        final p = visible[i];
                        return ListTile(
                          dense: true,
                          leading: Icon(p.system
                              ? Icons.settings_applications
                              : Icons.apps),
                          title: Text(p.name, overflow: TextOverflow.ellipsis),
                          subtitle: Text(
                            p.system
                                ? '${l10n.systemBadge} · ${p.apkPath}'
                                : p.apkPath,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          onTap: () => _onAction(serial, p, _AppAction.launch),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: l10n.launchApp,
                                onPressed: () =>
                                    _onAction(serial, p, _AppAction.launch),
                                icon: const Icon(Icons.play_arrow),
                              ),
                              IconButton(
                                tooltip: l10n.forceStop,
                                onPressed: () =>
                                    _onAction(serial, p, _AppAction.forceStop),
                                icon: const Icon(Icons.stop_circle_outlined),
                              ),
                              PopupMenuButton<_AppAction>(
                                onSelected: (a) => _onAction(serial, p, a),
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: _AppAction.clearData,
                                    child: Text(l10n.clearData),
                                  ),
                                  PopupMenuItem(
                                    value: _AppAction.saveApk,
                                    child: Text(l10n.saveApk),
                                  ),
                                  PopupMenuItem(
                                    value: _AppAction.uninstall,
                                    child: Text(l10n.uninstall),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}
