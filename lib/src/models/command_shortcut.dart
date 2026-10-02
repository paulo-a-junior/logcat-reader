import 'dart:math';

/// What a [CommandShortcut] runs.
enum ShortcutKind {
  /// `adb shell <command>` on the selected device.
  shell,

  /// `adb <arguments>` against the selected device.
  adb,

  /// A command or script on this computer.
  host,
}

/// Where a shortcut's output goes once it finishes.
enum ShortcutOutput {
  /// A short notification; output is still kept in the Shell console.
  notify,

  /// Switch to the Shell view.
  console,
}

/// A user-defined, persisted command.
class CommandShortcut {
  const CommandShortcut({
    required this.id,
    required this.name,
    required this.command,
    this.kind = ShortcutKind.shell,
    this.output = ShortcutOutput.notify,
    this.confirm = false,
    this.pinned = false,
    this.iconIndex = 0,
  });

  final String id;
  final String name;
  final String command;
  final ShortcutKind kind;
  final ShortcutOutput output;

  /// Ask before running.
  final bool confirm;

  /// Show as a button in the toolbar.
  final bool pinned;
  final int iconIndex;

  static final _random = Random();
  static String newId() =>
      '${DateTime.now().microsecondsSinceEpoch}-${_random.nextInt(1 << 32)}';

  CommandShortcut copyWith({
    String? id,
    String? name,
    String? command,
    ShortcutKind? kind,
    ShortcutOutput? output,
    bool? confirm,
    bool? pinned,
    int? iconIndex,
  }) =>
      CommandShortcut(
        id: id ?? this.id,
        name: name ?? this.name,
        command: command ?? this.command,
        kind: kind ?? this.kind,
        output: output ?? this.output,
        confirm: confirm ?? this.confirm,
        pinned: pinned ?? this.pinned,
        iconIndex: iconIndex ?? this.iconIndex,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'command': command,
        'kind': kind.name,
        'output': output.name,
        'confirm': confirm,
        'pinned': pinned,
        'icon': iconIndex,
      };

  factory CommandShortcut.fromJson(Map<String, Object?> json) =>
      CommandShortcut(
        id: json['id'] as String? ?? newId(),
        name: json['name'] as String? ?? '',
        command: json['command'] as String? ?? '',
        kind:
            ShortcutKind.values.asNameMap()[json['kind']] ?? ShortcutKind.shell,
        output: ShortcutOutput.values.asNameMap()[json['output']] ??
            ShortcutOutput.notify,
        confirm: json['confirm'] as bool? ?? false,
        pinned: json['pinned'] as bool? ?? false,
        iconIndex: json['icon'] as int? ?? 0,
      );
}
