import 'package:flutter/material.dart';

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
