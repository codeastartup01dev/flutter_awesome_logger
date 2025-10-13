import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Global manager for floating logger visibility and position
class FloatingLoggerManager {
  static const String _visibilityKey = 'awesome_floating_logger_visible';
  static const String _positionXKey = 'awesome_floating_logger_position_x';
  static const String _positionYKey = 'awesome_floating_logger_position_y';

  static final ValueNotifier<bool> _visibilityNotifier = ValueNotifier<bool>(
    true,
  );

  /// Get the visibility notifier for listening to changes
  static ValueNotifier<bool> get visibilityNotifier => _visibilityNotifier;

  /// Check if floating logger is currently visible
  static Future<bool> isVisible() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_visibilityKey) ?? true;
  }

  /// Set floating logger visibility
  static Future<void> setVisible(bool visible) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_visibilityKey, visible);
    _visibilityNotifier.value = visible;
  }

  /// Toggle floating logger visibility
  static Future<void> toggle() async {
    final current = await isVisible();
    await setVisible(!current);
  }

  /// Get saved position of floating logger
  static Future<Offset?> getSavedPosition() async {
    final prefs = await SharedPreferences.getInstance();
    final x = prefs.getDouble(_positionXKey);
    final y = prefs.getDouble(_positionYKey);

    if (x != null && y != null) {
      return Offset(x, y);
    }
    return null;
  }

  /// Save position of floating logger
  static Future<void> savePosition(Offset position) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_positionXKey, position.dx);
    await prefs.setDouble(_positionYKey, position.dy);
  }

  /// Clear all saved preferences
  static Future<void> clearPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_visibilityKey);
    await prefs.remove(_positionXKey);
    await prefs.remove(_positionYKey);
  }

  /// Initialize visibility from saved preferences
  static Future<void> initialize() async {
    final visible = await isVisible();
    _visibilityNotifier.value = visible;
  }
}
