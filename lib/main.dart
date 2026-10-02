import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/gen/app_localizations.dart';
import 'src/adb/device_selection.dart';
import 'src/controller/log_controller.dart';
import 'src/settings/app_settings.dart';
import 'src/settings/filter_store.dart';
import 'src/settings/shortcut_store.dart';
import 'src/tools/shell_console.dart';
import 'src/ui/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final settings = await AppSettings.load();
  final filters = await FilterStore.load();
  final shortcuts = await ShortcutStore.load();
  runApp(LogcatReaderApp(
    settings: settings,
    filters: filters,
    shortcuts: shortcuts,
  ));
}

class LogcatReaderApp extends StatefulWidget {
  const LogcatReaderApp({
    super.key,
    required this.settings,
    required this.filters,
    required this.shortcuts,
  });

  final AppSettings settings;
  final FilterStore filters;
  final ShortcutStore shortcuts;

  @override
  State<LogcatReaderApp> createState() => _LogcatReaderAppState();
}

class _LogcatReaderAppState extends State<LogcatReaderApp> {
  final _controller = LogController();
  late final _devices = DeviceSelection(_controller.adb);
  late final _console = ShellConsole(_controller.adb);

  AppSettings get _settings => widget.settings;
  FilterStore get _filters => widget.filters;

  @override
  void initState() {
    super.initState();
    _syncController();
    _settings.addListener(_syncController);
    _syncFilters();
    _filters.addListener(_syncFilters);
  }

  void _syncFilters() {
    _controller.setFilters(
      [
        for (final f in _filters.filters)
          if (f.enabled)
            FilterRule(
              criteria: f.criteria,
              exclude: f.exclude,
              mark: f.colorIndex,
            ),
      ],
      matchAll: _filters.combine == FilterCombine.all,
    );
  }

  void _syncController() {
    if (_controller.autoReconnect != _settings.autoReconnect) {
      _controller.autoReconnect = _settings.autoReconnect;
    }
    if (_controller.runAsRoot != _settings.adbRoot) {
      _controller.runAsRoot = _settings.adbRoot;
    }
    final adb = _controller.adb;
    if (adb.customPath != _settings.adbPath) {
      adb.customPath = _settings.adbPath;
      // The toolbar lists devices on startup; later changes need a reload.
      if (_started) _devices.refresh();
    }
    _started = true;
  }

  bool _started = false;

  @override
  void dispose() {
    _settings.removeListener(_syncController);
    _filters.removeListener(_syncFilters);
    _controller.dispose();
    _devices.dispose();
    _console.dispose();
    super.dispose();
  }

  ThemeData _theme(Brightness brightness) => ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: brightness,
        ),
        visualDensity: VisualDensity.compact,
      );

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _settings,
      builder: (context, _) => MaterialApp(
        onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
        debugShowCheckedModeBanner: false,
        theme: _theme(Brightness.light),
        darkTheme: _theme(Brightness.dark),
        themeMode: _settings.themeMode,
        locale: _settings.locale,
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: HomePage(
          controller: _controller,
          settings: _settings,
          filters: _filters,
          devices: _devices,
          console: _console,
          shortcuts: widget.shortcuts,
        ),
      ),
    );
  }
}
