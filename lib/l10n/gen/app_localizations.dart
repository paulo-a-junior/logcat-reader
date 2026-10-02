import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_pt.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('pt')
  ];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Logcat Reader'**
  String get appTitle;

  /// No description provided for @selectDevice.
  ///
  /// In en, this message translates to:
  /// **'Select a device'**
  String get selectDevice;

  /// No description provided for @noDevicesFound.
  ///
  /// In en, this message translates to:
  /// **'No devices found'**
  String get noDevicesFound;

  /// No description provided for @refreshDevices.
  ///
  /// In en, this message translates to:
  /// **'Refresh devices'**
  String get refreshDevices;

  /// No description provided for @connectViaIp.
  ///
  /// In en, this message translates to:
  /// **'Connect via IP (adb connect)'**
  String get connectViaIp;

  /// No description provided for @startLogcat.
  ///
  /// In en, this message translates to:
  /// **'Start logcat'**
  String get startLogcat;

  /// No description provided for @stop.
  ///
  /// In en, this message translates to:
  /// **'Stop'**
  String get stop;

  /// No description provided for @openFile.
  ///
  /// In en, this message translates to:
  /// **'Open file'**
  String get openFile;

  /// No description provided for @clearLogs.
  ///
  /// In en, this message translates to:
  /// **'Clear logs'**
  String get clearLogs;

  /// No description provided for @preferences.
  ///
  /// In en, this message translates to:
  /// **'Preferences'**
  String get preferences;

  /// No description provided for @fileTypeLogs.
  ///
  /// In en, this message translates to:
  /// **'Log files'**
  String get fileTypeLogs;

  /// No description provided for @fileTypeAll.
  ///
  /// In en, this message translates to:
  /// **'All files'**
  String get fileTypeAll;

  /// No description provided for @connectDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Connect via IP'**
  String get connectDialogTitle;

  /// No description provided for @address.
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @connect.
  ///
  /// In en, this message translates to:
  /// **'Connect'**
  String get connect;

  /// No description provided for @columnLine.
  ///
  /// In en, this message translates to:
  /// **'Line'**
  String get columnLine;

  /// No description provided for @columnProcess.
  ///
  /// In en, this message translates to:
  /// **'Process Name'**
  String get columnProcess;

  /// No description provided for @columnMessage.
  ///
  /// In en, this message translates to:
  /// **'Log Message'**
  String get columnMessage;

  /// No description provided for @tableRaw.
  ///
  /// In en, this message translates to:
  /// **'Raw'**
  String get tableRaw;

  /// No description provided for @tableFiltered.
  ///
  /// In en, this message translates to:
  /// **'Filtered'**
  String get tableFiltered;

  /// No description provided for @lineCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 line} other{{count} lines}}'**
  String lineCount(int count);

  /// No description provided for @saveLog.
  ///
  /// In en, this message translates to:
  /// **'Save log'**
  String get saveLog;

  /// No description provided for @saveAllLines.
  ///
  /// In en, this message translates to:
  /// **'Save all lines ({count})…'**
  String saveAllLines(int count);

  /// No description provided for @saveFilteredLines.
  ///
  /// In en, this message translates to:
  /// **'Save filtered lines ({count})…'**
  String saveFilteredLines(int count);

  /// No description provided for @saveLogEmpty.
  ///
  /// In en, this message translates to:
  /// **'There are no lines to save'**
  String get saveLogEmpty;

  /// No description provided for @saveLogDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Saved 1 line to {path}} other{Saved {count} lines to {path}}}'**
  String saveLogDone(int count, String path);

  /// No description provided for @saveLogFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save {path}: {error}'**
  String saveLogFailed(String path, String error);

  /// No description provided for @copyLine.
  ///
  /// In en, this message translates to:
  /// **'Copy line'**
  String get copyLine;

  /// No description provided for @copyMessage.
  ///
  /// In en, this message translates to:
  /// **'Copy message'**
  String get copyMessage;

  /// No description provided for @copyProcessName.
  ///
  /// In en, this message translates to:
  /// **'Copy process name'**
  String get copyProcessName;

  /// No description provided for @copyRow.
  ///
  /// In en, this message translates to:
  /// **'Copy row (line, process, message)'**
  String get copyRow;

  /// No description provided for @copiedToClipboard.
  ///
  /// In en, this message translates to:
  /// **'Copied to clipboard'**
  String get copiedToClipboard;

  /// No description provided for @copyLines.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copy 1 line} other{Copy {count} lines}}'**
  String copyLines(int count);

  /// No description provided for @copyMessages.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copy 1 message} other{Copy {count} messages}}'**
  String copyMessages(int count);

  /// No description provided for @copyRows.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Copy 1 row (line, process, message)} other{Copy {count} rows (line, process, message)}}'**
  String copyRows(int count);

  /// No description provided for @selectedCount.
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedCount(int count);

  /// No description provided for @selectAll.
  ///
  /// In en, this message translates to:
  /// **'Select all'**
  String get selectAll;

  /// No description provided for @followingNewLines.
  ///
  /// In en, this message translates to:
  /// **'Following new lines'**
  String get followingNewLines;

  /// No description provided for @followNewLines.
  ///
  /// In en, this message translates to:
  /// **'Follow new lines'**
  String get followNewLines;

  /// No description provided for @filterMessage.
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get filterMessage;

  /// No description provided for @filterMessageHintText.
  ///
  /// In en, this message translates to:
  /// **'Text'**
  String get filterMessageHintText;

  /// No description provided for @filterMessageHintRegex.
  ///
  /// In en, this message translates to:
  /// **'Regular expression'**
  String get filterMessageHintRegex;

  /// No description provided for @regularExpression.
  ///
  /// In en, this message translates to:
  /// **'Regular expression'**
  String get regularExpression;

  /// No description provided for @caseSensitive.
  ///
  /// In en, this message translates to:
  /// **'Case sensitive'**
  String get caseSensitive;

  /// No description provided for @filterProcess.
  ///
  /// In en, this message translates to:
  /// **'Process'**
  String get filterProcess;

  /// No description provided for @filterProcessHint.
  ///
  /// In en, this message translates to:
  /// **'Name or PID'**
  String get filterProcessHint;

  /// No description provided for @filterTag.
  ///
  /// In en, this message translates to:
  /// **'Tag'**
  String get filterTag;

  /// No description provided for @filterMinLevel.
  ///
  /// In en, this message translates to:
  /// **'Min level'**
  String get filterMinLevel;

  /// No description provided for @levelVerbose.
  ///
  /// In en, this message translates to:
  /// **'Verbose'**
  String get levelVerbose;

  /// No description provided for @levelDebug.
  ///
  /// In en, this message translates to:
  /// **'Debug'**
  String get levelDebug;

  /// No description provided for @levelInfo.
  ///
  /// In en, this message translates to:
  /// **'Info'**
  String get levelInfo;

  /// No description provided for @levelWarn.
  ///
  /// In en, this message translates to:
  /// **'Warning'**
  String get levelWarn;

  /// No description provided for @levelError.
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get levelError;

  /// No description provided for @levelFatal.
  ///
  /// In en, this message translates to:
  /// **'Fatal'**
  String get levelFatal;

  /// No description provided for @statusStarting.
  ///
  /// In en, this message translates to:
  /// **'Starting logcat on {source}…'**
  String statusStarting(String source);

  /// No description provided for @statusStreaming.
  ///
  /// In en, this message translates to:
  /// **'Streaming from {source}'**
  String statusStreaming(String source);

  /// No description provided for @statusEnded.
  ///
  /// In en, this message translates to:
  /// **'logcat on {source} ended'**
  String statusEnded(String source);

  /// No description provided for @statusReconnecting.
  ///
  /// In en, this message translates to:
  /// **'Connection to {source} lost — reconnecting (attempt {attempt})…'**
  String statusReconnecting(String source, int attempt);

  /// No description provided for @statusStopped.
  ///
  /// In en, this message translates to:
  /// **'Stopped'**
  String get statusStopped;

  /// No description provided for @statusLoading.
  ///
  /// In en, this message translates to:
  /// **'Loading {path}…'**
  String statusLoading(String path);

  /// No description provided for @statusLoaded.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{Loaded 1 line from {path}} other{Loaded {count} lines from {path}}}'**
  String statusLoaded(int count, String path);

  /// No description provided for @statusReadFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to read {path}: {error}'**
  String statusReadFailed(String path, String error);

  /// No description provided for @adbNotFound.
  ///
  /// In en, this message translates to:
  /// **'Could not run \"{adb}\". Choose the adb executable in Preferences, put adb on PATH or set the ADB environment variable.'**
  String adbNotFound(String adb);

  /// No description provided for @notifyConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection to {source} lost'**
  String notifyConnectionLost(String source);

  /// No description provided for @notifyReconnected.
  ///
  /// In en, this message translates to:
  /// **'Reconnected to {source}'**
  String notifyReconnected(String source);

  /// No description provided for @notifyRebooted.
  ///
  /// In en, this message translates to:
  /// **'{source} rebooted — logcat resumed'**
  String notifyRebooted(String source);

  /// No description provided for @notifyJavaCrash.
  ///
  /// In en, this message translates to:
  /// **'Crash (FATAL EXCEPTION) in {process}'**
  String notifyJavaCrash(String process);

  /// No description provided for @notifyAnr.
  ///
  /// In en, this message translates to:
  /// **'ANR in {process}'**
  String notifyAnr(String process);

  /// No description provided for @notifyNativeCrash.
  ///
  /// In en, this message translates to:
  /// **'Native crash in {process}'**
  String notifyNativeCrash(String process);

  /// No description provided for @show.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get show;

  /// No description provided for @sectionDevice.
  ///
  /// In en, this message translates to:
  /// **'Device'**
  String get sectionDevice;

  /// No description provided for @autoReconnect.
  ///
  /// In en, this message translates to:
  /// **'Auto-reconnect'**
  String get autoReconnect;

  /// No description provided for @autoReconnectSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Resume logcat when the device disconnects or reboots'**
  String get autoReconnectSubtitle;

  /// No description provided for @adbPath.
  ///
  /// In en, this message translates to:
  /// **'adb executable'**
  String get adbPath;

  /// No description provided for @adbPathSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Leave empty to use the ADB environment variable or adb from PATH'**
  String get adbPathSubtitle;

  /// No description provided for @adbPathHint.
  ///
  /// In en, this message translates to:
  /// **'Default: {path}'**
  String adbPathHint(String path);

  /// No description provided for @adbPathBrowse.
  ///
  /// In en, this message translates to:
  /// **'Browse…'**
  String get adbPathBrowse;

  /// No description provided for @adbPathUseDefault.
  ///
  /// In en, this message translates to:
  /// **'Use default'**
  String get adbPathUseDefault;

  /// No description provided for @adbPathCheck.
  ///
  /// In en, this message translates to:
  /// **'Check adb'**
  String get adbPathCheck;

  /// No description provided for @adbPathChecking.
  ///
  /// In en, this message translates to:
  /// **'Checking…'**
  String get adbPathChecking;

  /// No description provided for @sectionDisplay.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get sectionDisplay;

  /// No description provided for @longLines.
  ///
  /// In en, this message translates to:
  /// **'Long lines'**
  String get longLines;

  /// No description provided for @longLinesEllipsis.
  ///
  /// In en, this message translates to:
  /// **'Ellipsis'**
  String get longLinesEllipsis;

  /// No description provided for @longLinesWrap.
  ///
  /// In en, this message translates to:
  /// **'Wrap'**
  String get longLinesWrap;

  /// No description provided for @theme.
  ///
  /// In en, this message translates to:
  /// **'Theme'**
  String get theme;

  /// No description provided for @themeSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get themeSystem;

  /// No description provided for @themeLight.
  ///
  /// In en, this message translates to:
  /// **'Light'**
  String get themeLight;

  /// No description provided for @themeDark.
  ///
  /// In en, this message translates to:
  /// **'Dark'**
  String get themeDark;

  /// No description provided for @fontSize.
  ///
  /// In en, this message translates to:
  /// **'Log font size'**
  String get fontSize;

  /// No description provided for @sectionNotifications.
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get sectionNotifications;

  /// No description provided for @notifyOnConnectionLost.
  ///
  /// In en, this message translates to:
  /// **'Connection lost'**
  String get notifyOnConnectionLost;

  /// No description provided for @notifyOnReconnected.
  ///
  /// In en, this message translates to:
  /// **'Reconnected'**
  String get notifyOnReconnected;

  /// No description provided for @notifyOnCrash.
  ///
  /// In en, this message translates to:
  /// **'App crashes'**
  String get notifyOnCrash;

  /// No description provided for @notifyOnCrashSubtitle.
  ///
  /// In en, this message translates to:
  /// **'FATAL EXCEPTION, ANR and native crashes in live logs'**
  String get notifyOnCrashSubtitle;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get languageSystem;

  /// No description provided for @resetDefaults.
  ///
  /// In en, this message translates to:
  /// **'Reset to defaults'**
  String get resetDefaults;

  /// No description provided for @close.
  ///
  /// In en, this message translates to:
  /// **'Close'**
  String get close;

  /// No description provided for @filters.
  ///
  /// In en, this message translates to:
  /// **'Filters'**
  String get filters;

  /// No description provided for @manageFilters.
  ///
  /// In en, this message translates to:
  /// **'Manage filters'**
  String get manageFilters;

  /// No description provided for @addFilter.
  ///
  /// In en, this message translates to:
  /// **'Add filter'**
  String get addFilter;

  /// No description provided for @newFilterName.
  ///
  /// In en, this message translates to:
  /// **'New filter'**
  String get newFilterName;

  /// No description provided for @editFilter.
  ///
  /// In en, this message translates to:
  /// **'Edit filter'**
  String get editFilter;

  /// No description provided for @duplicateFilter.
  ///
  /// In en, this message translates to:
  /// **'Duplicate'**
  String get duplicateFilter;

  /// No description provided for @deleteFilter.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteFilter;

  /// No description provided for @deleteFilterTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete filter?'**
  String get deleteFilterTitle;

  /// No description provided for @deleteFilterConfirm.
  ///
  /// In en, this message translates to:
  /// **'The filter \"{name}\" will be removed.'**
  String deleteFilterConfirm(String name);

  /// No description provided for @filterCopyName.
  ///
  /// In en, this message translates to:
  /// **'{name} (copy)'**
  String filterCopyName(String name);

  /// No description provided for @edit.
  ///
  /// In en, this message translates to:
  /// **'Edit'**
  String get edit;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @filterName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get filterName;

  /// No description provided for @filterColor.
  ///
  /// In en, this message translates to:
  /// **'Colour'**
  String get filterColor;

  /// No description provided for @filterMode.
  ///
  /// In en, this message translates to:
  /// **'Matching lines'**
  String get filterMode;

  /// No description provided for @filterModeInclude.
  ///
  /// In en, this message translates to:
  /// **'Show'**
  String get filterModeInclude;

  /// No description provided for @filterModeExclude.
  ///
  /// In en, this message translates to:
  /// **'Hide'**
  String get filterModeExclude;

  /// No description provided for @filterCriteria.
  ///
  /// In en, this message translates to:
  /// **'Criteria'**
  String get filterCriteria;

  /// No description provided for @combineAny.
  ///
  /// In en, this message translates to:
  /// **'Any'**
  String get combineAny;

  /// No description provided for @combineAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get combineAll;

  /// No description provided for @combineTooltip.
  ///
  /// In en, this message translates to:
  /// **'Show lines matching any or all of the enabled filters'**
  String get combineTooltip;

  /// No description provided for @enableAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Enable all'**
  String get enableAllFilters;

  /// No description provided for @disableAllFilters.
  ///
  /// In en, this message translates to:
  /// **'Disable all'**
  String get disableAllFilters;

  /// No description provided for @noFilterSelected.
  ///
  /// In en, this message translates to:
  /// **'Select a filter to edit it, or add a new one.'**
  String get noFilterSelected;

  /// No description provided for @noFilters.
  ///
  /// In en, this message translates to:
  /// **'No filters yet'**
  String get noFilters;

  /// No description provided for @noActiveFilters.
  ///
  /// In en, this message translates to:
  /// **'No filter enabled — enable a filter to see lines'**
  String get noActiveFilters;

  /// No description provided for @summaryMatchesAll.
  ///
  /// In en, this message translates to:
  /// **'Matches every line'**
  String get summaryMatchesAll;

  /// No description provided for @summaryLevel.
  ///
  /// In en, this message translates to:
  /// **'level ≥ {level}'**
  String summaryLevel(String level);

  /// No description provided for @summaryTag.
  ///
  /// In en, this message translates to:
  /// **'tag: {tag}'**
  String summaryTag(String tag);

  /// No description provided for @summaryProcess.
  ///
  /// In en, this message translates to:
  /// **'process: {process}'**
  String summaryProcess(String process);

  /// No description provided for @summaryExclude.
  ///
  /// In en, this message translates to:
  /// **'hides matches'**
  String get summaryExclude;

  /// No description provided for @invalidRegex.
  ///
  /// In en, this message translates to:
  /// **'Invalid regular expression: {error}'**
  String invalidRegex(String error);

  /// No description provided for @filterEnabled.
  ///
  /// In en, this message translates to:
  /// **'Enabled'**
  String get filterEnabled;

  /// No description provided for @navLogs.
  ///
  /// In en, this message translates to:
  /// **'Logs'**
  String get navLogs;

  /// No description provided for @navApps.
  ///
  /// In en, this message translates to:
  /// **'Apps'**
  String get navApps;

  /// No description provided for @navFiles.
  ///
  /// In en, this message translates to:
  /// **'Files'**
  String get navFiles;

  /// No description provided for @navShell.
  ///
  /// In en, this message translates to:
  /// **'Shell'**
  String get navShell;

  /// No description provided for @navShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Shortcuts'**
  String get navShortcuts;

  /// No description provided for @noDeviceSelected.
  ///
  /// In en, this message translates to:
  /// **'Select a connected device in the toolbar to use this view.'**
  String get noDeviceSelected;

  /// No description provided for @deviceMenu.
  ///
  /// In en, this message translates to:
  /// **'Device actions'**
  String get deviceMenu;

  /// No description provided for @reboot.
  ///
  /// In en, this message translates to:
  /// **'Reboot'**
  String get reboot;

  /// No description provided for @rebootRecovery.
  ///
  /// In en, this message translates to:
  /// **'Reboot to recovery'**
  String get rebootRecovery;

  /// No description provided for @rebootBootloader.
  ///
  /// In en, this message translates to:
  /// **'Reboot to bootloader'**
  String get rebootBootloader;

  /// No description provided for @rebootConfirmTitle.
  ///
  /// In en, this message translates to:
  /// **'Reboot device?'**
  String get rebootConfirmTitle;

  /// No description provided for @rebootConfirm.
  ///
  /// In en, this message translates to:
  /// **'{device} will restart ({mode}).'**
  String rebootConfirm(String device, String mode);

  /// No description provided for @rebootSent.
  ///
  /// In en, this message translates to:
  /// **'Reboot command sent to {device}'**
  String rebootSent(String device);

  /// No description provided for @takeScreenshot.
  ///
  /// In en, this message translates to:
  /// **'Take screenshot…'**
  String get takeScreenshot;

  /// No description provided for @screenshotSaved.
  ///
  /// In en, this message translates to:
  /// **'Screenshot saved to {path}'**
  String screenshotSaved(String path);

  /// No description provided for @installApk.
  ///
  /// In en, this message translates to:
  /// **'Install APK…'**
  String get installApk;

  /// No description provided for @installing.
  ///
  /// In en, this message translates to:
  /// **'Installing {name}…'**
  String installing(String name);

  /// No description provided for @installed.
  ///
  /// In en, this message translates to:
  /// **'{name} installed'**
  String installed(String name);

  /// No description provided for @fileTypeApk.
  ///
  /// In en, this message translates to:
  /// **'Android packages'**
  String get fileTypeApk;

  /// No description provided for @fileTypePng.
  ///
  /// In en, this message translates to:
  /// **'PNG images'**
  String get fileTypePng;

  /// No description provided for @refresh.
  ///
  /// In en, this message translates to:
  /// **'Refresh'**
  String get refresh;

  /// No description provided for @searchPackages.
  ///
  /// In en, this message translates to:
  /// **'Search packages'**
  String get searchPackages;

  /// No description provided for @showSystemApps.
  ///
  /// In en, this message translates to:
  /// **'System apps'**
  String get showSystemApps;

  /// No description provided for @systemBadge.
  ///
  /// In en, this message translates to:
  /// **'system'**
  String get systemBadge;

  /// No description provided for @packageCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 package} other{{count} packages}}'**
  String packageCount(int count);

  /// No description provided for @launchApp.
  ///
  /// In en, this message translates to:
  /// **'Launch'**
  String get launchApp;

  /// No description provided for @forceStop.
  ///
  /// In en, this message translates to:
  /// **'Force stop'**
  String get forceStop;

  /// No description provided for @clearData.
  ///
  /// In en, this message translates to:
  /// **'Clear data'**
  String get clearData;

  /// No description provided for @uninstall.
  ///
  /// In en, this message translates to:
  /// **'Uninstall'**
  String get uninstall;

  /// No description provided for @saveApk.
  ///
  /// In en, this message translates to:
  /// **'Save APK…'**
  String get saveApk;

  /// No description provided for @uninstallTitle.
  ///
  /// In en, this message translates to:
  /// **'Uninstall {name}?'**
  String uninstallTitle(String name);

  /// No description provided for @clearDataTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear data of {name}?'**
  String clearDataTitle(String name);

  /// No description provided for @cannotUndo.
  ///
  /// In en, this message translates to:
  /// **'This cannot be undone.'**
  String get cannotUndo;

  /// No description provided for @doneMessage.
  ///
  /// In en, this message translates to:
  /// **'{action}: {name}'**
  String doneMessage(String action, String name);

  /// No description provided for @goUp.
  ///
  /// In en, this message translates to:
  /// **'Parent folder'**
  String get goUp;

  /// No description provided for @path.
  ///
  /// In en, this message translates to:
  /// **'Path'**
  String get path;

  /// No description provided for @pushFiles.
  ///
  /// In en, this message translates to:
  /// **'Push files…'**
  String get pushFiles;

  /// No description provided for @pull.
  ///
  /// In en, this message translates to:
  /// **'Pull…'**
  String get pull;

  /// No description provided for @newFolder.
  ///
  /// In en, this message translates to:
  /// **'New folder'**
  String get newFolder;

  /// No description provided for @folderName.
  ///
  /// In en, this message translates to:
  /// **'Folder name'**
  String get folderName;

  /// No description provided for @create.
  ///
  /// In en, this message translates to:
  /// **'Create'**
  String get create;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @deleteFileTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete {name}?'**
  String deleteFileTitle(String name);

  /// No description provided for @emptyFolder.
  ///
  /// In en, this message translates to:
  /// **'This folder is empty'**
  String get emptyFolder;

  /// No description provided for @columnName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get columnName;

  /// No description provided for @columnSize.
  ///
  /// In en, this message translates to:
  /// **'Size'**
  String get columnSize;

  /// No description provided for @columnModified.
  ///
  /// In en, this message translates to:
  /// **'Modified'**
  String get columnModified;

  /// No description provided for @transferring.
  ///
  /// In en, this message translates to:
  /// **'Transferring {name}…'**
  String transferring(String name);

  /// No description provided for @pushDone.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 file sent to {path}} other{{count} files sent to {path}}}'**
  String pushDone(int count, String path);

  /// No description provided for @pullDone.
  ///
  /// In en, this message translates to:
  /// **'Saved to {path}'**
  String pullDone(String path);

  /// No description provided for @shellHint.
  ///
  /// In en, this message translates to:
  /// **'Command to run on the device (adb shell) — ↑/↓ for history'**
  String get shellHint;

  /// No description provided for @run.
  ///
  /// In en, this message translates to:
  /// **'Run'**
  String get run;

  /// No description provided for @clearConsole.
  ///
  /// In en, this message translates to:
  /// **'Clear finished'**
  String get clearConsole;

  /// No description provided for @exitCode.
  ///
  /// In en, this message translates to:
  /// **'exit {code}'**
  String exitCode(int code);

  /// No description provided for @stopped.
  ///
  /// In en, this message translates to:
  /// **'stopped'**
  String get stopped;

  /// No description provided for @running.
  ///
  /// In en, this message translates to:
  /// **'running…'**
  String get running;

  /// No description provided for @outputTruncated.
  ///
  /// In en, this message translates to:
  /// **'(output truncated)'**
  String get outputTruncated;

  /// No description provided for @consoleEmpty.
  ///
  /// In en, this message translates to:
  /// **'Run a command or a shortcut to see its output here.'**
  String get consoleEmpty;

  /// No description provided for @copyOutput.
  ///
  /// In en, this message translates to:
  /// **'Copy output'**
  String get copyOutput;

  /// No description provided for @copied.
  ///
  /// In en, this message translates to:
  /// **'Copied'**
  String get copied;

  /// No description provided for @addShortcut.
  ///
  /// In en, this message translates to:
  /// **'Add shortcut'**
  String get addShortcut;

  /// No description provided for @editShortcut.
  ///
  /// In en, this message translates to:
  /// **'Edit shortcut'**
  String get editShortcut;

  /// No description provided for @newShortcutName.
  ///
  /// In en, this message translates to:
  /// **'New shortcut'**
  String get newShortcutName;

  /// No description provided for @deleteShortcutTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete shortcut?'**
  String get deleteShortcutTitle;

  /// No description provided for @deleteShortcutConfirm.
  ///
  /// In en, this message translates to:
  /// **'The shortcut \"{name}\" will be removed.'**
  String deleteShortcutConfirm(String name);

  /// No description provided for @manageShortcuts.
  ///
  /// In en, this message translates to:
  /// **'Manage shortcuts…'**
  String get manageShortcuts;

  /// No description provided for @noShortcuts.
  ///
  /// In en, this message translates to:
  /// **'No shortcuts yet'**
  String get noShortcuts;

  /// No description provided for @shortcutName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get shortcutName;

  /// No description provided for @shortcutCommand.
  ///
  /// In en, this message translates to:
  /// **'Command'**
  String get shortcutCommand;

  /// No description provided for @shortcutKind.
  ///
  /// In en, this message translates to:
  /// **'Runs'**
  String get shortcutKind;

  /// No description provided for @kindShell.
  ///
  /// In en, this message translates to:
  /// **'adb shell'**
  String get kindShell;

  /// No description provided for @kindAdb.
  ///
  /// In en, this message translates to:
  /// **'adb'**
  String get kindAdb;

  /// No description provided for @kindHost.
  ///
  /// In en, this message translates to:
  /// **'This computer'**
  String get kindHost;

  /// No description provided for @kindShellHint.
  ///
  /// In en, this message translates to:
  /// **'Runs in the device shell, e.g. input keyevent KEYCODE_HOME'**
  String get kindShellHint;

  /// No description provided for @kindAdbHint.
  ///
  /// In en, this message translates to:
  /// **'adb arguments for the selected device, e.g. install -r /path/app.apk'**
  String get kindAdbHint;

  /// No description provided for @kindHostHint.
  ///
  /// In en, this message translates to:
  /// **'Command or script on this computer; ANDROID_SERIAL and ADB are set'**
  String get kindHostHint;

  /// No description provided for @shortcutOutput.
  ///
  /// In en, this message translates to:
  /// **'When finished'**
  String get shortcutOutput;

  /// No description provided for @outputNotify.
  ///
  /// In en, this message translates to:
  /// **'Notify'**
  String get outputNotify;

  /// No description provided for @outputConsole.
  ///
  /// In en, this message translates to:
  /// **'Open Shell view'**
  String get outputConsole;

  /// No description provided for @shortcutConfirm.
  ///
  /// In en, this message translates to:
  /// **'Ask before running'**
  String get shortcutConfirm;

  /// No description provided for @shortcutPinned.
  ///
  /// In en, this message translates to:
  /// **'Show in toolbar'**
  String get shortcutPinned;

  /// No description provided for @shortcutIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get shortcutIcon;

  /// No description provided for @runShortcutTitle.
  ///
  /// In en, this message translates to:
  /// **'Run \"{name}\"?'**
  String runShortcutTitle(String name);

  /// No description provided for @shortcutDone.
  ///
  /// In en, this message translates to:
  /// **'{name}: done'**
  String shortcutDone(String name);

  /// No description provided for @shortcutFailed.
  ///
  /// In en, this message translates to:
  /// **'{name} failed (exit {code})'**
  String shortcutFailed(String name, int code);

  /// No description provided for @shortcutNeedsDevice.
  ///
  /// In en, this message translates to:
  /// **'Select a connected device to run \"{name}\"'**
  String shortcutNeedsDevice(String name);

  /// No description provided for @commandRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a command'**
  String get commandRequired;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'pt'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {


  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en': return AppLocalizationsEn();
    case 'pt': return AppLocalizationsPt();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.'
  );
}
