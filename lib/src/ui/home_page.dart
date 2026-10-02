import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../adb/device_selection.dart';
import '../controller/log_controller.dart';
import '../models/command_shortcut.dart';
import '../settings/app_settings.dart';
import '../settings/filter_store.dart';
import '../settings/shortcut_store.dart';
import '../tools/shell_console.dart';
import 'filters/filter_balloon_bar.dart';
import 'filters/filter_colors.dart';
import 'filters/filter_manager_page.dart';
import 'l10n_helpers.dart';
import 'log_table.dart';
import 'preferences_dialog.dart';
import 'save_log.dart';
import 'source_toolbar.dart';
import 'tools/apps_view.dart';
import 'tools/device_menu.dart';
import 'tools/files_view.dart';
import 'tools/shell_view.dart';
import 'tools/shortcut_bar.dart';
import 'tools/shortcut_runner.dart';
import 'tools/shortcuts_view.dart';

/// Top-level views selectable from the navigation rail.
enum AppView { logs, apps, files, shell, shortcuts }

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.controller,
    required this.settings,
    required this.filters,
    required this.devices,
    required this.console,
    required this.shortcuts,
  });

  final LogController controller;
  final AppSettings settings;
  final FilterStore filters;
  final DeviceSelection devices;
  final ShellConsole console;
  final ShortcutStore shortcuts;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _rawTable = LogTableController();
  final _filteredTable = LogTableController();
  late final StreamSubscription<LogEvent> _events;
  int? _selectedLine;
  AppView _view = AppView.logs;

  /// Fraction of the available height given to the raw table.
  double _split = 0.5;

  LogController get _c => widget.controller;
  AppSettings get _settings => widget.settings;

  @override
  void initState() {
    super.initState();
    _events = _c.events.listen(_notify);
  }

  @override
  void dispose() {
    _events.cancel();
    super.dispose();
  }

  void _show(AppView view) => setState(() => _view = view);

  void _runShortcut(CommandShortcut shortcut) => runShortcut(
        context,
        shortcut: shortcut,
        serial: widget.devices.onlineSerial,
        console: widget.console,
        showConsole: () => _show(AppView.shell),
      );

  void _revealInRaw(int lineNumber) {
    setState(() {
      _selectedLine = lineNumber;
      _view = AppView.logs;
    });
    // Line numbers are 1-based and contiguous within a session.
    _rawTable.revealIndex(lineNumber - 1);
  }

  void _openPreferences() => PreferencesDialog.show(context, _settings);

  void _saveLog() => saveLog(context, _c);

  void _notify(LogEvent event) {
    if (!mounted) return;
    final l10n = context.l10n;
    final colors = Theme.of(context).colorScheme;
    String? message;
    SnackBarAction? action;
    var error = false;
    var warning = false;

    switch (event) {
      case ConnectionLostEvent(:final source):
        if (!_settings.notifyConnectionLost) return;
        message = l10n.notifyConnectionLost(source);
        error = true;
      case ReconnectedEvent(:final source, :final rebooted):
        if (!_settings.notifyReconnected) return;
        message = rebooted
            ? l10n.notifyRebooted(source)
            : l10n.notifyReconnected(source);
      case CrashEvent(:final kind, :final process, :final entry):
        if (!_settings.notifyCrash) return;
        message = switch (kind) {
          CrashKind.java => l10n.notifyJavaCrash(process),
          CrashKind.anr => l10n.notifyAnr(process),
          CrashKind.native => l10n.notifyNativeCrash(process),
        };
        error = true;
        action = SnackBarAction(
          label: l10n.show,
          onPressed: () => _revealInRaw(entry.lineNumber),
        );
      case RootFailedEvent(:final source, message: final detail):
        message = l10n.notifyRootFailed(source, detail);
        error = true;
      case WideEncodingEvent(:final encoding):
        message = l10n.notifyWideEncoding(encoding);
        warning = true;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Row(
          children: [
            Icon(
                error
                    ? Icons.error_outline
                    : warning
                        ? Icons.warning_amber
                        : Icons.check_circle_outline,
                color: error
                    ? colors.onErrorContainer
                    : warning
                        ? colors.onTertiaryContainer
                        : null),
            const SizedBox(width: 12),
            Expanded(
                child: Text(message,
                    style: warning
                        ? TextStyle(color: colors.onTertiaryContainer)
                        : null)),
          ],
        ),
        backgroundColor: error
            ? colors.errorContainer
            : warning
                ? colors.tertiaryContainer
                : null,
        behavior: SnackBarBehavior.floating,
        width: 520,
        duration: Duration(seconds: action != null || warning ? 8 : 4),
        action: action,
      ));
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.comma, control: true):
            _openPreferences,
        const SingleActivator(LogicalKeyboardKey.comma, meta: true):
            _openPreferences,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _saveLog,
        const SingleActivator(LogicalKeyboardKey.keyS, meta: true): _saveLog,
        // A focused table opens its own find bar; otherwise use the raw one.
        const SingleActivator(LogicalKeyboardKey.keyF, control: true):
            _rawTable.openFind,
        const SingleActivator(LogicalKeyboardKey.keyF, meta: true):
            _rawTable.openFind,
      },
      child: Focus(
        autofocus: true,
        child: Scaffold(
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ListenableBuilder(
                listenable: _c,
                builder: (context, _) => SourceToolbar(
                  controller: _c,
                  devices: widget.devices,
                  onOpenPreferences: _openPreferences,
                  actions: [
                    ShortcutBar(
                      store: widget.shortcuts,
                      onRun: _runShortcut,
                      onManage: () => _show(AppView.shortcuts),
                    ),
                    DeviceMenu(devices: widget.devices),
                  ],
                ),
              ),
              const Divider(height: 1),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildRail(context),
                    const VerticalDivider(width: 1),
                    Expanded(
                      child: IndexedStack(
                        index: _view.index,
                        children: [
                          _buildLogs(context),
                          AppsView(
                            devices: widget.devices,
                            active: _view == AppView.apps,
                          ),
                          FilesView(
                            devices: widget.devices,
                            active: _view == AppView.files,
                          ),
                          ListenableBuilder(
                            listenable: _settings,
                            builder: (context, _) => ShellView(
                              console: widget.console,
                              devices: widget.devices,
                              fontSize: _settings.fontSize,
                            ),
                          ),
                          ShortcutsView(
                            store: widget.shortcuts,
                            onRun: _runShortcut,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRail(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: widget.console,
      builder: (context, _) => NavigationRail(
        selectedIndex: _view.index,
        onDestinationSelected: (i) => _show(AppView.values[i]),
        labelType: NavigationRailLabelType.all,
        minWidth: 64,
        destinations: [
          NavigationRailDestination(
            icon: const Icon(Icons.article_outlined),
            selectedIcon: const Icon(Icons.article),
            label: Text(l10n.navLogs),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.apps_outlined),
            selectedIcon: const Icon(Icons.apps),
            label: Text(l10n.navApps),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.folder_outlined),
            selectedIcon: const Icon(Icons.folder),
            label: Text(l10n.navFiles),
          ),
          NavigationRailDestination(
            icon: Badge(
              isLabelVisible: widget.console.anyRunning,
              child: const Icon(Icons.terminal),
            ),
            label: Text(l10n.navShell),
          ),
          NavigationRailDestination(
            icon: const Icon(Icons.bolt_outlined),
            selectedIcon: const Icon(Icons.bolt),
            label: Text(l10n.navShortcuts),
          ),
        ],
      ),
    );
  }

  Widget _buildLogs(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: Listenable.merge([_c, _settings]),
      builder: (context, _) {
        final wrap = _settings.longLineMode == LongLineMode.wrap;
        return LayoutBuilder(builder: (context, constraints) {
          final height = constraints.maxHeight;
          return Column(
            children: [
              SizedBox(
                height: (height * _split).clamp(80.0, height - 160),
                child: LogTable(
                  title: l10n.tableRaw,
                  controller: _rawTable,
                  contentVersion: _c.entriesVersion,
                  itemCount: _c.entries.length,
                  entryAt: (i) => _c.entries[i],
                  processLabel: _c.processLabel,
                  fontSize: _settings.fontSize,
                  wrap: wrap,
                  selectedLine: _selectedLine,
                  onRowTap: (e) => setState(() => _selectedLine = e.lineNumber),
                ),
              ),
              MouseRegion(
                cursor: SystemMouseCursors.resizeRow,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragUpdate: (d) => setState(() {
                    _split = (_split + d.delta.dy / height).clamp(0.1, 0.9);
                  }),
                  child: Container(
                    height: 6,
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              FilterBalloonBar(
                store: widget.filters,
                onManage: () => FilterManagerPage.open(context, widget.filters),
              ),
              Expanded(
                child: LogTable(
                  title: _c.hasActiveFilters
                      ? l10n.tableFiltered
                      : '${l10n.tableFiltered} — '
                          '${l10n.noActiveFilters}',
                  controller: _filteredTable,
                  contentVersion: _c.filteredVersion,
                  itemCount: _c.filtered.length,
                  entryAt: (i) => _c.entries[_c.filtered[i]],
                  markColorAt: (i) {
                    final mark = _c.filteredMarks[i];
                    return mark < 0
                        ? null
                        : filterColor(mark, Theme.of(context).brightness);
                  },
                  processLabel: _c.processLabel,
                  fontSize: _settings.fontSize,
                  wrap: wrap,
                  selectedLine: _selectedLine,
                  onRowTap: (e) => _revealInRaw(e.lineNumber),
                ),
              ),
            ],
          );
        });
      },
    );
  }
}
