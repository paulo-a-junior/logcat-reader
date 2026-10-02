import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Logcat Reader';

  @override
  String get selectDevice => 'Select a device';

  @override
  String get noDevicesFound => 'No devices found';

  @override
  String get refreshDevices => 'Refresh devices';

  @override
  String get connectViaIp => 'Connect via IP (adb connect)';

  @override
  String get startLogcat => 'Start logcat';

  @override
  String get stop => 'Stop';

  @override
  String get openFile => 'Open file';

  @override
  String get clearLogs => 'Clear logs';

  @override
  String get preferences => 'Preferences';

  @override
  String get fileTypeLogs => 'Log files';

  @override
  String get fileTypeAll => 'All files';

  @override
  String get connectDialogTitle => 'Connect via IP';

  @override
  String get address => 'Address';

  @override
  String get cancel => 'Cancel';

  @override
  String get connect => 'Connect';

  @override
  String get columnLine => 'Line';

  @override
  String get columnProcess => 'Process Name';

  @override
  String get columnMessage => 'Log Message';

  @override
  String get tableRaw => 'Raw';

  @override
  String get tableFiltered => 'Filtered';

  @override
  String lineCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$countString lines',
      one: '1 line',
    );
    return '$_temp0';
  }

  @override
  String get saveLog => 'Save log';

  @override
  String saveAllLines(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Save all lines ($countString)…';
  }

  @override
  String saveFilteredLines(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return 'Save filtered lines ($countString)…';
  }

  @override
  String get saveLogEmpty => 'There are no lines to save';

  @override
  String saveLogDone(int count, String path) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saved $countString lines to $path',
      one: 'Saved 1 line to $path',
    );
    return '$_temp0';
  }

  @override
  String saveLogFailed(String path, String error) {
    return 'Could not save $path: $error';
  }

  @override
  String get copyLine => 'Copy line';

  @override
  String get copyMessage => 'Copy message';

  @override
  String get copyProcessName => 'Copy process name';

  @override
  String get copyRow => 'Copy row (line, process, message)';

  @override
  String get copiedToClipboard => 'Copied to clipboard';

  @override
  String copyLines(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copy $countString lines',
      one: 'Copy 1 line',
    );
    return '$_temp0';
  }

  @override
  String copyMessages(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copy $countString messages',
      one: 'Copy 1 message',
    );
    return '$_temp0';
  }

  @override
  String copyRows(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Copy $countString rows (line, process, message)',
      one: 'Copy 1 row (line, process, message)',
    );
    return '$_temp0';
  }

  @override
  String selectedCount(int count) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    return '$countString selected';
  }

  @override
  String get selectAll => 'Select all';

  @override
  String get followingNewLines => 'Following new lines';

  @override
  String get followNewLines => 'Follow new lines';

  @override
  String get filterMessage => 'Message';

  @override
  String get filterMessageHintText => 'Text';

  @override
  String get filterMessageHintRegex => 'Regular expression';

  @override
  String get regularExpression => 'Regular expression';

  @override
  String get caseSensitive => 'Case sensitive';

  @override
  String get filterProcess => 'Process';

  @override
  String get filterProcessHint => 'Name or PID';

  @override
  String get filterTag => 'Tag';

  @override
  String get filterMinLevel => 'Min level';

  @override
  String get levelVerbose => 'Verbose';

  @override
  String get levelDebug => 'Debug';

  @override
  String get levelInfo => 'Info';

  @override
  String get levelWarn => 'Warning';

  @override
  String get levelError => 'Error';

  @override
  String get levelFatal => 'Fatal';

  @override
  String statusStarting(String source) {
    return 'Starting logcat on $source…';
  }

  @override
  String statusStreaming(String source) {
    return 'Streaming from $source';
  }

  @override
  String statusEnded(String source) {
    return 'logcat on $source ended';
  }

  @override
  String statusReconnecting(String source, int attempt) {
    return 'Connection to $source lost — reconnecting (attempt $attempt)…';
  }

  @override
  String get statusStopped => 'Stopped';

  @override
  String statusLoading(String path) {
    return 'Loading $path…';
  }

  @override
  String statusLoaded(int count, String path) {
    final intl.NumberFormat countNumberFormat = intl.NumberFormat.decimalPattern(localeName);
    final String countString = countNumberFormat.format(count);

    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Loaded $countString lines from $path',
      one: 'Loaded 1 line from $path',
    );
    return '$_temp0';
  }

  @override
  String statusReadFailed(String path, String error) {
    return 'Failed to read $path: $error';
  }

  @override
  String adbNotFound(String adb) {
    return 'Could not run \"$adb\". Choose the adb executable in Preferences, put adb on PATH or set the ADB environment variable.';
  }

  @override
  String notifyConnectionLost(String source) {
    return 'Connection to $source lost';
  }

  @override
  String notifyReconnected(String source) {
    return 'Reconnected to $source';
  }

  @override
  String notifyRootFailed(String source, String message) {
    return 'Could not switch adbd mode on $source: $message';
  }

  @override
  String notifyWideEncoding(String encoding) {
    return 'This file is $encoding, not UTF-8. It was converted for viewing; the file on disk is unchanged.';
  }

  @override
  String notifyRebooted(String source) {
    return '$source rebooted — logcat resumed';
  }

  @override
  String notifyJavaCrash(String process) {
    return 'Crash (FATAL EXCEPTION) in $process';
  }

  @override
  String notifyAnr(String process) {
    return 'ANR in $process';
  }

  @override
  String notifyNativeCrash(String process) {
    return 'Native crash in $process';
  }

  @override
  String get show => 'Show';

  @override
  String get sectionDevice => 'Device';

  @override
  String get adbRoot => 'Run adb as root';

  @override
  String get adbRootSubtitle => 'Restart adbd with adb root before reading logs (userdebug/eng builds only)';

  @override
  String get autoReconnect => 'Auto-reconnect';

  @override
  String get autoReconnectSubtitle => 'Resume logcat when the device disconnects or reboots';

  @override
  String get adbPath => 'adb executable';

  @override
  String get adbPathSubtitle => 'Leave empty to use the ADB environment variable or adb from PATH';

  @override
  String adbPathHint(String path) {
    return 'Default: $path';
  }

  @override
  String get adbPathBrowse => 'Browse…';

  @override
  String get adbPathUseDefault => 'Use default';

  @override
  String get adbPathCheck => 'Check adb';

  @override
  String get adbPathChecking => 'Checking…';

  @override
  String get sectionDisplay => 'Display';

  @override
  String get longLines => 'Long lines';

  @override
  String get longLinesEllipsis => 'Ellipsis';

  @override
  String get longLinesWrap => 'Wrap';

  @override
  String get theme => 'Theme';

  @override
  String get themeSystem => 'System';

  @override
  String get themeLight => 'Light';

  @override
  String get themeDark => 'Dark';

  @override
  String get fontSize => 'Log font size';

  @override
  String get sectionNotifications => 'Notifications';

  @override
  String get notifyOnConnectionLost => 'Connection lost';

  @override
  String get notifyOnReconnected => 'Reconnected';

  @override
  String get notifyOnCrash => 'App crashes';

  @override
  String get notifyOnCrashSubtitle => 'FATAL EXCEPTION, ANR and native crashes in live logs';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System default';

  @override
  String get resetDefaults => 'Reset to defaults';

  @override
  String get close => 'Close';

  @override
  String get filters => 'Filters';

  @override
  String get manageFilters => 'Manage filters';

  @override
  String get addFilter => 'Add filter';

  @override
  String get newFilterName => 'New filter';

  @override
  String get editFilter => 'Edit filter';

  @override
  String get duplicateFilter => 'Duplicate';

  @override
  String get deleteFilter => 'Delete';

  @override
  String get deleteFilterTitle => 'Delete filter?';

  @override
  String deleteFilterConfirm(String name) {
    return 'The filter \"$name\" will be removed.';
  }

  @override
  String filterCopyName(String name) {
    return '$name (copy)';
  }

  @override
  String get edit => 'Edit';

  @override
  String get save => 'Save';

  @override
  String get filterName => 'Name';

  @override
  String get filterColor => 'Colour';

  @override
  String get filterMode => 'Matching lines';

  @override
  String get filterModeInclude => 'Show';

  @override
  String get filterModeExclude => 'Hide';

  @override
  String get filterCriteria => 'Criteria';

  @override
  String get combineAny => 'Any';

  @override
  String get combineAll => 'All';

  @override
  String get combineTooltip => 'Show lines matching any or all of the enabled filters';

  @override
  String get enableAllFilters => 'Enable all';

  @override
  String get disableAllFilters => 'Disable all';

  @override
  String get noFilterSelected => 'Select a filter to edit it, or add a new one.';

  @override
  String get noFilters => 'No filters yet';

  @override
  String get noActiveFilters => 'No filter enabled — enable a filter to see lines';

  @override
  String get summaryMatchesAll => 'Matches every line';

  @override
  String summaryLevel(String level) {
    return 'level ≥ $level';
  }

  @override
  String summaryTag(String tag) {
    return 'tag: $tag';
  }

  @override
  String summaryProcess(String process) {
    return 'process: $process';
  }

  @override
  String get summaryExclude => 'hides matches';

  @override
  String invalidRegex(String error) {
    return 'Invalid regular expression: $error';
  }

  @override
  String get filterEnabled => 'Enabled';

  @override
  String get navLogs => 'Logs';

  @override
  String get navApps => 'Apps';

  @override
  String get navFiles => 'Files';

  @override
  String get navShell => 'Shell';

  @override
  String get navShortcuts => 'Shortcuts';

  @override
  String get noDeviceSelected => 'Select a connected device in the toolbar to use this view.';

  @override
  String get deviceMenu => 'Device actions';

  @override
  String get reboot => 'Reboot';

  @override
  String get rebootRecovery => 'Reboot to recovery';

  @override
  String get rebootBootloader => 'Reboot to bootloader';

  @override
  String get rebootConfirmTitle => 'Reboot device?';

  @override
  String rebootConfirm(String device, String mode) {
    return '$device will restart ($mode).';
  }

  @override
  String rebootSent(String device) {
    return 'Reboot command sent to $device';
  }

  @override
  String get takeScreenshot => 'Take screenshot…';

  @override
  String screenshotSaved(String path) {
    return 'Screenshot saved to $path';
  }

  @override
  String get installApk => 'Install APK…';

  @override
  String installing(String name) {
    return 'Installing $name…';
  }

  @override
  String installed(String name) {
    return '$name installed';
  }

  @override
  String get fileTypeApk => 'Android packages';

  @override
  String get fileTypePng => 'PNG images';

  @override
  String get refresh => 'Refresh';

  @override
  String get searchPackages => 'Search packages';

  @override
  String get showSystemApps => 'System apps';

  @override
  String get systemBadge => 'system';

  @override
  String packageCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count packages',
      one: '1 package',
    );
    return '$_temp0';
  }

  @override
  String get launchApp => 'Launch';

  @override
  String get forceStop => 'Force stop';

  @override
  String get clearData => 'Clear data';

  @override
  String get uninstall => 'Uninstall';

  @override
  String get saveApk => 'Save APK…';

  @override
  String uninstallTitle(String name) {
    return 'Uninstall $name?';
  }

  @override
  String clearDataTitle(String name) {
    return 'Clear data of $name?';
  }

  @override
  String get cannotUndo => 'This cannot be undone.';

  @override
  String doneMessage(String action, String name) {
    return '$action: $name';
  }

  @override
  String get goUp => 'Parent folder';

  @override
  String get path => 'Path';

  @override
  String get pushFiles => 'Push files…';

  @override
  String get pull => 'Pull…';

  @override
  String get newFolder => 'New folder';

  @override
  String get folderName => 'Folder name';

  @override
  String get create => 'Create';

  @override
  String get delete => 'Delete';

  @override
  String deleteFileTitle(String name) {
    return 'Delete $name?';
  }

  @override
  String get emptyFolder => 'This folder is empty';

  @override
  String get columnName => 'Name';

  @override
  String get columnSize => 'Size';

  @override
  String get columnModified => 'Modified';

  @override
  String transferring(String name) {
    return 'Transferring $name…';
  }

  @override
  String pushDone(int count, String path) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count files sent to $path',
      one: '1 file sent to $path',
    );
    return '$_temp0';
  }

  @override
  String pullDone(String path) {
    return 'Saved to $path';
  }

  @override
  String get shellHint => 'Command to run on the device (adb shell) — ↑/↓ for history';

  @override
  String get run => 'Run';

  @override
  String get clearConsole => 'Clear finished';

  @override
  String exitCode(int code) {
    return 'exit $code';
  }

  @override
  String get stopped => 'stopped';

  @override
  String get running => 'running…';

  @override
  String get outputTruncated => '(output truncated)';

  @override
  String get consoleEmpty => 'Run a command or a shortcut to see its output here.';

  @override
  String get copyOutput => 'Copy output';

  @override
  String get copied => 'Copied';

  @override
  String get addShortcut => 'Add shortcut';

  @override
  String get editShortcut => 'Edit shortcut';

  @override
  String get newShortcutName => 'New shortcut';

  @override
  String get deleteShortcutTitle => 'Delete shortcut?';

  @override
  String deleteShortcutConfirm(String name) {
    return 'The shortcut \"$name\" will be removed.';
  }

  @override
  String get manageShortcuts => 'Manage shortcuts…';

  @override
  String get noShortcuts => 'No shortcuts yet';

  @override
  String get shortcutName => 'Name';

  @override
  String get shortcutCommand => 'Command';

  @override
  String get shortcutKind => 'Runs';

  @override
  String get kindShell => 'adb shell';

  @override
  String get kindAdb => 'adb';

  @override
  String get kindHost => 'This computer';

  @override
  String get kindShellHint => 'Runs in the device shell, e.g. input keyevent KEYCODE_HOME';

  @override
  String get kindAdbHint => 'adb arguments for the selected device, e.g. install -r /path/app.apk';

  @override
  String get kindHostHint => 'Command or script on this computer; ANDROID_SERIAL and ADB are set';

  @override
  String get shortcutOutput => 'When finished';

  @override
  String get outputNotify => 'Notify';

  @override
  String get outputConsole => 'Open Shell view';

  @override
  String get shortcutConfirm => 'Ask before running';

  @override
  String get shortcutPinned => 'Show in toolbar';

  @override
  String get shortcutIcon => 'Icon';

  @override
  String runShortcutTitle(String name) {
    return 'Run \"$name\"?';
  }

  @override
  String shortcutDone(String name) {
    return '$name: done';
  }

  @override
  String shortcutFailed(String name, int code) {
    return '$name failed (exit $code)';
  }

  @override
  String shortcutNeedsDevice(String name) {
    return 'Select a connected device to run \"$name\"';
  }

  @override
  String get commandRequired => 'Enter a command';
}
