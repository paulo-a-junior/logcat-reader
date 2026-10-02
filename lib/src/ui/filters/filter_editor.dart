import 'package:flutter/material.dart';

import '../../models/log_entry.dart';
import '../../models/log_filter.dart';
import '../l10n_helpers.dart';
import 'filter_colors.dart';

/// Form for a [SavedFilter]'s properties. Reports every change through
/// [onChanged]; the caller decides whether to apply it live or on save.
///
/// Fields are initialised from [filter] once; give the widget a key per
/// filter id so it resets when a different filter is edited.
class FilterEditor extends StatefulWidget {
  const FilterEditor({
    super.key,
    required this.filter,
    required this.onChanged,
    this.autofocusName = false,
  });

  final SavedFilter filter;
  final ValueChanged<SavedFilter> onChanged;
  final bool autofocusName;

  @override
  State<FilterEditor> createState() => _FilterEditorState();
}

class _FilterEditorState extends State<FilterEditor> {
  late final _name = TextEditingController(text: widget.filter.name);
  late final _text = TextEditingController(text: widget.filter.criteria.text);
  late final _process =
      TextEditingController(text: widget.filter.criteria.process);
  late final _tag = TextEditingController(text: widget.filter.criteria.tag);
  late int _colorIndex = widget.filter.colorIndex;
  late bool _exclude = widget.filter.exclude;
  late bool _useRegex = widget.filter.criteria.useRegex;
  late bool _caseSensitive = widget.filter.criteria.caseSensitive;
  late LogLevel _minLevel = widget.filter.criteria.minLevel;

  @override
  void initState() {
    super.initState();
    if (widget.autofocusName) {
      _name.selection =
          TextSelection(baseOffset: 0, extentOffset: _name.text.length);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _text.dispose();
    _process.dispose();
    _tag.dispose();
    super.dispose();
  }

  LogFilter get _criteria => LogFilter(
        text: _text.text,
        useRegex: _useRegex,
        caseSensitive: _caseSensitive,
        process: _process.text,
        tag: _tag.text,
        minLevel: _minLevel,
      );

  void _emit() {
    setState(() {});
    widget.onChanged(widget.filter.copyWith(
      name: _name.text,
      colorIndex: _colorIndex,
      exclude: _exclude,
      criteria: _criteria,
    ));
  }

  InputDecoration _decoration(String label, IconData icon,
          {String? hint, String? errorText}) =>
      InputDecoration(
        isDense: true,
        labelText: label,
        hintText: hint,
        errorText: errorText,
        prefixIcon: Icon(icon, size: 18),
        border: const OutlineInputBorder(),
      );

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final brightness = theme.brightness;
    final regexError = _criteria.compile().error;

    Widget section(String title) => Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(title,
              style: theme.textTheme.titleSmall
                  ?.copyWith(color: theme.colorScheme.primary)),
        );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _name,
          autofocus: widget.autofocusName,
          onChanged: (_) => _emit(),
          decoration: _decoration(l10n.filterName, Icons.label),
        ),
        section(l10n.filterColor),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (var i = 0; i < filterPalette.length; i++)
              _Swatch(
                color: filterColor(i, brightness),
                selected: i == _colorIndex,
                onTap: () {
                  _colorIndex = i;
                  _emit();
                },
              ),
          ],
        ),
        section(l10n.filterMode),
        Align(
          alignment: Alignment.centerLeft,
          child: SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(
                  value: false,
                  icon: const Icon(Icons.visibility),
                  label: Text(l10n.filterModeInclude)),
              ButtonSegment(
                  value: true,
                  icon: const Icon(Icons.visibility_off),
                  label: Text(l10n.filterModeExclude)),
            ],
            selected: {_exclude},
            onSelectionChanged: (s) {
              _exclude = s.single;
              _emit();
            },
          ),
        ),
        section(l10n.filterCriteria),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: _text,
                onChanged: (_) => _emit(),
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: _decoration(
                  l10n.filterMessage,
                  Icons.search,
                  hint: _useRegex
                      ? l10n.filterMessageHintRegex
                      : l10n.filterMessageHintText,
                  errorText:
                      regexError == null ? null : l10n.invalidRegex(regexError),
                ),
              ),
            ),
            const SizedBox(width: 4),
            _Toggle(
              label: '.*',
              tooltip: l10n.regularExpression,
              selected: _useRegex,
              onPressed: () {
                _useRegex = !_useRegex;
                _emit();
              },
            ),
            _Toggle(
              label: 'Aa',
              tooltip: l10n.caseSensitive,
              selected: _caseSensitive,
              onPressed: () {
                _caseSensitive = !_caseSensitive;
                _emit();
              },
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _process,
                onChanged: (_) => _emit(),
                decoration: _decoration(l10n.filterProcess, Icons.memory,
                    hint: l10n.filterProcessHint),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _tag,
                onChanged: (_) => _emit(),
                decoration: _decoration(l10n.filterTag, Icons.sell_outlined),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<LogLevel>(
          value: _minLevel,
          isDense: true,
          isExpanded: true,
          decoration: _decoration(l10n.filterMinLevel, Icons.filter_list),
          items: [
            for (final level in LogLevel.values
                .where((l) => l.index <= LogLevel.fatal.index))
              DropdownMenuItem(
                value: level,
                child: Text(l10n.level(level),
                    style: TextStyle(color: levelColor(level, brightness))),
              ),
          ],
          onChanged: (level) {
            if (level == null) return;
            _minLevel = level;
            _emit();
          },
        ),
      ],
    );
  }
}

class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      customBorder: const CircleBorder(),
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: selected
              ? Border.all(
                  color: Theme.of(context).colorScheme.onSurface, width: 3)
              : null,
        ),
        child: selected
            ? Icon(Icons.check,
                size: 16,
                color: ThemeData.estimateBrightnessForColor(color) ==
                        Brightness.dark
                    ? Colors.white
                    : Colors.black)
            : null,
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.label,
    required this.tooltip,
    required this.selected,
    required this.onPressed,
  });

  final String label;
  final String tooltip;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.only(top: 2),
        child: ToggleButtons(
          isSelected: [selected],
          onPressed: (_) => onPressed(),
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          children: [
            Text(label, style: const TextStyle(fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }
}
