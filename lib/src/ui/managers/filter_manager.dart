import 'package:flutter/foundation.dart';

import '../../core/unified_log_entry.dart';
import '../../core/unified_log_types.dart';

/// Manages all filter state and logic for the logger history page
class FilterManager extends ChangeNotifier {
  // Filter sets
  final Set<UnifiedLogType> _selectedTypes = {};
  final Set<LogSource> _selectedSources = {};
  final Set<String> _selectedClasses = {}; // For general logs
  final Set<String> _selectedMethods = {}; // For API logs

  /// Constructor that optionally accepts a default main filter
  FilterManager({LogSource? defaultMainFilter}) {
    if (defaultMainFilter != null) {
      _selectedSources.add(defaultMainFilter);
    } else {
      _selectedSources.add(LogSource.api);
    }
  }

  // Main filter section
  bool _isFilterSectionExpanded = true;

  // Expanded filter sections
  bool _isLoggerFiltersExpanded = false;
  bool _isApiFiltersExpanded = false;

  // Statistics filter
  String? _statsFilter;

  // Search query
  String _searchQuery = '';

  // Sorting
  bool _sortNewestFirst = false;

  // Getters
  Set<UnifiedLogType> get selectedTypes => Set.unmodifiable(_selectedTypes);
  Set<LogSource> get selectedSources => Set.unmodifiable(_selectedSources);
  Set<String> get selectedClasses => Set.unmodifiable(_selectedClasses);
  Set<String> get selectedMethods => Set.unmodifiable(_selectedMethods);

  bool get isFilterSectionExpanded => _isFilterSectionExpanded;
  bool get isLoggerFiltersExpanded => _isLoggerFiltersExpanded;
  bool get isApiFiltersExpanded => _isApiFiltersExpanded;

  String? get statsFilter => _statsFilter;
  String get searchQuery => _searchQuery;
  bool get sortNewestFirst => _sortNewestFirst;

  /// Toggle filter section expansion
  void toggleFilterSectionExpanded() {
    _isFilterSectionExpanded = !_isFilterSectionExpanded;
    notifyListeners();
  }

  /// Toggle logger filters expansion
  void toggleLoggerFiltersExpanded() {
    _isLoggerFiltersExpanded = !_isLoggerFiltersExpanded;
    notifyListeners();
  }

  /// Toggle API filters expansion
  void toggleApiFiltersExpanded() {
    _isApiFiltersExpanded = !_isApiFiltersExpanded;
    notifyListeners();
  }

  /// Update search query
  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  /// Toggle sorting order
  void toggleSortOrder() {
    _sortNewestFirst = !_sortNewestFirst;
    notifyListeners();
  }

  /// Toggle log source selection
  void toggleLogSource(LogSource source) {
    if (_selectedSources.contains(source)) {
      _selectedSources.remove(source);
      // Clear related sub-filters when deselecting source
      switch (source) {
        case LogSource.general:
          _isLoggerFiltersExpanded = false;
          _selectedTypes.removeWhere((type) => type.isGeneralLog);
          _selectedClasses.clear();
          break;
        case LogSource.api:
          _isApiFiltersExpanded = false;
          _selectedTypes.removeWhere((type) => type.isApiLog);
          _selectedMethods.clear();
          break;
        default:
          // Handle other sources like flutter
          break;
      }
    } else {
      _selectedSources.add(source);
    }
    notifyListeners();
  }

  /// Toggle log type selection
  void toggleLogType(UnifiedLogType type) {
    if (_selectedTypes.contains(type)) {
      _selectedTypes.remove(type);
    } else {
      _selectedTypes.add(type);
    }
    notifyListeners();
  }

  /// Toggle class selection (for general logs)
  void toggleClass(String className) {
    if (_selectedClasses.contains(className)) {
      _selectedClasses.remove(className);
    } else {
      _selectedClasses.add(className);
    }
    notifyListeners();
  }

  /// Toggle method selection (for API logs)
  void toggleMethod(String method) {
    if (_selectedMethods.contains(method)) {
      _selectedMethods.remove(method);
    } else {
      _selectedMethods.add(method);
    }
    notifyListeners();
  }

  /// Set statistics filter
  void setStatsFilter(String? filterKey) {
    if (_statsFilter == filterKey) {
      _statsFilter = null; // Toggle off if already selected
    } else {
      _statsFilter = filterKey == 'total' ? null : filterKey;
    }
    notifyListeners();
  }

  /// Check if there are any active filters
  bool hasActiveFilters() {
    return _selectedTypes.isNotEmpty ||
        _selectedSources.isNotEmpty ||
        _selectedClasses.isNotEmpty ||
        _selectedMethods.isNotEmpty ||
        _statsFilter != null;
  }

  /// Get count of active filters
  int getActiveFilterCount() {
    int count = 0;
    count += _selectedTypes.length;
    count += _selectedSources.length;
    count += _selectedClasses.length;
    count += _selectedMethods.length;
    if (_statsFilter != null) count += 1;
    return count;
  }

  /// Check if any logger sub-filters are selected
  bool hasLoggerSubFiltersSelected() {
    return _selectedTypes.any((type) => type.isGeneralLog) ||
        _selectedClasses.isNotEmpty;
  }

  /// Check if any API sub-filters are selected
  bool hasApiSubFiltersSelected() {
    return _selectedTypes.any((type) => type.isApiLog) ||
        _selectedMethods.isNotEmpty;
  }

  /// Clear all filters
  void clearAllFilters() {
    _selectedTypes.clear();
    _selectedSources.clear();
    _selectedClasses.clear();
    _selectedMethods.clear();
    _statsFilter = null;
    _isLoggerFiltersExpanded = false;
    _isApiFiltersExpanded = false;
    notifyListeners();
  }

  /// Apply filters to a list of logs
  List<UnifiedLogEntry> applyFilters(List<UnifiedLogEntry> logs) {
    final filteredLogs = logs.where((log) {
      // Search filter
      if (!log.matchesSearch(_searchQuery)) return false;

      // Type filter
      if (_selectedTypes.isNotEmpty && !_selectedTypes.contains(log.type)) {
        return false;
      }

      // Source filter
      if (_selectedSources.isNotEmpty &&
          !_selectedSources.contains(log.source)) {
        return false;
      }

      // Class filter (for general logs)
      if (_selectedClasses.isNotEmpty && log.source == LogSource.general) {
        final className = log.className;
        if (className == null || !_selectedClasses.contains(className)) {
          return false;
        }
      }

      // Method filter (for API logs)
      if (_selectedMethods.isNotEmpty && log.source == LogSource.api) {
        if (log.httpMethod == null ||
            !_selectedMethods.contains(log.httpMethod!)) {
          return false;
        }
      }

      // Statistics filter
      if (_statsFilter != null) {
        switch (_statsFilter) {
          case 'success':
            if (!log.type.isSuccess) return false;
            break;
          case 'errors':
            if (!log.type.isError) return false;
            break;
          case 'general':
            if (log.source != LogSource.general) return false;
            break;
          case 'api':
            if (log.source != LogSource.api) return false;
            break;
        }
      }

      return true;
    }).toList();

    // Apply sorting
    if (_sortNewestFirst) {
      filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else {
      filteredLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    return filteredLogs;
  }
}
