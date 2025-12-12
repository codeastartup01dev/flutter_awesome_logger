import 'package:flutter/material.dart';

import '../../core/unified_log_types.dart';
import '../managers/filter_manager.dart';

/// Utility class for generating display text based on filter states
class FilterDisplayUtils {
  /// Generate dynamic hint text based on selected filters
  static String getSearchHintText(FilterManager filterManager) {
    final selectedSources = filterManager.selectedSources;
    final selectedTypes = filterManager.selectedTypes;
    final selectedClasses = filterManager.selectedClasses;
    final selectedSourceNames = filterManager.selectedSourceNames;
    final selectedFilePaths = filterManager.selectedFilePaths;
    final selectedMethods = filterManager.selectedMethods;
    final statsFilter = filterManager.statsFilter;

    // If no filters are active, show default
    if (selectedSources.isEmpty &&
        selectedTypes.isEmpty &&
        selectedClasses.isEmpty &&
        selectedSourceNames.isEmpty &&
        selectedFilePaths.isEmpty &&
        selectedMethods.isEmpty &&
        (statsFilter == null || statsFilter == 'total')) {
      return 'Search all logs...';
    }

    // Build hint text based on filters
    final parts = <String>[];

    // Stats filter takes precedence
    if (statsFilter != null && statsFilter != 'total') {
      switch (statsFilter) {
        case 'success':
          parts.add('successful');
          break;
        case 'warnings':
          parts.add('warning');
          break;
        case 'errors':
          parts.add('error');
          break;
        case 'general':
          parts.add('general');
          break;
        case 'api':
          parts.add('API');
          break;
      }
      return 'Search ${parts.join(' ')} logs...';
    }

    // Source-based filtering
    if (selectedSources.length == 1) {
      final source = selectedSources.first;
      parts.add(source.displayName.toLowerCase());
    } else if (selectedSources.length > 1) {
      parts.add('selected');
    }

    // Type-based filtering
    if (selectedTypes.length == 1) {
      final type = selectedTypes.first;
      if (parts.isEmpty) {
        parts.add(type.displayName.toLowerCase());
      } else {
        parts.add(type.displayName.toLowerCase());
      }
    } else if (selectedTypes.length > 1) {
      if (parts.isEmpty) {
        parts.add('filtered');
      } else {
        parts.add('filtered');
      }
    }

    // Specific filters (classes, sources, file paths, methods)
    final hasSpecificFilters = selectedClasses.isNotEmpty ||
        selectedSourceNames.isNotEmpty ||
        selectedFilePaths.isNotEmpty ||
        selectedMethods.isNotEmpty;

    if (hasSpecificFilters) {
      if (parts.isEmpty) {
        return 'Search in selected sources...';
      } else {
        return 'Search ${parts.join(' ')} logs in selected sources...';
      }
    }

    // Default case with sources/types
    if (parts.isEmpty) {
      return 'Search filtered logs...';
    } else {
      return 'Search ${parts.join(' ')} logs...';
    }
  }

  /// Generate empty state message based on search and filters
  static String getEmptyStateMessage(
    FilterManager filterManager,
    TextEditingController searchController,
  ) {
    if (filterManager.searchQuery.isEmpty) {
      return 'No logs available\n';
    }

    // Check if there are any active filters
    final hasActiveFilters = filterManager.hasActiveFilters();

    if (!hasActiveFilters) {
      return 'No logs matching "${searchController.text}"';
    }

    // Build filter description
    final filterDescription = getFilterDescription(filterManager);
    return 'No logs matching "${searchController.text}" for $filterDescription';
  }

  /// Generate a description of active filters for empty state messages
  static String getFilterDescription(FilterManager filterManager) {
    final selectedSources = filterManager.selectedSources;
    final selectedTypes = filterManager.selectedTypes;
    final selectedClasses = filterManager.selectedClasses;
    final selectedSourceNames = filterManager.selectedSourceNames;
    final selectedFilePaths = filterManager.selectedFilePaths;
    final selectedMethods = filterManager.selectedMethods;
    final statsFilter = filterManager.statsFilter;

    final descriptions = <String>[];

    // Stats filter takes precedence
    if (statsFilter != null && statsFilter != 'total') {
      switch (statsFilter) {
        case 'success':
          descriptions.add('successful logs');
          break;
        case 'warnings':
          descriptions.add('warning logs');
          break;
        case 'errors':
          descriptions.add('error logs');
          break;
        case 'general':
          descriptions.add('general logs');
          break;
        case 'api':
          descriptions.add('API logs');
          break;
      }
      return descriptions.first;
    }

    // Add source descriptions
    if (selectedSources.length == 1) {
      descriptions
          .add('${selectedSources.first.displayName.toLowerCase()} logs');
    } else if (selectedSources.length > 1) {
      final sourceNames =
          selectedSources.map((s) => s.displayName.toLowerCase()).join(', ');
      descriptions.add('$sourceNames logs');
    }

    // Add type descriptions
    if (selectedTypes.length == 1) {
      descriptions.add(selectedTypes.first.displayName.toLowerCase());
    } else if (selectedTypes.length > 1) {
      final typeNames =
          selectedTypes.map((t) => t.displayName.toLowerCase()).join(', ');
      descriptions.add('$typeNames types');
    }

    // Add specific filter descriptions
    final specificFilters = <String>[];
    if (selectedClasses.isNotEmpty) {
      specificFilters.add(
          '${selectedClasses.length} class${selectedClasses.length > 1 ? 'es' : ''}');
    }
    if (selectedSourceNames.isNotEmpty) {
      specificFilters.add(
          '${selectedSourceNames.length} source${selectedSourceNames.length > 1 ? 's' : ''}');
    }
    if (selectedFilePaths.isNotEmpty) {
      specificFilters.add(
          '${selectedFilePaths.length} file path${selectedFilePaths.length > 1 ? 's' : ''}');
    }
    if (selectedMethods.isNotEmpty) {
      specificFilters.add(
          '${selectedMethods.length} method${selectedMethods.length > 1 ? 's' : ''}');
    }

    if (specificFilters.isNotEmpty) {
      descriptions.add('selected ${specificFilters.join(', ')}');
    }

    // Fallback for generic filters
    if (descriptions.isEmpty) {
      return 'current filters';
    }

    return descriptions.join(' with ');
  }
}
