import 'package:flutter/material.dart';

import '../../models/command_shortcut.dart';
import '../l10n_helpers.dart';
import 'shortcut_icons.dart';

/// Add/edit form for a [CommandShortcut]; pops the edited shortcut on save.
class ShortcutEditDialog extends StatefulWidget {
  const ShortcutEditDialog(
      {super.key, required this.initial, this.isNew = false});

  final CommandShortcut initial;
  final bool isNew;

  static Future<CommandShortcut?> show(
          BuildContext context, CommandShortcut initial,
          {bool isNew = false}) =>
      showDialog<CommandShortcut>(
        context: context,
        builder: (_) => ShortcutEditDialog(initial: initial, isNew: isNew),
      );

  @override
  State<ShortcutEditDialog> createState() => _ShortcutEditDialogState();
}

class _ShortcutEditDialogState extends State<ShortcutEditDialog> {
  late final _name = TextEditingController(text: widget.initial.name);
  late final _command = TextEditingController(text: widget.initial.command);
  late CommandShortcut _value = widget.initial;
  bool _showErrors = false;

  @override
  void dispose() {
    _name.dispose();
    _command.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final command = _command.text.trim();
    if (name.isEmpty || command.isEmpty) {
      setState(() => _showErrors = true);
      return;
    }
    Navigator.pop(context, _value.copyWith(name: name, command: command));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final hint = switch (_value.kind) {
      ShortcutKind.shell => l10n.kindShellHint,
      ShortcutKind.adb => l10n.kindAdbHint,
      ShortcutKind.host => l10n.kindHostHint,
    };
    return AlertDialog(
      title: Text(widget.isNew ? l10n.addShortcut : l10n.editShortcut),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _name,
                autofocus: true,
                decoration: InputDecoration(
                  labelText: l10n.shortcutName,
                  errorText: _showErrors && _name.text.trim().isEmpty
                      ? l10n.shortcutName
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.shortcutKind, style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              SegmentedButton<ShortcutKind>(
                segments: [
                  ButtonSegment(
                      value: ShortcutKind.shell,
                      icon: const Icon(Icons.terminal),
                      label: Text(l10n.kindShell)),
                  ButtonSegment(
                      value: ShortcutKind.adb,
                      icon: const Icon(Icons.usb),
                      label: Text(l10n.kindAdb)),
                  ButtonSegment(
                      value: ShortcutKind.host,
                      icon: const Icon(Icons.computer),
                      label: Text(l10n.kindHost)),
                ],
                selected: {_value.kind},
                onSelectionChanged: (s) =>
                    setState(() => _value = _value.copyWith(kind: s.first)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _command,
                minLines: 1,
                maxLines: 6,
                style: const TextStyle(fontFamily: 'monospace'),
                decoration: InputDecoration(
                  labelText: l10n.shortcutCommand,
                  helperText: hint,
                  helperMaxLines: 2,
                  errorText: _showErrors && _command.text.trim().isEmpty
                      ? l10n.commandRequired
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              Text(l10n.shortcutOutput, style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              SegmentedButton<ShortcutOutput>(
                segments: [
                  ButtonSegment(
                      value: ShortcutOutput.notify,
                      icon: const Icon(Icons.notifications_none),
                      label: Text(l10n.outputNotify)),
                  ButtonSegment(
                      value: ShortcutOutput.console,
                      icon: const Icon(Icons.terminal),
                      label: Text(l10n.outputConsole)),
                ],
                selected: {_value.output},
                onSelectionChanged: (s) =>
                    setState(() => _value = _value.copyWith(output: s.first)),
              ),
              const SizedBox(height: 8),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.shortcutConfirm),
                value: _value.confirm,
                onChanged: (v) =>
                    setState(() => _value = _value.copyWith(confirm: v)),
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.shortcutPinned),
                value: _value.pinned,
                onChanged: (v) =>
                    setState(() => _value = _value.copyWith(pinned: v)),
              ),
              const SizedBox(height: 8),
              Text(l10n.shortcutIcon, style: theme.textTheme.labelLarge),
              const SizedBox(height: 6),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  for (var i = 0; i < shortcutIcons.length; i++)
                    IconButton(
                      isSelected: _value.iconIndex == i,
                      style: IconButton.styleFrom(
                        backgroundColor: _value.iconIndex == i
                            ? theme.colorScheme.secondaryContainer
                            : null,
                      ),
                      onPressed: () => setState(
                          () => _value = _value.copyWith(iconIndex: i)),
                      icon: Icon(shortcutIcons[i]),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(onPressed: _save, child: Text(l10n.save)),
      ],
    );
  }
}
