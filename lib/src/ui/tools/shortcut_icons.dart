import 'package:flutter/material.dart';

/// Icons a shortcut can use, indexed by [CommandShortcut.iconIndex].
const shortcutIcons = <IconData>[
  Icons.bolt,
  Icons.home,
  Icons.arrow_back,
  Icons.power_settings_new,
  Icons.visibility,
  Icons.info_outline,
  Icons.terminal,
  Icons.description,
  Icons.bug_report,
  Icons.restart_alt,
  Icons.cleaning_services,
  Icons.wifi,
  Icons.settings,
  Icons.play_arrow,
  Icons.screenshot_monitor,
  Icons.build,
];

IconData shortcutIcon(int index) =>
    shortcutIcons[index.clamp(0, shortcutIcons.length - 1)];
