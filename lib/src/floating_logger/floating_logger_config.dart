import 'package:flutter/material.dart';

/// Configuration for floating logger behavior and appearance
class FloatingLoggerConfig {
  /// Background color of the floating button
  final Color backgroundColor;

  /// Icon displayed on the floating button
  final IconData icon;

  /// Whether to show log count badges on the button
  final bool showCount;

  /// Whether to enable drag gestures for repositioning
  final bool enableGestures;

  /// Size of the floating button
  final double size;

  /// Whether to show file paths in UI
  final bool showFilePaths;

  /// Initial position of the floating button
  final Offset? initialPosition;

  /// Whether to auto-snap to screen edges after dragging
  final bool autoSnapToEdges;

  /// Margin from screen edges when snapping
  final double edgeMargin;

  /// Whether to enable shake-to-toggle functionality
  final bool enableShakeToToggle;

  /// Shake sensitivity threshold (1-15, higher = less sensitive)
  final int shakeSensitivity;

  const FloatingLoggerConfig({
    this.backgroundColor = Colors.deepPurple,
    this.icon = Icons.developer_mode,
    this.showCount = true,
    this.enableGestures = true,
    this.size = 60.0,
    this.showFilePaths = true,
    this.initialPosition,
    this.autoSnapToEdges = true,
    this.edgeMargin = 20.0,
    this.enableShakeToToggle = true,
    this.shakeSensitivity = 8,
  });

  /// Create a copy with updated fields
  FloatingLoggerConfig copyWith({
    Color? backgroundColor,
    IconData? icon,
    bool? showCount,
    bool? enableGestures,
    double? size,
    bool? showFilePaths,
    Offset? initialPosition,
    bool? autoSnapToEdges,
    double? edgeMargin,
    bool? enableShakeToToggle,
    int? shakeSensitivity,
  }) {
    return FloatingLoggerConfig(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      icon: icon ?? this.icon,
      showCount: showCount ?? this.showCount,
      enableGestures: enableGestures ?? this.enableGestures,
      size: size ?? this.size,
      showFilePaths: showFilePaths ?? this.showFilePaths,
      initialPosition: initialPosition ?? this.initialPosition,
      autoSnapToEdges: autoSnapToEdges ?? this.autoSnapToEdges,
      edgeMargin: edgeMargin ?? this.edgeMargin,
      enableShakeToToggle: enableShakeToToggle ?? this.enableShakeToToggle,
      shakeSensitivity: shakeSensitivity ?? this.shakeSensitivity,
    );
  }
}

/// Style configuration for floating logger button
class FloatingLoggerStyle {
  /// Background color of the button
  final Color? backgroundColor;

  /// Icon data for the button
  final IconData? iconData;

  /// Tooltip text
  final String? tooltip;

  /// Size of the button
  final Size? size;

  /// Custom icon widget (overrides iconData)
  final Widget? customIcon;

  /// Text color for badges
  final Color? badgeTextColor;

  /// Border color for the button
  final Color? borderColor;

  /// Shadow configuration
  final List<BoxShadow>? shadows;

  const FloatingLoggerStyle({
    this.backgroundColor,
    this.iconData,
    this.tooltip,
    this.size,
    this.customIcon,
    this.badgeTextColor,
    this.borderColor,
    this.shadows,
  });

  /// Create a copy with updated fields
  FloatingLoggerStyle copyWith({
    Color? backgroundColor,
    IconData? iconData,
    String? tooltip,
    Size? size,
    Widget? customIcon,
    Color? badgeTextColor,
    Color? borderColor,
    List<BoxShadow>? shadows,
  }) {
    return FloatingLoggerStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      iconData: iconData ?? this.iconData,
      tooltip: tooltip ?? this.tooltip,
      size: size ?? this.size,
      customIcon: customIcon ?? this.customIcon,
      badgeTextColor: badgeTextColor ?? this.badgeTextColor,
      borderColor: borderColor ?? this.borderColor,
      shadows: shadows ?? this.shadows,
    );
  }
}
