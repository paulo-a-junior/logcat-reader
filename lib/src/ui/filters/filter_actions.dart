import 'package:flutter/material.dart';

import '../../models/log_filter.dart';
import '../../settings/filter_store.dart';
import '../l10n_helpers.dart';
import 'filter_colors.dart';
import 'filter_editor.dart';

/// Filter operations shared by the balloon bar and the manager page.
abstract final class FilterActions {
  /// A fresh filter, using the next unused colour.
  static SavedFilter newFilter(BuildContext context, FilterStore store) {
    final used = store.filters.map((f) => f.colorIndex).toSet();
    var color = 0;
    while (used.contains(color) && color < filterPalette.length - 1) {
      color++;
    }
    return SavedFilter(
      id: SavedFilter.newId(),
      name: context.l10n.newFilterName,
      colorIndex: used.length >= filterPalette.length
          ? store.filters.length % filterPalette.length
          : color,
      enabled: true,
    );
  }

  /// Opens the editor dialog for a new filter and adds it on save.
  static Future<void> add(BuildContext context, FilterStore store) async {
    final created = await FilterEditDialog.show(
        context, newFilter(context, store),
        isNew: true);
    if (created != null) store.add(created);
  }

  static Future<void> edit(
      BuildContext context, FilterStore store, SavedFilter filter) async {
    final edited = await FilterEditDialog.show(context, filter);
    if (edited == null) return;
    // Keep the enabled state current in case it was toggled meanwhile.
    final latest = store.byId(filter.id);
    if (latest != null) store.update(edited.copyWith(enabled: latest.enabled));
  }

  static SavedFilter? duplicate(
          BuildContext context, FilterStore store, SavedFilter filter) =>
      store.duplicate(filter.id, context.l10n.filterCopyName(filter.name));

  /// Asks for confirmation; returns whether the filter was deleted.
  static Future<bool> delete(
      BuildContext context, FilterStore store, SavedFilter filter) async {
    final l10n = context.l10n;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.deleteFilterTitle),
        content: Text(l10n.deleteFilterConfirm(filter.name)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(l10n.deleteFilter)),
        ],
      ),
    );
    if (ok != true) return false;
    store.remove(filter.id);
    return true;
  }
}

/// Modal editor for one filter; returns the edited copy, or null on cancel.
class FilterEditDialog extends StatefulWidget {
  const FilterEditDialog({super.key, required this.filter, this.isNew = false});

  final SavedFilter filter;
  final bool isNew;

  static Future<SavedFilter?> show(BuildContext context, SavedFilter filter,
          {bool isNew = false}) =>
      showDialog<SavedFilter>(
        context: context,
        builder: (_) => FilterEditDialog(filter: filter, isNew: isNew),
      );

  @override
  State<FilterEditDialog> createState() => _FilterEditDialogState();
}

class _FilterEditDialogState extends State<FilterEditDialog> {
  late SavedFilter _draft = widget.filter;

  void _save() {
    final name = _draft.name.trim();
    Navigator.pop(
      context,
      _draft.copyWith(name: name.isEmpty ? context.l10n.newFilterName : name),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return AlertDialog(
      title: Text(widget.isNew ? l10n.addFilter : l10n.editFilter),
      content: SizedBox(
        width: 560,
        child: SingleChildScrollView(
          child: FilterEditor(
            filter: _draft,
            autofocusName: widget.isNew,
            onChanged: (f) => setState(() => _draft = f),
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
