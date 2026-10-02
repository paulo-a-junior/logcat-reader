import 'dart:async';
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/material.dart';

import '../adb/adb_client.dart';
import '../settings/app_settings.dart';
import 'l10n_helpers.dart';

class PreferencesDialog extends StatelessWidget {
  const PreferencesDialog({super.key, required this.settings});

  final AppSettings settings;

  static Future<void> show(BuildContext context, AppSettings settings) =>
      showDialog<void>(
        context: context,
        builder: (_) => PreferencesDialog(settings: settings),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(l10n.preferences),
      content: SizedBox(
        width: 520,
        child: ListenableBuilder(
          listenable: settings,
          builder: (context, _) => SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Section(l10n.sectionDevice),
                _AdbPathField(settings: settings),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.adbRoot),
                  subtitle: Text(l10n.adbRootSubtitle),
                  value: settings.adbRoot,
                  onChanged: (v) => settings.adbRoot = v,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.autoReconnect),
                  subtitle: Text(l10n.autoReconnectSubtitle),
                  value: settings.autoReconnect,
                  onChanged: (v) => settings.autoReconnect = v,
                ),
                _Section(l10n.sectionDisplay),
                _Row(
                  label: l10n.theme,
                  child: SegmentedButton<ThemeMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                          value: ThemeMode.system,
                          icon: const Icon(Icons.brightness_auto),
                          label: Text(l10n.themeSystem)),
                      ButtonSegment(
                          value: ThemeMode.light,
                          icon: const Icon(Icons.light_mode),
                          label: Text(l10n.themeLight)),
                      ButtonSegment(
                          value: ThemeMode.dark,
                          icon: const Icon(Icons.dark_mode),
                          label: Text(l10n.themeDark)),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) => settings.themeMode = s.single,
                  ),
                ),
                _Row(
                  label: l10n.longLines,
                  child: SegmentedButton<LongLineMode>(
                    showSelectedIcon: false,
                    segments: [
                      ButtonSegment(
                          value: LongLineMode.ellipsis,
                          icon: const Icon(Icons.short_text),
                          label: Text(l10n.longLinesEllipsis)),
                      ButtonSegment(
                          value: LongLineMode.wrap,
                          icon: const Icon(Icons.wrap_text),
                          label: Text(l10n.longLinesWrap)),
                    ],
                    selected: {settings.longLineMode},
                    onSelectionChanged: (s) => settings.longLineMode = s.single,
                  ),
                ),
                _Row(
                  label: l10n.fontSize,
                  child: SizedBox(
                    width: 260,
                    child: Row(
                      children: [
                        Expanded(
                          child: Slider(
                            min: AppSettings.minFontSize,
                            max: AppSettings.maxFontSize,
                            divisions: ((AppSettings.maxFontSize -
                                        AppSettings.minFontSize) *
                                    2)
                                .round(),
                            value: settings.fontSize,
                            label: settings.fontSize.toStringAsFixed(1),
                            onChanged: (v) => settings.fontSize = v,
                          ),
                        ),
                        SizedBox(
                          width: 36,
                          child: Text(settings.fontSize.toStringAsFixed(1),
                              textAlign: TextAlign.end),
                        ),
                      ],
                    ),
                  ),
                ),
                _Row(
                  label: l10n.language,
                  child: DropdownButton<String?>(
                    value: settings.language,
                    items: [
                      DropdownMenuItem(
                          value: null, child: Text(l10n.languageSystem)),
                      for (final code in AppSettings.supportedLanguages)
                        DropdownMenuItem(
                          value: code,
                          child: Text(LocalizedStrings.languageName(code)),
                        ),
                    ],
                    onChanged: (v) => settings.language = v,
                  ),
                ),
                _Section(l10n.sectionNotifications),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.notifyOnConnectionLost),
                  value: settings.notifyConnectionLost,
                  onChanged: (v) => settings.notifyConnectionLost = v,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.notifyOnReconnected),
                  value: settings.notifyReconnected,
                  onChanged: (v) => settings.notifyReconnected = v,
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n.notifyOnCrash),
                  subtitle: Text(l10n.notifyOnCrashSubtitle),
                  value: settings.notifyCrash,
                  onChanged: (v) => settings.notifyCrash = v,
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: settings.resetToDefaults,
          child: Text(l10n.resetDefaults),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Text(title,
          style: theme.textTheme.titleSmall
              ?.copyWith(color: theme.colorScheme.primary)),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          child,
        ],
      ),
    );
  }
}

/// Path to the adb executable, with browse, reset and a version check.
class _AdbPathField extends StatefulWidget {
  const _AdbPathField({required this.settings});

  final AppSettings settings;

  @override
  State<_AdbPathField> createState() => _AdbPathFieldState();
}

class _AdbPathFieldState extends State<_AdbPathField> {
  late final _text = TextEditingController(text: widget.settings.adbPath);
  final _focus = FocusNode();
  bool _checking = false;
  String? _version;
  String? _error;
  int _checkId = 0;

  AppSettings get _settings => widget.settings;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus) _apply(_text.text);
    });
    _settings.addListener(_onSettings);
    _check();
  }

  @override
  void dispose() {
    _settings.removeListener(_onSettings);
    // Save an unsubmitted edit once the tree is unlocked.
    final settings = _settings, path = _text.text;
    scheduleMicrotask(() => settings.adbPath = path);
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  // Reflect external changes, e.g. "Reset to defaults".
  void _onSettings() {
    final path = _settings.adbPath ?? '';
    if (_text.text.trim() != path && !_focus.hasFocus) {
      _text.text = path;
      _check();
    }
  }

  void _apply(String path, {bool check = true}) {
    final before = _settings.adbPath;
    _settings.adbPath = path;
    if (check && _settings.adbPath != before) _check();
  }

  Future<void> _check() async {
    final id = ++_checkId;
    if (mounted) setState(() => _checking = true);
    String? version, error;
    try {
      version = await AdbClient.version(_settings.adbPath);
    } on AdbException catch (e) {
      error = mounted ? context.l10n.adbError(e) : e.message;
    }
    if (!mounted || id != _checkId) return;
    setState(() {
      _checking = false;
      _version = version;
      _error = error;
    });
  }

  Future<void> _browse() async {
    final current = _settings.adbPath;
    final file = await openFile(
      initialDirectory: current == null ? null : File(current).parent.path,
    );
    if (file == null || !mounted) return;
    _text.text = file.path;
    _apply(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.adbPath),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _text,
                  focusNode: _focus,
                  decoration: InputDecoration(
                    isDense: true,
                    border: const OutlineInputBorder(),
                    hintText: l10n.adbPathHint(AdbClient.defaultPath),
                    helperText: l10n.adbPathSubtitle,
                    helperMaxLines: 2,
                  ),
                  onSubmitted: _apply,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: l10n.adbPathBrowse,
                icon: const Icon(Icons.folder_open),
                onPressed: _browse,
              ),
              IconButton(
                tooltip: l10n.adbPathUseDefault,
                icon: const Icon(Icons.restart_alt),
                onPressed: _settings.adbPath == null
                    ? null
                    : () {
                        _text.clear();
                        _apply('');
                      },
              ),
              IconButton(
                tooltip: l10n.adbPathCheck,
                icon: const Icon(Icons.fact_check_outlined),
                onPressed: _checking
                    ? null
                    : () {
                        _apply(_text.text, check: false);
                        _check();
                      },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (_checking)
                const SizedBox.square(
                    dimension: 14,
                    child: CircularProgressIndicator(strokeWidth: 2))
              else
                Icon(
                  _error == null ? Icons.check_circle : Icons.error,
                  size: 16,
                  color:
                      _error == null ? Colors.green : theme.colorScheme.error,
                ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  _checking ? l10n.adbPathChecking : (_error ?? _version ?? ''),
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: _error == null ? null : theme.colorScheme.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
