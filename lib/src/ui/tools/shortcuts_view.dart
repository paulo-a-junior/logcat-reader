import 'package:flutter/material.dart';

import '../../models/command_shortcut.dart';
import '../../settings/shortcut_store.dart';
import '../l10n_helpers.dart';
import 'shortcut_edit_dialog.dart';
import 'shortcut_icons.dart';
import 'tool_helpers.dart';

/// Shortcut actions shared by the Shortcuts view and the toolbar menu.
class ShortcutActions {
  static Future<void> add(BuildContext context, ShortcutStore store) async {
    final created = await ShortcutEditDialog.show(
      context,
      CommandShortcut(
        id: CommandShortcut.newId(),
        name: context.l10n.newShortcutName,
        command: '',
      ),
      isNew: true,
    );
    if (created != null) store.add(created);
  }

  static Future<void> edit(
      BuildContext context, ShortcutStore store, CommandShortcut s) async {
    final edited = await ShortcutEditDialog.show(context, s);
    if (edited != null) store.update(edited);
  }

  static Future<void> delete(
      BuildContext context, ShortcutStore store, CommandShortcut s) async {
    final l10n = context.l10n;
    if (await confirmAction(
      context,
      title: l10n.deleteShortcutTitle,
      message: l10n.deleteShortcutConfirm(s.name),
      action: l10n.delete,
      destructive: true,
    )) {
      store.remove(s.id);
    }
  }
}

/// Lists, reorders, edits and runs the saved command shortcuts.
class ShortcutsView extends StatelessWidget {
  const ShortcutsView({super.key, required this.store, required this.onRun});

  final ShortcutStore store;
  final void Function(CommandShortcut) onRun;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final items = store.shortcuts;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  Text(l10n.navShortcuts, style: theme.textTheme.titleMedium),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: () => ShortcutActions.add(context, store),
                    icon: const Icon(Icons.add),
                    label: Text(l10n.addShortcut),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: items.isEmpty
                  ? Center(child: Text(l10n.noShortcuts))
                  : ReorderableListView.builder(
                      buildDefaultDragHandles: false,
                      itemCount: items.length,
                      onReorder: store.reorder,
                      itemBuilder: (context, i) {
                        final s = items[i];
                        final kind = switch (s.kind) {
                          ShortcutKind.shell => l10n.kindShell,
                          ShortcutKind.adb => l10n.kindAdb,
                          ShortcutKind.host => l10n.kindHost,
                        };
                        return ListTile(
                          key: ValueKey(s.id),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ReorderableDragStartListener(
                                index: i,
                                child: const Icon(Icons.drag_indicator),
                              ),
                              const SizedBox(width: 12),
                              Icon(shortcutIcon(s.iconIndex)),
                            ],
                          ),
                          title: Row(
                            children: [
                              Flexible(
                                child: Text(s.name,
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (s.pinned) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.push_pin,
                                    size: 14, color: theme.colorScheme.primary),
                              ],
                              if (s.confirm) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.help_outline,
                                    size: 14, color: theme.colorScheme.outline),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '$kind · ${s.command}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontFamily: 'monospace'),
                          ),
                          onTap: () => ShortcutActions.edit(context, store, s),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: l10n.run,
                                onPressed: () => onRun(s),
                                icon: const Icon(Icons.play_arrow),
                              ),
                              IconButton(
                                tooltip: l10n.edit,
                                onPressed: () =>
                                    ShortcutActions.edit(context, store, s),
                                icon: const Icon(Icons.edit),
                              ),
                              IconButton(
                                tooltip: l10n.delete,
                                onPressed: () =>
                                    ShortcutActions.delete(context, store, s),
                                icon: const Icon(Icons.delete_outline),
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
