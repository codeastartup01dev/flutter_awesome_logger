import 'package:flutter/material.dart';

/// Reusable statistics widget for logger pages
class LoggerStatistics extends StatelessWidget {
  /// List of statistics to display
  final List<StatisticItem> statistics;

  /// Optional callback when a statistic is tapped
  final Function(String)? onStatisticTapped;

  /// Currently selected statistic filter
  final String? selectedFilter;

  const LoggerStatistics({
    super.key,
    required this.statistics,
    this.onStatisticTapped,
    this.selectedFilter,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children:
            statistics.map((stat) => _buildStatItem(stat, context)).toList(),
      ),
    );
  }

  Widget _buildStatItem(StatisticItem stat, BuildContext context) {
    final isSelected = selectedFilter == stat.filterKey;

    return InkWell(
      onTap: onStatisticTapped != null
          ? () => onStatisticTapped!(stat.filterKey)
          : null,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? stat.color.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? stat.color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              stat.value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: stat.color,
              ),
            ),
            Text(
              stat.label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

/// Represents a single statistic item
class StatisticItem {
  /// Display label for the statistic
  final String label;

  /// Value to display (usually a number)
  final String value;

  /// Color for the statistic
  final Color color;

  /// Key used for filtering when this statistic is tapped
  final String filterKey;

  /// Optional icon for the statistic
  final IconData? icon;

  const StatisticItem({
    required this.label,
    required this.value,
    required this.color,
    required this.filterKey,
    this.icon,
  });
}
