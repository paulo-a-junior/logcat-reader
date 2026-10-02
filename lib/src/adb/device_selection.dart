import 'package:flutter/foundation.dart';

import 'adb_client.dart';

/// The adb device list and the device the user is working with, shared by
/// the log viewer and the device tools.
class DeviceSelection extends ChangeNotifier {
  DeviceSelection(this.adb);

  final AdbClient adb;

  List<AdbDevice> _devices = const [];
  String? _selectedSerial;
  bool _loading = false;
  AdbException? _error;

  List<AdbDevice> get devices => _devices;
  bool get loading => _loading;
  AdbException? get error => _error;

  AdbDevice? get selected =>
      _devices.where((d) => d.serial == _selectedSerial).firstOrNull;

  /// Serial of the selected device if it is online, otherwise null.
  String? get onlineSerial {
    final d = selected;
    return d != null && d.isOnline ? d.serial : null;
  }

  set selectedSerial(String? serial) {
    if (serial == _selectedSerial) return;
    _selectedSerial = serial;
    notifyListeners();
  }

  Future<void> refresh() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final devices = await adb.devices();
      _devices = devices;
      if (!devices.any((d) => d.serial == _selectedSerial)) {
        _selectedSerial =
            devices.where((d) => d.isOnline).map((d) => d.serial).firstOrNull;
      }
    } on AdbException catch (e) {
      _error = e;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
