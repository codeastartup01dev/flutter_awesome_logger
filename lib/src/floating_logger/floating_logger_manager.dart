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
  static bool isVisible() {
    return _visibilityNotifier.value;
  }

  /// Set floating logger visibility
  static void setVisible(bool visible) {
    _visibilityNotifier.value = visible;
  }

  /// Toggle floating logger visibility
  static void toggle() {
    final current = isVisible();
    setVisible(!current);
  }

  /// Get saved position of floating logger
  static Offset? getSavedPosition() {
    return _savedPosition;
  }

  /// Save position of floating logger
  static void savePosition(Offset position) {
    _savedPosition = position;
  }

  /// Clear all saved preferences
  static void clearPreferences() {
    _savedPosition = null;
    _visibilityNotifier.value = true;
  }

  /// Initialize visibility from saved preferences
  static void initialize() {
    // Initialize with default values since we don't persist data
    _visibilityNotifier.value = true;
    _savedPosition = null;
  }
}
