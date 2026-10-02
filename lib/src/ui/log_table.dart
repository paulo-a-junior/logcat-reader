import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import '../models/log_entry.dart';
import 'l10n_helpers.dart';

/// A virtualized three-column log table (line number, process, message)
/// that follows the tail while the user is scrolled to the bottom.
///
/// With [wrap] off every row has the same height and a plain [ListView] with
/// a fixed extent is used; with [wrap] on rows have variable height and
/// [SuperListView] keeps jumping to an index accurate.
class LogTable extends StatefulWidget {
  const LogTable({
    super.key,
    required this.title,
    required this.itemCount,
    required this.entryAt,
    required this.processLabel,
    required this.fontSize,
    required this.wrap,
    this.selectedLine,
    this.onRowTap,
    this.controller,
    this.markColorAt,
  });

  final String title;
  final int itemCount;
  final LogEntry Function(int index) entryAt;
  final String Function(LogEntry entry) processLabel;
  final double fontSize;
  final bool wrap;
  final int? selectedLine;
  final ValueChanged<LogEntry>? onRowTap;
  final LogTableController? controller;

  /// Optional colour stripe drawn at the start of each row.
  final Color? Function(int index)? markColorAt;

  @override
  State<LogTable> createState() => _LogTableState();
}

/// Lets a parent scroll a [LogTable] to a given row index.
class LogTableController {
  _LogTableState? _state;

  void revealIndex(int index) => _state?._revealIndex(index);
}

class _LogTableState extends State<LogTable> {
  final _vertical = ScrollController();
  final _list = ListController();
  bool _follow = true;

  // Follow mode only reacts to scrolling the user caused.
  bool _pointerDown = false;
  DateTime _lastWheel = DateTime.fromMillisecondsSinceEpoch(0);

  double get _rowHeight => widget.fontSize * 1.2 + 5;
  double get _charWidth => widget.fontSize * 0.62;
  double get _lineColWidth => _charWidth * 8 + 8;
  double get _processColWidth => _charWidth * 36;

  TextStyle get _mono => TextStyle(
      fontFamily: 'monospace', fontSize: widget.fontSize, height: 1.2);

  @override
  void initState() {
    super.initState();
    widget.controller?._state = this;
  }

  @override
  void didUpdateWidget(LogTable old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._state = null;
      widget.controller?._state = this;
    }
    if (_follow &&
        (widget.itemCount != old.itemCount ||
            widget.wrap != old.wrap ||
            widget.fontSize != old.fontSize)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToEnd());
    }
  }

  @override
  void dispose() {
    widget.controller?._state = null;
    _vertical.dispose();
    _list.dispose();
    super.dispose();
  }

  bool get _userScrolling =>
      _pointerDown ||
      DateTime.now().difference(_lastWheel) < const Duration(milliseconds: 250);

  void _jumpToEnd() {
    if (!mounted || !_vertical.hasClients || widget.itemCount == 0) return;
    if (widget.wrap) {
      if (!_list.isAttached) return;
      _list.jumpToItem(
        index: widget.itemCount - 1,
        scrollController: _vertical,
        alignment: 1,
      );
    } else {
      _vertical.jumpTo(_vertical.position.maxScrollExtent);
    }
  }

  void _setFollow(bool value) {
    if (value == _follow) return;
    setState(() => _follow = value);
    if (value) _jumpToEnd();
  }

  void _revealIndex(int index) {
    if (!_vertical.hasClients || index < 0 || index >= widget.itemCount) {
      return;
    }
    _setFollow(false);
    if (widget.wrap) {
      if (!_list.isAttached) return;
      _list.jumpToItem(
        index: index,
        scrollController: _vertical,
        alignment: 0.5,
      );
    } else {
      final pos = _vertical.position;
      final target =
          (index * _rowHeight - pos.viewportDimension / 2 + _rowHeight)
              .clamp(0.0, pos.maxScrollExtent);
      _vertical.jumpTo(target);
    }
  }

  bool _onScroll(ScrollNotification n) {
    if (_userScrolling &&
        (n is ScrollUpdateNotification || n is ScrollEndNotification)) {
      final m = n.metrics;
      _setFollow(m.pixels >= m.maxScrollExtent - _rowHeight);
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final headerStyle =
        theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          color: theme.colorScheme.surfaceContainerHigh,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          height: 28,
          child: Row(
            children: [
              SizedBox(
                  width: _lineColWidth,
                  child: Text(l10n.columnLine, style: headerStyle)),
              SizedBox(
                  width: _processColWidth,
                  child: Text(l10n.columnProcess, style: headerStyle)),
              Expanded(child: Text(l10n.columnMessage, style: headerStyle)),
              Text('${widget.title} · ${l10n.lineCount(widget.itemCount)}',
                  style: theme.textTheme.labelSmall),
              const SizedBox(width: 4),
              IconButton(
                tooltip: _follow ? l10n.followingNewLines : l10n.followNewLines,
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                isSelected: _follow,
                icon: const Icon(Icons.vertical_align_bottom),
                onPressed: () => _setFollow(!_follow),
              ),
            ],
          ),
        ),
        Expanded(
          child: Listener(
            onPointerDown: (_) => _pointerDown = true,
            onPointerUp: (_) => _pointerDown = false,
            onPointerCancel: (_) => _pointerDown = false,
            onPointerSignal: (e) {
              if (e is PointerScrollEvent) _lastWheel = DateTime.now();
            },
            child: NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: Scrollbar(
                controller: _vertical,
                thumbVisibility: true,
                child: widget.wrap
                    ? SuperListView.builder(
                        controller: _vertical,
                        listController: _list,
                        itemCount: widget.itemCount,
                        extentEstimation: (_, __) => _rowHeight,
                        itemBuilder: (context, index) =>
                            _buildRow(theme, index),
                      )
                    : ListView.builder(
                        controller: _vertical,
                        itemExtent: _rowHeight,
                        itemCount: widget.itemCount,
                        itemBuilder: (context, index) =>
                            _buildRow(theme, index),
                      ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRow(ThemeData theme, int index) {
    final entry = widget.entryAt(index);
    final selected = entry.lineNumber == widget.selectedLine;
    final color = levelColor(entry.level, theme.brightness) ??
        theme.colorScheme.onSurface;
    final background = selected
        ? theme.colorScheme.primaryContainer
        : index.isOdd
            ? theme.colorScheme.surfaceContainerLowest
            : null;
    final style = _mono.copyWith(color: color);
    final wrap = widget.wrap;
    final mark = widget.markColorAt?.call(index);

    return Material(
      color: background ?? Colors.transparent,
      child: InkWell(
        onTap: widget.onRowTap == null ? null : () => widget.onRowTap!(entry),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(color: mark ?? Colors.transparent, width: 3),
            ),
          ),
          padding: const EdgeInsets.fromLTRB(5, 2.5, 8, 2.5),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _lineColWidth,
                child: Text('${entry.lineNumber}',
                    style: _mono.copyWith(color: theme.hintColor)),
              ),
              SizedBox(
                width: _processColWidth,
                child: Text(widget.processLabel(entry),
                    maxLines: 1,
                    softWrap: false,
                    overflow: TextOverflow.ellipsis,
                    style: style),
              ),
              Expanded(
                child: Text(entry.displayMessage,
                    maxLines: wrap ? null : 1,
                    softWrap: wrap,
                    overflow: wrap ? null : TextOverflow.ellipsis,
                    style: style),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
