import 'package:flutter/material.dart';
import '../../../core/unified_log_types.dart';

/// Reusable filter chips widget for logger pages
class LoggerFilterChips extends StatelessWidget {
  /// Available filter options
  final List<FilterOption> options;

  /// Currently selected filters
  final Set<String> selectedFilters;

  /// Callback when a filter is selected/deselected
  final Function(String, bool) onFilterChanged;

  /// Title for the filter section
  final String title;

  /// Whether to show the clear all button
  final bool showClearAll;

  /// Callback when clear all is pressed
  final VoidCallback? onClearAll;

  const LoggerFilterChips({
    super.key,
    required this.options,
    required this.selectedFilters,
    required this.onFilterChanged,
    required this.title,
    this.showClearAll = true,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
            if (showClearAll && selectedFilters.isNotEmpty) ...[
              const SizedBox(width: 8),
              TextButton.icon(
                onPressed: onClearAll,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Clear All', style: TextStyle(fontSize: 12)),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options
                .map(
                  (option) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      selected: selectedFilters.contains(option.value),
                      label: Text(
                        option.label,
                        style: const TextStyle(fontSize: 11),
                      ),
                      backgroundColor: selectedFilters.contains(option.value)
                          ? option.color?.withValues(alpha: 0.2)
                          : null,
                      selectedColor: option.color?.withValues(alpha: 0.3),
                      onSelected: (selected) =>
                          onFilterChanged(option.value, selected),
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }
}

/// Represents a filter option with label, value, and optional color
class FilterOption {
  /// Display label for the filter
  final String label;

  /// Value used for filtering
  final String value;

  /// Optional color for the filter chip
  final Color? color;

  /// Optional count to display in the label
  final int? count;

  const FilterOption({
    required this.label,
    required this.value,
    this.color,
    this.count,
  });

  /// Get display label with count if available
  String get displayLabel {
    if (count != null) {
      return '($count) $label';
    }
    return label;
  }
}

/// Multi-select filter chips for unified log types
class UnifiedLogTypeFilterChips extends StatelessWidget {
  /// Available log types to filter by
  final List<UnifiedLogType> availableTypes;

  /// Currently selected log types
  final Set<UnifiedLogType> selectedTypes;

  /// Callback when a type is selected/deselected
  final Function(UnifiedLogType, bool) onTypeChanged;

  /// Optional counts for each type
  final Map<UnifiedLogType, int>? typeCounts;

  /// Whether to show the clear all button
  final bool showClearAll;

  /// Callback when clear all is pressed
  final VoidCallback? onClearAll;

  const UnifiedLogTypeFilterChips({
    super.key,
    required this.availableTypes,
    required this.selectedTypes,
    required this.onTypeChanged,
    this.typeCounts,
    this.showClearAll = true,
    this.onClearAll,
  });

  @override
  Widget build(BuildContext context) {
    final options = availableTypes.map((type) {
      final count = typeCounts?[type];
      final label =
          count != null ? '($count) ${type.displayName}' : type.displayName;
      return FilterOption(
        label: label,
        value: type.name,
        color: type.color,
      );
    }).toList();

    return LoggerFilterChips(
      title: 'Log Types:',
      options: options,
      selectedFilters: selectedTypes.map((t) => t.name).toSet(),
      onFilterChanged: (value, selected) {
        final type = UnifiedLogType.values.firstWhere((t) => t.name == value);
        onTypeChanged(type, selected);
      },
      showClearAll: showClearAll,
      onClearAll: onClearAll,
    );
  }
}
