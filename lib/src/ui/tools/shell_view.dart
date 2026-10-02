import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../adb/device_selection.dart';
import '../../tools/shell_console.dart';
import '../l10n_helpers.dart';
import 'tool_helpers.dart';

/// Console for one-shot `adb shell` commands; also shows shortcut output.
class ShellView extends StatefulWidget {
  const ShellView({
    super.key,
    required this.console,
    required this.devices,
    required this.fontSize,
  });

  final ShellConsole console;
  final DeviceSelection devices;
  final double fontSize;

  @override
  State<ShellView> createState() => _ShellViewState();
}

class _ShellViewState extends State<ShellView> {
  final _input = TextEditingController();
  final _focus = FocusNode();
  final _scroll = ScrollController();

  /// Position in [ShellConsole.history] while browsing with ↑/↓.
  int? _historyIndex;
  int _lastRunCount = 0;

  ShellConsole get _console => widget.console;

  @override
  void initState() {
    super.initState();
    _console.addListener(_onConsole);
  }

  @override
  void dispose() {
    _console.removeListener(_onConsole);
    _input.dispose();
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _onConsole() {
    if (_console.runs.length > _lastRunCount) _scrollToEnd();
    _lastRunCount = _console.runs.length;
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.jumpTo(_scroll.position.maxScrollExtent);
      }
    });
  }

  void _submit() {
    final serial = widget.devices.onlineSerial;
    final command = _input.text.trim();
    if (serial == null || command.isEmpty) return;
    _console.remember(command);
    _historyIndex = null;
    _input.clear();
    _console.runShell(serial, command);
    _focus.requestFocus();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final history = _console.history;
    if (history.isEmpty) return KeyEventResult.ignored;
    if (event.logicalKey == LogicalKeyboardKey.arrowUp) {
      _historyIndex =
          ((_historyIndex ?? history.length) - 1).clamp(0, history.length - 1);
    } else if (event.logicalKey == LogicalKeyboardKey.arrowDown) {
      if (_historyIndex == null) return KeyEventResult.handled;
      final next = _historyIndex! + 1;
      _historyIndex = next >= history.length ? null : next;
    } else {
      return KeyEventResult.ignored;
    }
    final text = _historyIndex == null ? '' : history[_historyIndex!];
    _input.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return ListenableBuilder(
      listenable: Listenable.merge([_console, widget.devices]),
      builder: (context, _) {
        final serial = widget.devices.onlineSerial;
        final runs = _console.runs;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
              child: Row(
                children: [
                  Text(l10n.navShell, style: theme.textTheme.titleMedium),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.devices.selected?.label ?? '',
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed:
                        runs.any((r) => !r.running) ? _console.clear : null,
                    icon: const Icon(Icons.clear_all),
                    label: Text(l10n.clearConsole),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: runs.isEmpty
                  ? Center(
                      child: Text(l10n.consoleEmpty,
                          style: theme.textTheme.bodyLarge),
                    )
                  : SelectionArea(
                      child: ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(8),
                        itemCount: runs.length,
                        itemBuilder: (context, i) => _RunBlock(
                          key: ObjectKey(runs[i]),
                          run: runs[i],
                          fontSize: widget.fontSize,
                          onOutput: i == runs.length - 1 ? _maybeFollow : null,
                        ),
                      ),
                    ),
            ),
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(8),
              child: serial == null
                  ? Text(l10n.noDeviceSelected,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium)
                  : Row(
                      children: [
                        const Text('\$',
                            style: TextStyle(
                                fontFamily: 'monospace', fontSize: 16)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Focus(
                            onKeyEvent: _onKey,
                            child: TextField(
                              controller: _input,
                              focusNode: _focus,
                              style: const TextStyle(fontFamily: 'monospace'),
                              decoration: InputDecoration(
                                isDense: true,
                                hintText: l10n.shellHint,
                                border: const OutlineInputBorder(),
                              ),
                              onSubmitted: (_) => _submit(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.play_arrow),
                          label: Text(l10n.run),
                        ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  /// Keeps the console pinned to the bottom while the last run streams,
  /// unless the user scrolled up.
  void _maybeFollow() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.maxScrollExtent - pos.pixels < 80) _scrollToEnd();
  }
}

class _RunBlock extends StatefulWidget {
  const _RunBlock({
    super.key,
    required this.run,
    required this.fontSize,
    this.onOutput,
  });

  final ConsoleRun run;
  final double fontSize;
  final VoidCallback? onOutput;

  @override
  State<_RunBlock> createState() => _RunBlockState();
}

class _RunBlockState extends State<_RunBlock> {
  @override
  void initState() {
    super.initState();
    widget.run.addListener(_changed);
  }

  @override
  void didUpdateWidget(_RunBlock old) {
    super.didUpdateWidget(old);
    if (old.run != widget.run) {
      old.run.removeListener(_changed);
      widget.run.addListener(_changed);
    }
  }

  @override
  void dispose() {
    widget.run.removeListener(_changed);
    super.dispose();
  }

  void _changed() {
    setState(() {});
    widget.onOutput?.call();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final run = widget.run;
    final mono = TextStyle(fontFamily: 'monospace', fontSize: widget.fontSize);
    final failed = !run.running && run.exitCode != 0 && !run.stopped;
    final status = run.running
        ? l10n.running
        : run.stopped
            ? l10n.stopped
            : l10n.exitCode(run.exitCode!);
    final time = TimeOfDay.fromDateTime(run.started).format(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(
              width: 3,
              color: run.running
                  ? colors.primary
                  : failed
                      ? colors.error
                      : colors.outlineVariant,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(run.title,
                        style: mono.copyWith(
                            fontWeight: FontWeight.bold,
                            color: colors.primary)),
                  ),
                  Text('$time · $status',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: failed ? colors.error : null)),
                  if (run.running)
                    IconButton(
                      tooltip: l10n.stop,
                      visualDensity: VisualDensity.compact,
                      onPressed: run.stop,
                      icon: const Icon(Icons.stop, size: 18),
                    )
                  else if (run.output.isNotEmpty)
                    IconButton(
                      tooltip: l10n.copyOutput,
                      visualDensity: VisualDensity.compact,
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: run.output));
                        showToolMessage(context, l10n.copied);
                      },
                      icon: const Icon(Icons.copy, size: 16),
                    ),
                ],
              ),
              if (run.output.isNotEmpty)
                Text(run.output.trimRight(), style: mono),
              if (run.truncated)
                Text(l10n.outputTruncated,
                    style: mono.copyWith(color: colors.error)),
            ],
          ),
        ),
      ),
    );
  }
}
