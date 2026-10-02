import 'package:flutter/material.dart';

import '../../models/command_shortcut.dart';
import '../../settings/shortcut_store.dart';
import '../l10n_helpers.dart';
import 'shortcut_icons.dart';

/// Toolbar buttons for pinned shortcuts plus a menu listing all of them.
class ShortcutBar extends StatelessWidget {
  const ShortcutBar({
    super.key,
    required this.store,
    required this.onRun,
    required this.onManage,
  });

  final ShortcutStore store;
  final void Function(CommandShortcut) onRun;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final all = store.shortcuts;
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final s in all.where((s) => s.pinned))
              IconButton(
                tooltip: s.name,
                onPressed: () => onRun(s),
                icon: Icon(shortcutIcon(s.iconIndex)),
              ),
            PopupMenuButton<CommandShortcut?>(
              tooltip: l10n.navShortcuts,
              icon: const Icon(Icons.bolt),
              onSelected: (s) => s == null ? onManage() : onRun(s),
              itemBuilder: (context) => [
                for (final s in all)
                  PopupMenuItem(
                    value: s,
                    child: ListTile(
                      leading: Icon(shortcutIcon(s.iconIndex)),
                      title: Text(s.name),
                    ),
                  ),
                if (all.isNotEmpty) const PopupMenuDivider(),
                PopupMenuItem(
                  value: null,
                  child: ListTile(
                    leading: const Icon(Icons.tune),
                    title: Text(l10n.manageShortcuts),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
