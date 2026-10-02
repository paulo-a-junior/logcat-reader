import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../../adb/adb_client.dart';
import '../../adb/device_selection.dart';
import '../l10n_helpers.dart';
import 'tool_helpers.dart';

/// Browser for the selected device's file system with pull/push.
class FilesView extends StatefulWidget {
  const FilesView({super.key, required this.devices, required this.active});

  final DeviceSelection devices;
  final bool active;

  @override
  State<FilesView> createState() => _FilesViewState();
}

class _FilesViewState extends State<FilesView> {
  static const _home = '/sdcard';

  final _pathField = TextEditingController(text: _home);
  String _path = _home;
  List<RemoteFile> _files = const [];
  String? _loadedFor;
  bool _loading = false;
  AdbException? _error;
  String? _selected;

  AdbClient get _adb => widget.devices.adb;

  @override
  void initState() {
    super.initState();
    widget.devices.addListener(_maybeLoad);
    _maybeLoad();
  }

  @override
  void didUpdateWidget(FilesView old) {
    super.didUpdateWidget(old);
    _maybeLoad();
  }

  @override
  void dispose() {
    widget.devices.removeListener(_maybeLoad);
    _pathField.dispose();
    super.dispose();
  }

  void _maybeLoad() {
    final serial = widget.devices.onlineSerial;
    if (widget.active && serial != null && serial != _loadedFor && !_loading) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _open(_path));
    }
  }

  String _join(String dir, String name) =>
      dir.endsWith('/') ? '$dir$name' : '$dir/$name';

  String _parent(String path) {
    if (path == '/' || !path.contains('/')) return '/';
    final trimmed =
        path.endsWith('/') ? path.substring(0, path.length - 1) : path;
    final i = trimmed.lastIndexOf('/');
    return i <= 0 ? '/' : trimmed.substring(0, i);
  }

  Future<void> _open(String path) async {
    final serial = widget.devices.onlineSerial;
    if (serial == null || !mounted) return;
    path = path.trim().isEmpty ? '/' : path.trim();
    if (path.length > 1 && path.endsWith('/')) {
      path = path.substring(0, path.length - 1);
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final files = await _adb.listDir(serial, path);
      files.sort((a, b) {
        final ad = a.isDirectory || a.isLink, bd = b.isDirectory || b.isLink;
        if (ad != bd) return ad ? -1 : 1;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      if (!mounted) return;
      setState(() {
        _files = files;
        _path = path;
        _pathField.text = path;
        _selected = null;
      });
    } on AdbException catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadedFor = serial;
        });
      }
    }
  }

  Future<void> _activate(String serial, RemoteFile f) async {
    final path = _join(_path, f.name);
    if (f.isDirectory || (f.isLink && await _adb.isDirectory(serial, path))) {
      await _open(path);
    } else {
      await _pull(serial, f);
    }
  }

  Future<void> _pull(String serial, RemoteFile f) async {
    final l10n = context.l10n;
    final remote = _join(_path, f.name);
    final String? local;
    if (f.isDirectory) {
      final dir = await getDirectoryPath();
      local = dir;
    } else {
      local = (await getSaveLocation(suggestedName: f.name))?.path;
    }
    if (local == null || !mounted) return;
    showToolMessage(context, l10n.transferring(f.name));
    await runDeviceTask(context, () => _adb.pull(serial, remote, local!),
        success: l10n.pullDone(local));
  }

  Future<void> _push(String serial) async {
    final l10n = context.l10n;
    final files = await openFiles();
    if (files.isEmpty || !mounted) return;
    var sent = 0;
    for (final f in files) {
      if (!mounted) return;
      showToolMessage(context, l10n.transferring(f.name));
      if (await runDeviceTask(
          context, () => _adb.push(serial, f.path, '$_path/'))) {
        sent++;
      }
    }
    if (!mounted) return;
    if (sent > 0) showToolMessage(context, l10n.pushDone(sent, _path));
    await _open(_path);
  }

  Future<void> _newFolder(String serial) async {
    final l10n = context.l10n;
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.newFolder),
        content: SizedBox(
          width: 360,
          child: TextField(
            controller: controller,
            autofocus: true,
            decoration: InputDecoration(labelText: l10n.folderName),
            onSubmitted: (v) => Navigator.pop(context, v.trim()),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: Text(l10n.create)),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.isEmpty || !mounted) return;
    if (await runDeviceTask(
        context, () => _adb.mkdir(serial, _join(_path, name)))) {
      await _open(_path);
    }
  }

  Future<void> _delete(String serial, RemoteFile f) async {
    final l10n = context.l10n;
    final path = _join(_path, f.name);
    if (!await confirmAction(context,
        title: l10n.deleteFileTitle(f.name),
        message: '$path\n\n${l10n.cannotUndo}',
        action: l10n.delete,
        destructive: true)) {
      return;
    }
    if (!mounted) return;
    if (await runDeviceTask(context, () => _adb.remove(serial, path))) {
      await _open(_path);
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
        final selected = _files.where((f) => f.name == _selected).firstOrNull;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
              child: Row(
                children: [
                  Text(l10n.navFiles, style: theme.textTheme.titleMedium),
                  const SizedBox(width: 12),
                  IconButton(
                    tooltip: l10n.goUp,
                    onPressed:
                        _path == '/' ? null : () => _open(_parent(_path)),
                    icon: const Icon(Icons.arrow_upward),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _pathField,
                      style: const TextStyle(fontFamily: 'monospace'),
                      decoration: InputDecoration(
                        isDense: true,
                        labelText: l10n.path,
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: _open,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.refresh,
                    onPressed: _loading ? null : () => _open(_path),
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton(
                    tooltip: l10n.newFolder,
                    onPressed: () => _newFolder(serial),
                    icon: const Icon(Icons.create_new_folder_outlined),
                  ),
                  const SizedBox(width: 4),
                  OutlinedButton.icon(
                    onPressed:
                        selected == null ? null : () => _pull(serial, selected),
                    icon: const Icon(Icons.download),
                    label: Text(l10n.pull),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: () => _push(serial),
                    icon: const Icon(Icons.upload),
                    label: Text(l10n.pushFiles),
                  ),
                ],
              ),
            ),
            if (_loading) const LinearProgressIndicator(minHeight: 2),
            const Divider(height: 1),
            _HeaderRow(theme: theme),
            const Divider(height: 1),
            Expanded(
              child: _error != null
                  ? Center(child: Text(l10n.adbError(_error!)))
                  : _files.isEmpty && !_loading
                      ? Center(child: Text(l10n.emptyFolder))
                      : ListView.builder(
                          itemCount: _files.length,
                          itemExtent: 36,
                          itemBuilder: (context, i) {
                            final f = _files[i];
                            final isSelected = f.name == _selected;
                            return _FileRow(
                              file: f,
                              selected: isSelected,
                              onTap: () => setState(() => _selected = f.name),
                              onOpen: () => _activate(serial, f),
                              onPull: () => _pull(serial, f),
                              onDelete: () => _delete(serial, f),
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

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final style = theme.textTheme.labelMedium;
    return Container(
      color: theme.colorScheme.surfaceContainerHighest,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 32),
          Expanded(child: Text(l10n.columnName, style: style)),
          SizedBox(
              width: 100,
              child: Text(l10n.columnSize,
                  style: style, textAlign: TextAlign.end)),
          const SizedBox(width: 24),
          SizedBox(width: 140, child: Text(l10n.columnModified, style: style)),
          const SizedBox(width: 40),
        ],
      ),
    );
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({
    required this.file,
    required this.selected,
    required this.onTap,
    required this.onOpen,
    required this.onPull,
    required this.onDelete,
  });

  final RemoteFile file;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onOpen;
  final VoidCallback onPull;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final f = file;
    final icon = f.isDirectory
        ? Icons.folder
        : f.isLink
            ? Icons.link
            : Icons.insert_drive_file_outlined;
    return Material(
      color: selected ? theme.colorScheme.secondaryContainer : null,
      child: InkWell(
        onTap: onTap,
        onDoubleTap: onOpen,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Icon(icon,
                  size: 20,
                  color: f.isDirectory ? theme.colorScheme.primary : null),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  f.linkTarget == null ? f.name : '${f.name} → ${f.linkTarget}',
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(
                width: 100,
                child: Text(f.isDirectory ? '' : formatBytes(f.size),
                    textAlign: TextAlign.end, style: theme.textTheme.bodySmall),
              ),
              const SizedBox(width: 24),
              SizedBox(
                  width: 140,
                  child: Text(f.modified, style: theme.textTheme.bodySmall)),
              SizedBox(
                width: 40,
                child: PopupMenuButton<VoidCallback>(
                  iconSize: 18,
                  onSelected: (action) => action(),
                  itemBuilder: (context) => [
                    if (f.isDirectory || f.isLink)
                      PopupMenuItem(value: onOpen, child: Text(l10n.openFile)),
                    PopupMenuItem(value: onPull, child: Text(l10n.pull)),
                    PopupMenuItem(value: onDelete, child: Text(l10n.delete)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
