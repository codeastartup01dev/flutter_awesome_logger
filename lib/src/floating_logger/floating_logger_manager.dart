import 'package:flutter/material.dart';

/// Global manager for floating logger visibility and position
class FloatingLoggerManager {
  static final ValueNotifier<bool> _visibilityNotifier = ValueNotifier<bool>(
    true,
  );

  // In-memory storage for position
  static Offset? _savedPosition;

  /// Get the visibility notifier for listening to changes
  static ValueNotifier<bool> get visibilityNotifier => _visibilityNotifier;

  /// Check if floating logger is currently visible
  static Future<bool> isVisible() async {
    return _visibilityNotifier.value;
  }

  /// Set floating logger visibility
  static Future<void> setVisible(bool visible) async {
    _visibilityNotifier.value = visible;
  }

  /// Toggle floating logger visibility
  static Future<void> toggle() async {
    final current = await isVisible();
    await setVisible(!current);
  }

  /// Get saved position of floating logger
  static Future<Offset?> getSavedPosition() async {
    return _savedPosition;
  }

  /// Save position of floating logger
  static Future<void> savePosition(Offset position) async {
    _savedPosition = position;
  }

  /// Clear all saved preferences
  static Future<void> clearPreferences() async {
    _savedPosition = null;
    _visibilityNotifier.value = true;
  }

  /// Initialize visibility from saved preferences
  static Future<void> initialize() async {
    // Initialize with default values since we don't persist data
    _visibilityNotifier.value = true;
    _savedPosition = null;
  }
}
