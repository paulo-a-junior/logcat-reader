import 'package:flutter/material.dart';

import '../../models/log_filter.dart';
import '../../settings/filter_store.dart';
import '../l10n_helpers.dart';
import 'filter_actions.dart';
import 'filter_colors.dart';

enum _BalloonAction { edit, duplicate, delete }

/// Row of filter balloons. Click toggles a filter, double-click edits it;
/// right-click (or long press) offers edit, duplicate and delete.
class FilterBalloonBar extends StatelessWidget {
  const FilterBalloonBar({
    super.key,
    required this.store,
    required this.onManage,
  });

  final FilterStore store;
  final VoidCallback onManage;

  Future<void> _showMenu(
      BuildContext context, SavedFilter filter, Offset position) async {
    final l10n = context.l10n;
    final overlay =
        Overlay.of(context).context.findRenderObject()! as RenderBox;
    final action = await showMenu<_BalloonAction>(
      context: context,
      position: RelativeRect.fromRect(
          position & const Size(1, 1), Offset.zero & overlay.size),
      items: [
        PopupMenuItem(
          value: _BalloonAction.edit,
          child:
              ListTile(leading: const Icon(Icons.edit), title: Text(l10n.edit)),
        ),
        PopupMenuItem(
          value: _BalloonAction.duplicate,
          child: ListTile(
              leading: const Icon(Icons.copy),
              title: Text(l10n.duplicateFilter)),
        ),
        PopupMenuItem(
          value: _BalloonAction.delete,
          child: ListTile(
              leading: const Icon(Icons.delete_outline),
              title: Text(l10n.deleteFilter)),
        ),
      ],
    );
    if (action == null || !context.mounted) return;
    switch (action) {
      case _BalloonAction.edit:
        await FilterActions.edit(context, store, filter);
      case _BalloonAction.duplicate:
        FilterActions.duplicate(context, store, filter);
      case _BalloonAction.delete:
        await FilterActions.delete(context, store, filter);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final filters = store.filters;
        final anyEnabled = filters.any((f) => f.enabled);
        final includes = filters.where((f) => f.enabled && !f.exclude).length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 4, 6),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Tooltip(
                message: l10n.filters,
                child: const Icon(Icons.filter_alt_outlined, size: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    for (final f in filters)
                      FilterBalloon(
                        key: ValueKey(f.id),
                        filter: f,
                        onTap: () => store.toggle(f.id),
                        onDoubleTap: () =>
                            FilterActions.edit(context, store, f),
                        onMenu: (pos) => _showMenu(context, f, pos),
                      ),
                    ActionChip(
                      avatar: const Icon(Icons.add, size: 16),
                      label: Text(l10n.addFilter),
                      shape: const StadiumBorder(),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => FilterActions.add(context, store),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Tooltip(
                message: l10n.combineTooltip,
                child: SegmentedButton<FilterCombine>(
                  showSelectedIcon: false,
                  style:
                      const ButtonStyle(visualDensity: VisualDensity.compact),
                  segments: [
                    ButtonSegment(
                        value: FilterCombine.any, label: Text(l10n.combineAny)),
                    ButtonSegment(
                        value: FilterCombine.all, label: Text(l10n.combineAll)),
                  ],
                  selected: {store.combine},
                  onSelectionChanged:
                      includes < 2 ? null : (s) => store.combine = s.single,
                ),
              ),
              IconButton(
                tooltip: l10n.disableAllFilters,
                onPressed: anyEnabled ? () => store.setAllEnabled(false) : null,
                icon: const Icon(Icons.filter_alt_off_outlined),
              ),
              IconButton(
                tooltip: l10n.manageFilters,
                onPressed: onManage,
                icon: const Icon(Icons.tune),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A single pill-shaped filter toggle.
class FilterBalloon extends StatelessWidget {
  const FilterBalloon({
    super.key,
    required this.filter,
    required this.onTap,
    this.onDoubleTap,
    this.onMenu,
  });

  final SavedFilter filter;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;

  /// Called with the global position for a context menu.
  final ValueChanged<Offset>? onMenu;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = filterColor(filter.colorIndex, theme.brightness);
    final enabled = filter.enabled;
    final error = filter.criteria.compile().error;
    final foreground =
        enabled ? theme.colorScheme.onSurface : theme.colorScheme.outline;

    final Widget leading;
    if (error != null) {
      leading =
          Icon(Icons.error_outline, size: 16, color: theme.colorScheme.error);
    } else if (filter.exclude) {
      leading = Icon(Icons.visibility_off, size: 16, color: color);
    } else {
      leading = Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: enabled ? color : Colors.transparent,
          border: Border.all(color: color, width: 2),
        ),
      );
    }

    final tooltip = [
      l10n.filterSummary(filter.criteria),
      if (filter.exclude) l10n.summaryExclude,
      if (error != null) l10n.invalidRegex(error),
    ].join('\n');

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 500),
      child: GestureDetector(
        onSecondaryTapUp:
            onMenu == null ? null : (d) => onMenu!(d.globalPosition),
        onLongPressStart:
            onMenu == null ? null : (d) => onMenu!(d.globalPosition),
        child: Material(
          color: enabled ? color.withAlpha(56) : Colors.transparent,
          shape: StadiumBorder(
            side: BorderSide(
              color: enabled ? color : theme.colorScheme.outlineVariant,
              width: 1.5,
            ),
          ),
          child: InkWell(
            customBorder: const StadiumBorder(),
            onTap: onTap,
            onDoubleTap: onDoubleTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  leading,
                  const SizedBox(width: 6),
                  Text(
                    filter.name,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: foreground,
                      fontWeight: enabled ? FontWeight.w600 : null,
                      decoration: filter.exclude && enabled
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
