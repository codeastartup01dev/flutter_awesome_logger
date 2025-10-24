import 'dart:collection';

import 'bloc_log_entry.dart';

/// Service for managing BLoC logs
class BlocLoggerService {
  static final Queue<BlocLogEntry> _blocLogs = Queue<BlocLogEntry>();
  static const int _maxLogEntries = 1000;
  static bool _storageEnabled = true;

  /// Add a BLoC log entry
  static void addBlocLog(BlocLogEntry logEntry) {
    if (!_storageEnabled) return;

    _blocLogs.add(logEntry);

    // Remove old entries if we exceed the limit
    while (_blocLogs.length > _maxLogEntries) {
      _blocLogs.removeFirst();
    }
  }

  /// Get all BLoC logs
  static List<BlocLogEntry> getBlocLogs() {
    return _blocLogs.toList();
  }

  /// Clear all BLoC logs
  static void clearBlocLogs() {
    _blocLogs.clear();
  }

  /// Enable or disable BLoC log storage
  static void setStorageEnabled(bool enabled) {
    _storageEnabled = enabled;
  }

  /// Check if storage is enabled
  static bool get isStorageEnabled => _storageEnabled;

  /// Get the number of BLoC logs
  static int get logCount => _blocLogs.length;

  /// Get BLoC logs filtered by type
  static List<BlocLogEntry> getBlocLogsByType(BlocLogType type) {
    return _blocLogs.where((log) => log.type == type).toList();
  }

  /// Get BLoC logs filtered by BLoC name
  static List<BlocLogEntry> getBlocLogsByName(String blocName) {
    return _blocLogs.where((log) => log.blocName == blocName).toList();
  }

  /// Get unique BLoC names from all logs
  static List<String> getUniqueBlocNames() {
    final names = <String>{};
    for (final log in _blocLogs) {
      names.add(log.blocName);
    }
    return names.toList()..sort();
  }

  /// Get unique event types from all logs
  static List<String> getUniqueEventTypes() {
    final types = <String>{};
    for (final log in _blocLogs) {
      if (log.event != null) {
        types.add(log.event.runtimeType.toString());
      }
    }
    return types.toList()..sort();
  }

  /// Get unique state types from all logs
  static List<String> getUniqueStateTypes() {
    final types = <String>{};
    for (final log in _blocLogs) {
      if (log.currentState != null) {
        types.add(log.currentState.runtimeType.toString());
      }
      if (log.nextState != null) {
        types.add(log.nextState.runtimeType.toString());
      }
    }
    return types.toList()..sort();
  }
}
