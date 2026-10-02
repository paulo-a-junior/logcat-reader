import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/log_filter.dart';
import '../../settings/filter_store.dart';
import '../l10n_helpers.dart';
import 'filter_actions.dart';
import 'filter_colors.dart';
import 'filter_editor.dart';

enum _RowAction { duplicate, delete }

/// Lists every saved filter and edits the selected one in place.
/// Edits apply live (debounced) to the store.
class FilterManagerPage extends StatefulWidget {
  const FilterManagerPage({super.key, required this.store, this.initialId});

  final FilterStore store;
  final String? initialId;

  static Future<void> open(BuildContext context, FilterStore store,
          {String? initialId}) =>
      Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => FilterManagerPage(store: store, initialId: initialId),
      ));

  @override
  State<FilterManagerPage> createState() => _FilterManagerPageState();
}

class _FilterManagerPageState extends State<FilterManagerPage> {
  late String? _selectedId = widget.initialId;
  String? _justCreatedId;
  SavedFilter? _pending;
  Timer? _debounce;

  FilterStore get _store => widget.store;

  @override
  void dispose() {
    _debounce?.cancel();
    final pending = _pending;
    final store = _store;
    // The store notifies listeners; don't do that while the tree is locked.
    if (pending != null) scheduleMicrotask(() => _apply(store, pending));
    super.dispose();
  }

  static void _apply(FilterStore store, SavedFilter f) {
    final latest = store.byId(f.id);
    if (latest != null) store.update(f.copyWith(enabled: latest.enabled));
  }

  void _onEdited(SavedFilter f) {
    _pending = f;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), _flush);
  }

  void _flush() {
    _debounce?.cancel();
    _debounce = null;
    final f = _pending;
    _pending = null;
    if (f != null) _apply(_store, f);
  }

  void _select(String? id) {
    _flush();
    setState(() {
      _selectedId = id;
      _justCreatedId = null;
    });
  }

  void _add() {
    _flush();
    final f = FilterActions.newFilter(context, _store);
    _store.add(f);
    setState(() {
      _selectedId = f.id;
      _justCreatedId = f.id;
    });
  }

  Future<void> _onRowAction(_RowAction action, SavedFilter f) async {
    _flush();
    switch (action) {
      case _RowAction.duplicate:
        final copy = FilterActions.duplicate(context, _store, f);
        if (copy != null) _select(copy.id);
      case _RowAction.delete:
        final deleted = await FilterActions.delete(context, _store, f);
        if (deleted && _selectedId == f.id) _select(null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ListenableBuilder(
      listenable: _store,
      builder: (context, _) {
        final filters = _store.filters;
        final selected = _selectedId == null ? null : _store.byId(_selectedId!);
        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.manageFilters),
            actions: [
              Tooltip(
                message: l10n.combineTooltip,
                child: SegmentedButton<FilterCombine>(
                  showSelectedIcon: false,
                  segments: [
                    ButtonSegment(
                        value: FilterCombine.any, label: Text(l10n.combineAny)),
                    ButtonSegment(
                        value: FilterCombine.all, label: Text(l10n.combineAll)),
                  ],
                  selected: {_store.combine},
                  onSelectionChanged: (s) => _store.combine = s.single,
                ),
              ),
              const SizedBox(width: 8),
              TextButton(
                onPressed: filters.isEmpty
                    ? null
                    : () {
                        _flush();
                        _store.setAllEnabled(true);
                      },
                child: Text(l10n.enableAllFilters),
              ),
              TextButton(
                onPressed: filters.isEmpty
                    ? null
                    : () {
                        _flush();
                        _store.setAllEnabled(false);
                      },
                child: Text(l10n.disableAllFilters),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: 380,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: filters.isEmpty
                          ? Center(child: Text(l10n.noFilters))
                          : ReorderableListView.builder(
                              buildDefaultDragHandles: false,
                              itemCount: filters.length,
                              onReorder: (a, b) {
                                _flush();
                                _store.reorder(a, b);
                              },
                              itemBuilder: (context, i) =>
                                  _buildRow(context, filters[i], i),
                            ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: FilledButton.icon(
                        onPressed: _add,
                        icon: const Icon(Icons.add),
                        label: Text(l10n.addFilter),
                      ),
                    ),
                  ],
                ),
              ),
              const VerticalDivider(width: 1),
              Expanded(
                child: selected == null
                    ? Center(child: Text(l10n.noFilterSelected))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(24),
                        child: Align(
                          alignment: Alignment.topLeft,
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 640),
                            child: FilterEditor(
                              key: ValueKey(selected.id),
                              filter: selected,
                              autofocusName: selected.id == _justCreatedId,
                              onChanged: _onEdited,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRow(BuildContext context, SavedFilter f, int index) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final color = filterColor(f.colorIndex, theme.brightness);
    final error = f.criteria.compile().error;
    final summary = [
      l10n.filterSummary(f.criteria),
      if (f.exclude) l10n.summaryExclude,
    ].join(' · ');

    return Material(
      key: ValueKey(f.id),
      color: Colors.transparent,
      child: ListTile(
        selected: f.id == _selectedId,
        selectedTileColor: theme.colorScheme.secondaryContainer,
        onTap: () => _select(f.id),
        contentPadding: const EdgeInsets.only(left: 4, right: 4),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: const MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.drag_indicator, size: 20),
                ),
              ),
            ),
            const SizedBox(width: 4),
            error != null
                ? Icon(Icons.error_outline, color: theme.colorScheme.error)
                : f.exclude
                    ? Icon(Icons.visibility_off, color: color)
                    : Icon(Icons.circle, color: color, size: 18),
          ],
        ),
        title: Text(f.name, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          error != null ? l10n.invalidRegex(error) : summary,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style:
              error != null ? TextStyle(color: theme.colorScheme.error) : null,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: l10n.filterEnabled,
              child: Switch(
                value: f.enabled,
                onChanged: (_) {
                  _flush();
                  _store.toggle(f.id);
                },
              ),
            ),
            PopupMenuButton<_RowAction>(
              onSelected: (a) => _onRowAction(a, f),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: _RowAction.duplicate,
                  child: ListTile(
                      leading: const Icon(Icons.copy),
                      title: Text(l10n.duplicateFilter)),
                ),
                PopupMenuItem(
                  value: _RowAction.delete,
                  child: ListTile(
                      leading: const Icon(Icons.delete_outline),
                      title: Text(l10n.deleteFilter)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
