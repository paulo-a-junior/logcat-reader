import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

import '../models/log_entry.dart';
import 'l10n_helpers.dart';

/// A virtualized three-column log table (line number, process, message)
/// that follows the tail while the user is scrolled to the bottom.
///
/// Rows can be selected with click, Shift+click, click-and-drag (which
/// auto-scrolls past the edges) and Ctrl/Cmd+click or drag to add or remove
/// rows. The selection is kept as line-number ranges, so it survives filter
/// changes. Right-click or Ctrl+C copies it. Arrow keys move the selection
/// by one row and Page Up/Down by [pageRows]; with Shift they extend it.
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

  /// Rows moved by one Page Up/Down stroke.
  static const pageRows = 10;

  final String title;
  final int itemCount;
  final LogEntry Function(int index) entryAt;
  final String Function(LogEntry entry) processLabel;
  final double fontSize;
  final bool wrap;

  /// When this changes, the selection is reset to this line.
  final int? selectedLine;

  /// Plain click on a row (not Shift+click or a drag).
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

  final _focusNode = FocusNode(debugLabel: 'LogTable');
  final _viewportKey = GlobalKey();

  // Selection: [_committed] ranges (from Ctrl/Cmd+click) plus the active
  // range from [_anchorLine] to [_focusLine]; no active range while
  // [_focusLine] is null. Shift+click extends the active range.
  final _committed = _LineRanges();
  int? _anchorLine;
  int? _focusLine;

  // Mouse drag selection.
  bool _dragging = false;
  bool _dragMoved = false;
  bool _dragShift = false;
  bool _dragCommand = false;

  /// False when a Ctrl/Cmd+click removed a row: the drag then selects nothing.
  bool _dragSelects = true;
  LogEntry? _downEntry;
  Offset? _dragPosition;
  Timer? _autoScroll;

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
    _anchorLine = _focusLine = widget.selectedLine;
  }

  void _selectOnly(int? line) {
    _committed.clear();
    _anchorLine = _focusLine = line;
  }

  @override
  void didUpdateWidget(LogTable old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller?._state = null;
      widget.controller?._state = this;
    }
    if (widget.selectedLine != old.selectedLine &&
        widget.selectedLine != null) {
      _selectOnly(widget.selectedLine);
    }
    // Line numbers restart after the log is cleared or a new source opens.
    if (widget.itemCount == 0) _selectOnly(null);
    if (_follow &&
        (widget.itemCount != old.itemCount ||
            widget.wrap != old.wrap ||
            widget.fontSize != old.fontSize)) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _jumpToEnd());
    }
  }

  @override
  void dispose() {
    _autoScroll?.cancel();
    _focusNode.dispose();
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
    final line = widget.entryAt(index).lineNumber;
    if (_anchorLine != line || _focusLine != line || !_committed.isEmpty) {
      setState(() => _selectOnly(line));
    }
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
              Text(
                  [
                    widget.title,
                    l10n.lineCount(widget.itemCount),
                    if (_selectedCount > 1) l10n.selectedCount(_selectedCount),
                  ].join(' · '),
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
          child: Focus(
            focusNode: _focusNode,
            onKeyEvent: _onKey,
            child: Listener(
              key: _viewportKey,
              onPointerDown: _onPointerDown,
              onPointerMove: _onPointerMove,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerUp,
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
        ),
      ],
    );
  }

  // ---- Selection -------------------------------------------------------

  bool get _hasSelection => _focusLine != null || !_committed.isEmpty;

  bool _isSelected(int line) {
    final a = _anchorLine, f = _focusLine;
    if (a != null &&
        f != null &&
        line >= math.min(a, f) &&
        line <= math.max(a, f)) {
      return true;
    }
    return _committed.contains(line);
  }

  /// All selected line ranges, sorted and merged.
  List<(int, int)> get _selection {
    final a = _anchorLine, f = _focusLine;
    if (a == null || f == null) return _committed.ranges;
    return (_LineRanges.from(_committed)..add(math.min(a, f), math.max(a, f)))
        .ranges;
  }

  /// Moves the active range into [_committed] so a new one can start.
  void _commitActive() {
    final a = _anchorLine, f = _focusLine;
    if (a != null && f != null) _committed.add(math.min(a, f), math.max(a, f));
    _focusLine = null;
  }

  /// First row index whose line number is >= [line] (rows are sorted).
  int _lowerBound(int line) {
    var lo = 0, hi = widget.itemCount;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (widget.entryAt(mid).lineNumber < line) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  /// Row index spans `[start, end)` of the selection in this table.
  Iterable<(int, int)> get _selectedRows sync* {
    for (final (first, last) in _selection) {
      final start = _lowerBound(first);
      final end = _lowerBound(last + 1);
      if (end > start) yield (start, end);
    }
  }

  int get _selectedCount =>
      _selectedRows.fold(0, (sum, rows) => sum + rows.$2 - rows.$1);

  void _selectAll() {
    if (widget.itemCount == 0) return;
    setState(() {
      _committed.clear();
      _anchorLine = widget.entryAt(0).lineNumber;
      _focusLine = widget.entryAt(widget.itemCount - 1).lineNumber;
    });
  }

  /// The selected rows, in line order, one per line.
  String _selectionText(String Function(LogEntry e) line) {
    final out = StringBuffer();
    var first = true;
    for (final (start, end) in _selectedRows) {
      for (var i = start; i < end; i++) {
        if (!first) out.write('\n');
        first = false;
        out.write(line(widget.entryAt(i)));
      }
    }
    return out.toString();
  }

  String _rowText(LogEntry e) =>
      '${e.lineNumber}\t${widget.processLabel(e)}\t${e.displayMessage}';

  Future<void> _copy(String text) async {
    final messenger = ScaffoldMessenger.maybeOf(context);
    final message = context.l10n.copiedToClipboard;
    await Clipboard.setData(ClipboardData(text: text));
    messenger
      ?..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ));
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    final command = keyboard.isControlPressed || keyboard.isMetaPressed;
    final key = event.logicalKey;
    if (command && key == LogicalKeyboardKey.keyC && _selectedCount > 0) {
      _copy(_selectionText((e) => e.raw));
      return KeyEventResult.handled;
    }
    if (command && key == LogicalKeyboardKey.keyA) {
      _selectAll();
      return KeyEventResult.handled;
    }
    final step = switch (key) {
      LogicalKeyboardKey.pageUp => -LogTable.pageRows,
      LogicalKeyboardKey.pageDown => LogTable.pageRows,
      LogicalKeyboardKey.arrowUp => -1,
      LogicalKeyboardKey.arrowDown => 1,
      _ => 0,
    };
    if (step != 0 && !command) {
      _moveCursor(step, extend: keyboard.isShiftPressed);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape && _hasSelection) {
      setState(() => _selectOnly(null));
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  // ---- Keyboard navigation --------------------------------------------

  /// Index of the first row at least partly visible.
  int _firstVisibleRow() {
    if (!_vertical.hasClients || widget.itemCount == 0) return 0;
    if (widget.wrap) {
      return _list.isAttached ? (_list.visibleRange?.$1 ?? 0) : 0;
    }
    return (_vertical.position.pixels / _rowHeight)
        .floor()
        .clamp(0, widget.itemCount - 1);
  }

  /// Row of the selection focus and whether that line is in this table;
  /// if not, the row is the first one after it. Without a selection, the
  /// first visible row (not exact).
  (int, bool) _cursorRow() {
    final line = _focusLine ?? _anchorLine;
    if (line == null) return (_firstVisibleRow(), false);
    final row = _lowerBound(line);
    return (
      row,
      row < widget.itemCount && widget.entryAt(row).lineNumber == line
    );
  }

  /// Moves the selection by [delta] rows; [extend] keeps the anchor.
  void _moveCursor(int delta, {required bool extend}) {
    if (widget.itemCount == 0) return;
    final hasCursor = _focusLine != null || _anchorLine != null;
    final (row, exact) = _cursorRow();
    final int target;
    if (!hasCursor) {
      target = row;
    } else if (exact) {
      target = row + delta;
    } else {
      // [row] is the first row after the cursor.
      target = delta > 0 ? row + delta - 1 : row + delta;
    }
    final index = target.clamp(0, widget.itemCount - 1);
    final line = widget.entryAt(index).lineNumber;
    setState(() {
      if (extend && _anchorLine != null) {
        _committed.clear();
        _focusLine = line;
      } else {
        _selectOnly(line);
      }
    });
    if (index < widget.itemCount - 1) _setFollow(false);
    _ensureVisible(index);
  }

  /// Scrolls the least amount needed to show row [index] in full.
  void _ensureVisible(int index) {
    if (!_vertical.hasClients) return;
    if (widget.wrap) {
      if (!_list.isAttached) return;
      final range = _list.visibleRange;
      // Edge rows may be cut off, so they are aligned too.
      if (range == null || index <= range.$1) {
        _list.jumpToItem(
            index: index, scrollController: _vertical, alignment: 0);
      } else if (index >= range.$2) {
        _list.jumpToItem(
            index: index, scrollController: _vertical, alignment: 1);
      }
      return;
    }
    final pos = _vertical.position;
    final top = index * _rowHeight;
    final bottom = top + _rowHeight;
    double? target;
    if (top < pos.pixels) {
      target = top;
    } else if (bottom > pos.pixels + pos.viewportDimension) {
      target = bottom - pos.viewportDimension;
    }
    if (target != null) {
      _vertical.jumpTo(target.clamp(0.0, pos.maxScrollExtent));
    }
  }

  RenderBox? get _viewport =>
      _viewportKey.currentContext?.findRenderObject() as RenderBox?;

  /// Row index under [global], found through the rows' [MetaData] tags so
  /// it works for fixed and variable row heights alike.
  int? _indexAt(Offset global) {
    final result = HitTestResult();
    WidgetsBinding.instance
        .hitTestInView(result, global, View.of(context).viewId);
    for (final entry in result.path) {
      final target = entry.target;
      if (target is RenderMetaData) {
        final tag = target.metaData;
        if (tag is _RowTag && tag.owner == this) return tag.index;
      }
    }
    return null;
  }

  void _onPointerDown(PointerDownEvent e) {
    _pointerDown = true;
    if (e.kind != PointerDeviceKind.mouse &&
        e.kind != PointerDeviceKind.touch &&
        e.kind != PointerDeviceKind.stylus) {
      return;
    }
    if (e.buttons & kPrimaryButton == 0) return;
    final box = _viewport;
    if (box == null) return;
    // Leave the scrollbar to itself.
    if (box.globalToLocal(e.position).dx > box.size.width - 14) return;
    final index = _indexAt(e.position);
    if (index == null) return;
    _focusNode.requestFocus();
    final entry = widget.entryAt(index);
    final line = entry.lineNumber;
    final keyboard = HardwareKeyboard.instance;
    final shift = keyboard.isShiftPressed;
    final command = keyboard.isControlPressed || keyboard.isMetaPressed;
    var selects = true;
    setState(() {
      if (shift && _anchorLine != null) {
        // Shift: range from the anchor; with Ctrl/Cmd keep the rest.
        if (!command) _committed.clear();
        _focusLine = line;
      } else if (command && _isSelected(line)) {
        // Ctrl/Cmd+click on a selected row removes just that row.
        _commitActive();
        _committed.remove(line);
        _anchorLine = line;
        selects = false;
      } else if (command) {
        // Ctrl/Cmd+click or drag adds a new range to the selection.
        _commitActive();
        _anchorLine = _focusLine = line;
      } else {
        _selectOnly(line);
      }
    });
    _dragging = true;
    _dragMoved = false;
    _dragShift = shift;
    _dragCommand = command;
    _dragSelects = selects;
    _downEntry = entry;
    _dragPosition = e.position;
  }

  void _onPointerMove(PointerMoveEvent e) {
    if (!_dragging) return;
    _dragPosition = e.position;
    _extendDrag();
  }

  void _onPointerUp(PointerEvent e) {
    _pointerDown = false;
    if (!_dragging) return;
    _dragging = false;
    _autoScroll?.cancel();
    _autoScroll = null;
    final entry = _downEntry;
    if (e is PointerUpEvent &&
        !_dragMoved &&
        !_dragShift &&
        !_dragCommand &&
        entry != null) {
      widget.onRowTap?.call(entry);
    }
  }

  /// Moves the selection focus to the row under the pointer, clamped to the
  /// viewport, and auto-scrolls while the pointer is above or below it.
  void _extendDrag() {
    final box = _viewport, position = _dragPosition;
    if (box == null || position == null || !mounted || !_dragSelects) return;
    final local = box.globalToLocal(position);
    final height = box.size.height;
    final outside = local.dy < 0 || local.dy > height;
    if (outside && _autoScroll == null) {
      _autoScroll = Timer.periodic(
          const Duration(milliseconds: 16), (_) => _autoScrollTick());
    } else if (!outside) {
      _autoScroll?.cancel();
      _autoScroll = null;
    }
    final probe = box.localToGlobal(Offset(
      math.min(20, box.size.width / 2),
      local.dy.clamp(1.0, math.max(1.0, height - 1)),
    ));
    final index = _indexAt(probe);
    if (index == null) return;
    final line = widget.entryAt(index).lineNumber;
    if (line == _focusLine) return;
    _dragMoved = true;
    setState(() => _focusLine = line);
  }

  void _autoScrollTick() {
    final box = _viewport, position = _dragPosition;
    if (!_dragging ||
        box == null ||
        position == null ||
        !_vertical.hasClients) {
      _autoScroll?.cancel();
      _autoScroll = null;
      return;
    }
    final dy = box.globalToLocal(position).dy;
    final overshoot = dy < 0 ? dy : dy - box.size.height;
    // Faster the further the pointer is from the edge.
    final delta = overshoot.sign *
        math.max(_rowHeight / 2, math.min(overshoot.abs(), 300) / 3);
    final pos = _vertical.position;
    final target = (pos.pixels + delta).clamp(0.0, pos.maxScrollExtent);
    if (target != pos.pixels) {
      if (_follow && delta < 0) _setFollow(false);
      _vertical.jumpTo(target);
    }
    _extendDrag();
  }

  Future<void> _showRowMenu(LogEntry entry, Offset position) async {
    if (!_isSelected(entry.lineNumber)) {
      setState(() => _selectOnly(entry.lineNumber));
    }
    _focusNode.requestFocus();
    final l10n = context.l10n;
    final overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final process = widget.processLabel(entry);
    final count = _selectedCount;

    PopupMenuItem<String Function()> item(
            IconData icon, String label, String Function() text) =>
        PopupMenuItem(
          value: text,
          child: ListTile(leading: Icon(icon), title: Text(label)),
        );

    final text = await showMenu<String Function()>(
      context: context,
      position: RelativeRect.fromRect(
          position & const Size(1, 1), Offset.zero & overlay.size),
      items: count > 1
          ? [
              item(Icons.content_copy, l10n.copyLines(count),
                  () => _selectionText((e) => e.raw)),
              item(Icons.notes, l10n.copyMessages(count),
                  () => _selectionText((e) => e.message)),
              item(Icons.table_rows_outlined, l10n.copyRows(count),
                  () => _selectionText(_rowText)),
              const PopupMenuDivider(),
              item(Icons.select_all, l10n.selectAll, () => ''),
            ]
          : [
              item(Icons.content_copy, l10n.copyLine, () => entry.raw),
              item(Icons.notes, l10n.copyMessage, () => entry.message),
              if (process.isNotEmpty)
                item(Icons.memory, l10n.copyProcessName, () => process),
              item(Icons.table_rows_outlined, l10n.copyRow,
                  () => _rowText(entry)),
              const PopupMenuDivider(),
              item(Icons.select_all, l10n.selectAll, () => ''),
            ],
    );
    if (text == null || !mounted) return;
    final value = text();
    if (value.isEmpty) {
      _selectAll();
    } else {
      await _copy(value);
    }
  }

  Widget _buildRow(ThemeData theme, int index) {
    final entry = widget.entryAt(index);
    final selected = _isSelected(entry.lineNumber);
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

    return MetaData(
      metaData: _RowTag(this, index),
      behavior: HitTestBehavior.translucent,
      child: Material(
        color: background ?? Colors.transparent,
        child: InkWell(
          // Selection and onRowTap are handled by the pointer listener; this
          // only provides hover and splash feedback.
          onTap: () {},
          onSecondaryTapUp: (d) => _showRowMenu(entry, d.globalPosition),
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
      ),
    );
  }
}

/// Identifies a row of a [LogTable] for hit testing.
class _RowTag {
  const _RowTag(this.owner, this.index);

  final _LogTableState owner;
  final int index;
}

/// Sorted, non-overlapping, non-adjacent inclusive ranges of line numbers.
class _LineRanges {
  _LineRanges();

  _LineRanges.from(_LineRanges other) {
    _ranges.addAll(other._ranges);
  }

  final List<(int, int)> _ranges = [];

  List<(int, int)> get ranges => List.unmodifiable(_ranges);
  bool get isEmpty => _ranges.isEmpty;

  void clear() => _ranges.clear();

  /// Index of the first range whose end is >= [line].
  int _search(int line) {
    var lo = 0, hi = _ranges.length;
    while (lo < hi) {
      final mid = (lo + hi) >> 1;
      if (_ranges[mid].$2 < line) {
        lo = mid + 1;
      } else {
        hi = mid;
      }
    }
    return lo;
  }

  bool contains(int line) {
    final i = _search(line);
    return i < _ranges.length && _ranges[i].$1 <= line;
  }

  void add(int first, int last) {
    // Merge with every range that overlaps or touches [first, last].
    var i = _search(first - 1);
    var start = first, end = last;
    while (i < _ranges.length && _ranges[i].$1 <= last + 1) {
      start = math.min(start, _ranges[i].$1);
      end = math.max(end, _ranges[i].$2);
      _ranges.removeAt(i);
    }
    _ranges.insert(i, (start, end));
  }

  void remove(int line) {
    final i = _search(line);
    if (i >= _ranges.length || _ranges[i].$1 > line) return;
    final (first, last) = _ranges[i];
    _ranges.removeAt(i);
    if (line < last) _ranges.insert(i, (line + 1, last));
    if (first < line) _ranges.insert(i, (first, line - 1));
  }
}
