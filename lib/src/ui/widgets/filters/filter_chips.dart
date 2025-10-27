import 'package:flutter/material.dart';

import '../../../core/unified_log_entry.dart';
import '../../../core/unified_log_types.dart';

/// Widget for building main filter chips (Logger Logs, API Logs, BLoC Logs)
class MainFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;
  final bool isExpanded;
  final VoidCallback onDropdownTap;
  final bool hasSubFiltersSelected;

  const MainFilterChip({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.count,
    required this.onTap,
    required this.isExpanded,
    required this.onDropdownTap,
    required this.hasSubFiltersSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? Color.fromARGB(26, (color.r * 255).round(),
                (color.g * 255).round(), (color.b * 255).round())
            : Colors.grey[100], // 10% opacity
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? color : Colors.grey[300]!,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Main chip content (clickable for selection)
          InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(20),
              bottomLeft: Radius.circular(20),
            ),
            child: Container(
              padding:
                  const EdgeInsets.only(left: 12, top: 8, bottom: 8, right: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 16,
                    color: isSelected ? color : Colors.grey[600],
                  ),
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isSelected ? color : Colors.grey[700],
                    ),
                  ),
                  if (count > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected ? color : Colors.grey[500],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          // Dropdown arrow (clickable for expanding sub-filters)
          InkWell(
            onTap: onDropdownTap,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(20),
              bottomRight: Radius.circular(20),
            ),
            child: Container(
              padding:
                  const EdgeInsets.only(left: 4, right: 8, top: 8, bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(20),
                  bottomRight: Radius.circular(20),
                ),
                border: Border.all(
                  color: hasSubFiltersSelected ? color : Colors.grey[300]!,
                  width: hasSubFiltersSelected ? 1.5 : 1,
                ),
              ),
              child: Icon(
                isExpanded
                    ? Icons.keyboard_arrow_up
                    : Icons.keyboard_arrow_down,
                size: 16,
                color: hasSubFiltersSelected ? color : Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for building sub-filter chips (logger.d, GET, Success, etc.)
class SubFilterChip extends StatelessWidget {
  final String label;
  final Color color;
  final bool isSelected;
  final int count;
  final VoidCallback onTap;

  const SubFilterChip({
    super.key,
    required this.label,
    required this.color,
    required this.isSelected,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Color.fromARGB(26, (color.r * 255).round(),
                  (color.g * 255).round(), (color.b * 255).round())
              : Colors.grey[50], // 10% opacity
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (count > 0) ...[
              Text(
                '($count)',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? color : Colors.grey[600],
                ),
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Utility class for getting labels for different log types
class FilterLabels {
  /// Get logger level label for unified log type
  static String getLoggerLevelLabel(UnifiedLogType type) {
    switch (type) {
      case UnifiedLogType.debug:
        return 'logger.d';
      case UnifiedLogType.info:
        return 'logger.i';
      case UnifiedLogType.warning:
        return 'logger.w';
      case UnifiedLogType.error:
        return 'logger.e';
      default:
        return 'logger';
    }
  }

  /// Get API status label for unified log type
  static String getApiStatusLabel(UnifiedLogType type) {
    switch (type) {
      case UnifiedLogType.apiSuccess:
        return 'Success (2xx)';
      case UnifiedLogType.apiRedirect:
        return 'Redirect (3xx)';
      case UnifiedLogType.apiClientError:
        return 'Client Error (4xx)';
      case UnifiedLogType.apiServerError:
        return 'Server Error (5xx)';
      case UnifiedLogType.apiNetworkError:
        return 'Network Error';
      case UnifiedLogType.apiPending:
        return 'Pending';
      default:
        return 'API';
    }
  }

  /// Get BLoC status label for unified log type
  static String getBlocStatusLabel(UnifiedLogType type) {
    switch (type) {
      case UnifiedLogType.blocEvent:
        return 'BLoC\nEvent';
      case UnifiedLogType.blocTransition:
        return 'BLoC\nTransition';
      case UnifiedLogType.blocChange:
        return 'BLoC\nChange';
      case UnifiedLogType.blocCreate:
        return 'BLoC\nCreate';
      case UnifiedLogType.blocClose:
        return 'BLoC\nClose';
      case UnifiedLogType.blocError:
        return 'BLoC\nError';
      default:
        return 'BLoC';
    }
  }

  /// Get appropriate label for log type display
  static String getLogTypeLabel(UnifiedLogEntry log) {
    if (log.source == LogSource.api) {
      // For API logs, show the HTTP method
      return log.httpMethod ?? 'API';
    } else if (log.source == LogSource.bloc) {
      // For BLoC logs, show the BLoC type
      return getBlocStatusLabel(log.type);
    } else {
      // For general logs, show logger.level format
      switch (log.type) {
        case UnifiedLogType.debug:
          return 'logger.d';
        case UnifiedLogType.info:
          return 'logger.i';
        case UnifiedLogType.warning:
          return 'logger.w';
        case UnifiedLogType.error:
          return 'logger.e';
        default:
          return 'logger';
      }
    }
  }
}
