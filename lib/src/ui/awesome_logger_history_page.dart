import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api_logger/api_log_entry.dart';
import '../api_logger/api_logger_service.dart';
import '../bloc_logger/bloc_logger_service.dart';
import '../core/logging_using_logger.dart';
import '../core/unified_log_entry.dart';
import '../core/unified_log_types.dart';
import 'widgets/common/logger_export_dialog.dart';
import 'widgets/common/logger_search_bar.dart';
import 'widgets/common/logger_sort_toggle.dart';
import 'widgets/common/logger_statistics.dart';

/// Unified logger history page showing general, API, and BLoC logs in chronological order
class AwesomeLoggerHistoryPage extends StatefulWidget {
  /// Whether to show file paths in the UI
  final bool showFilePaths;

  /// Static flag to track if logger is currently open
  static bool _isLoggerOpen = false;

  /// Check if logger is currently open
  static bool get isLoggerOpen => _isLoggerOpen;

  const AwesomeLoggerHistoryPage({super.key, this.showFilePaths = true});

  @override
  State<AwesomeLoggerHistoryPage> createState() =>
      _AwesomeLoggerHistoryPageState();
}

class _AwesomeLoggerHistoryPageState extends State<AwesomeLoggerHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _refreshTimer;
  String _searchQuery = '';
  bool _sortNewestFirst = false;
  bool _isLoggingPaused = false;

  // Filter sets
  final Set<UnifiedLogType> _selectedTypes = {};
  final Set<LogSource> _selectedSources = {};
  final Set<String> _selectedClasses = {}; // For general logs
  final Set<String> _selectedMethods = {}; // For API logs
  final Set<String> _selectedBlocNames = {}; // For BLoC logs
  final Set<String> _selectedEventTypes = {}; // For BLoC logs
  final Set<String> _selectedStateTypes = {}; // For BLoC logs

  // Main filter section
  bool _isFilterSectionExpanded = true;

  // Expanded filter sections
  bool _isLoggerFiltersExpanded = false;
  bool _isApiFiltersExpanded = false;
  bool _isBlocFiltersExpanded = false;

  // Removed collapsible sub-sections - now showing directly when main filters are expanded

  // Statistics filter
  String? _statsFilter;

  // Expanded log view: 'request', 'response', 'curl'
  String? _selectedExpandedView = 'response';

  @override
  void initState() {
    super.initState();
    AwesomeLoggerHistoryPage._isLoggerOpen = true;
    _isLoggingPaused = LoggingUsingLogger.isPaused;
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _isLoggingPaused = LoggingUsingLogger.isPaused;
        });
      }
    });
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    AwesomeLoggerHistoryPage._isLoggerOpen = false;
    _refreshTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  void _onScroll() {
    FocusScope.of(context).unfocus();
  }

  /// Get all logs unified and sorted
  List<UnifiedLogEntry> _getUnifiedLogs() {
    final unifiedLogs = <UnifiedLogEntry>[];

    // Add general logs
    final generalLogs = LoggingUsingLogger.getLogs();
    for (final log in generalLogs) {
      unifiedLogs.add(UnifiedLogEntry.fromGeneralLog(log));
    }

    // Add API logs
    final apiLogs = ApiLoggerService.getApiLogs();
    for (final log in apiLogs) {
      unifiedLogs.add(UnifiedLogEntry.fromApiLog(log));
    }

    // Add BLoC logs
    final blocLogs = BlocLoggerService.getBlocLogs();
    for (final log in blocLogs) {
      unifiedLogs.add(UnifiedLogEntry.fromBlocLog(log));
    }

    return unifiedLogs;
  }

  /// Get filtered logs based on search and filters
  List<UnifiedLogEntry> _getFilteredLogs() {
    final allLogs = _getUnifiedLogs();
    final filteredLogs = allLogs.where((log) {
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

      // BLoC name filter (for BLoC logs)
      if (_selectedBlocNames.isNotEmpty && log.source == LogSource.bloc) {
        if (log.blocName == null ||
            !_selectedBlocNames.contains(log.blocName!)) {
          return false;
        }
      }

      // Event type filter (for BLoC logs)
      if (_selectedEventTypes.isNotEmpty && log.source == LogSource.bloc) {
        if (log.eventType == null ||
            !_selectedEventTypes.contains(log.eventType!)) {
          return false;
        }
      }

      // State type filter (for BLoC logs)
      if (_selectedStateTypes.isNotEmpty && log.source == LogSource.bloc) {
        if (log.stateType == null ||
            !_selectedStateTypes.contains(log.stateType!)) {
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
          case 'bloc':
            if (log.source != LogSource.bloc) return false;
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

  /// Get statistics for the current logs
  List<StatisticItem> _getStatistics() {
    final allLogs = _getUnifiedLogs();

    // Filter logs based on selected main filters
    List<UnifiedLogEntry> relevantLogs = allLogs;
    if (_selectedSources.isNotEmpty) {
      relevantLogs =
          allLogs.where((l) => _selectedSources.contains(l.source)).toList();
    }

    final successCount = relevantLogs.where((l) => l.type.isSuccess).length;
    final errorCount = relevantLogs.where((l) => l.type.isError).length;

    return [
      StatisticItem(
        label: 'Total',
        value: '${relevantLogs.length}',
        color: Colors.blue,
        filterKey: 'total',
      ),
      StatisticItem(
        label: 'Success',
        value: '$successCount',
        color: Colors.green,
        filterKey: 'success',
      ),
      StatisticItem(
        label: 'Errors',
        value: '$errorCount',
        color: Colors.red,
        filterKey: 'errors',
      ),
    ];
  }

  /// Get type counts for filter chips
  Map<UnifiedLogType, int> _getTypeCounts() {
    final allLogs = _getUnifiedLogs();

    // Filter logs based on selected main filters for accurate sub-filter counts
    List<UnifiedLogEntry> relevantLogs = allLogs;
    if (_selectedSources.isNotEmpty) {
      relevantLogs =
          allLogs.where((l) => _selectedSources.contains(l.source)).toList();
    }

    final counts = <UnifiedLogType, int>{};
    for (final log in relevantLogs) {
      counts[log.type] = (counts[log.type] ?? 0) + 1;
    }
    return counts;
  }

  /// Get available HTTP methods from API logs
  List<String> _getAvailableMethods() {
    final allLogs = _getUnifiedLogs();

    // Filter logs based on selected main filters
    List<UnifiedLogEntry> relevantLogs = allLogs;
    if (_selectedSources.isNotEmpty) {
      relevantLogs =
          allLogs.where((l) => _selectedSources.contains(l.source)).toList();
    }

    return relevantLogs
        .where((l) => l.source == LogSource.api && l.httpMethod != null)
        .map((l) => l.httpMethod!)
        .toSet()
        .toList()
      ..sort();
  }

  /// Toggle logging pause/resume
  void _toggleLoggingPause() {
    LoggingUsingLogger.setPauseLogging(!_isLoggingPaused);
    setState(() {
      _isLoggingPaused = !_isLoggingPaused;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isLoggingPaused ? 'Logging paused' : 'Logging resumed'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Export all logs
  void _exportAllLogs() {
    final filteredLogs = _getFilteredLogs();
    if (filteredLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logs to export')),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln('=== AWESOME FLUTTER LOGGER - UNIFIED EXPORT ===');
    buffer.writeln('Generated: ${DateTime.now().toIso8601String()}');
    buffer.writeln('Total logs: ${filteredLogs.length}');
    buffer.writeln();

    for (final log in filteredLogs) {
      buffer.writeln('--- ${log.source.displayName.toUpperCase()} LOG ---');
      buffer.writeln(log.formattedContent);
      buffer.writeln();
    }

    LoggerExportUtils.exportToClipboard(
      context: context,
      content: buffer.toString(),
      successMessage: 'All logs copied to clipboard',
      dialogTitle: 'Exported Unified Logs',
    );
  }

  /// Clear all logs
  void _clearAllLogs() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear All Logs'),
        content: const Text(
            'Are you sure you want to clear all general, API, and BLoC logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              LoggingUsingLogger.clearLogs();
              ApiLoggerService.clearApiLogs();
              BlocLoggerService.clearBlocLogs();
              setState(() {});
              Navigator.pop(context);
            },
            child: const Text('CLEAR'),
          ),
        ],
      ),
    );
  }

  /// Handle statistic tap for filtering
  void _onStatisticTapped(String filterKey) {
    setState(() {
      if (_statsFilter == filterKey) {
        _statsFilter = null; // Toggle off if already selected
      } else {
        _statsFilter = filterKey == 'total' ? null : filterKey;
      }
    });
  }

  /// Get count of general logs
  int _getGeneralLogCount() {
    final allLogs = _getUnifiedLogs();
    return allLogs.where((l) => l.source == LogSource.general).length;
  }

  /// Get count of API logs
  int _getApiLogCount() {
    final allLogs = _getUnifiedLogs();
    return allLogs.where((l) => l.source == LogSource.api).length;
  }

  /// Get count of BLoC logs
  int _getBlocLogCount() {
    final allLogs = _getUnifiedLogs();
    return allLogs.where((l) => l.source == LogSource.bloc).length;
  }

  /// Get count for specific HTTP method
  int _getMethodCount(String method) {
    final allLogs = _getUnifiedLogs();

    // Filter logs based on selected main filters
    List<UnifiedLogEntry> relevantLogs = allLogs;
    if (_selectedSources.isNotEmpty) {
      relevantLogs =
          allLogs.where((l) => _selectedSources.contains(l.source)).toList();
    }

    return relevantLogs.where((l) => l.httpMethod == method).length;
  }

  /// Get available BLoC names from BLoC logs
  List<String> _getAvailableBlocNames() {
    final allLogs = _getUnifiedLogs();

    // Filter logs based on selected main filters
    List<UnifiedLogEntry> relevantLogs = allLogs;
    if (_selectedSources.isNotEmpty) {
      relevantLogs =
          allLogs.where((l) => _selectedSources.contains(l.source)).toList();
    }

    return relevantLogs
        .where((l) => l.source == LogSource.bloc && l.blocName != null)
        .map((l) => l.blocName!)
        .toSet()
        .toList()
      ..sort();
  }

  /// Get available event types from BLoC logs
  List<String> _getAvailableEventTypes() {
    final allLogs = _getUnifiedLogs();

    // Filter logs based on selected main filters
    List<UnifiedLogEntry> relevantLogs = allLogs;
    if (_selectedSources.isNotEmpty) {
      relevantLogs =
          allLogs.where((l) => _selectedSources.contains(l.source)).toList();
    }

    return relevantLogs
        .where((l) => l.source == LogSource.bloc && l.eventType != null)
        .map((l) => l.eventType!)
        .toSet()
        .toList()
      ..sort();
  }

  /// Get available state types from BLoC logs
  List<String> _getAvailableStateTypes() {
    final allLogs = _getUnifiedLogs();

    // Filter logs based on selected main filters
    List<UnifiedLogEntry> relevantLogs = allLogs;
    if (_selectedSources.isNotEmpty) {
      relevantLogs =
          allLogs.where((l) => _selectedSources.contains(l.source)).toList();
    }

    return relevantLogs
        .where((l) => l.source == LogSource.bloc && l.stateType != null)
        .map((l) => l.stateType!)
        .toSet()
        .toList()
      ..sort();
  }

  /// Get count for specific BLoC name
  int _getBlocNameCount(String blocName) {
    final allLogs = _getUnifiedLogs();

    // Filter logs based on selected main filters
    List<UnifiedLogEntry> relevantLogs = allLogs;
    if (_selectedSources.isNotEmpty) {
      relevantLogs =
          allLogs.where((l) => _selectedSources.contains(l.source)).toList();
    }

    return relevantLogs.where((l) => l.blocName == blocName).length;
  }

  /// Get count for specific event type
  int _getEventTypeCount(String eventType) {
    final allLogs = _getUnifiedLogs();

    // Filter logs based on selected main filters
    List<UnifiedLogEntry> relevantLogs = allLogs;
    if (_selectedSources.isNotEmpty) {
      relevantLogs =
          allLogs.where((l) => _selectedSources.contains(l.source)).toList();
    }

    return relevantLogs.where((l) => l.eventType == eventType).length;
  }

  /// Get count for specific state type
  int _getStateTypeCount(String stateType) {
    final allLogs = _getUnifiedLogs();

    // Filter logs based on selected main filters
    List<UnifiedLogEntry> relevantLogs = allLogs;
    if (_selectedSources.isNotEmpty) {
      relevantLogs =
          allLogs.where((l) => _selectedSources.contains(l.source)).toList();
    }

    return relevantLogs.where((l) => l.stateType == stateType).length;
  }

  /// Check if any logger sub-filters are selected
  bool _hasLoggerSubFiltersSelected() {
    return _selectedTypes.any((type) => type.isGeneralLog);
  }

  /// Check if any API sub-filters are selected
  bool _hasApiSubFiltersSelected() {
    return _selectedTypes.any((type) => type.isApiLog) ||
        _selectedMethods.isNotEmpty;
  }

  /// Check if any BLoC sub-filters are selected
  bool _hasBlocSubFiltersSelected() {
    return _selectedTypes.any((type) => type.isBlocLog) ||
        _selectedBlocNames.isNotEmpty ||
        _selectedEventTypes.isNotEmpty ||
        _selectedStateTypes.isNotEmpty;
  }

  /// Get logger level label for unified log type
  String _getLoggerLevelLabel(UnifiedLogType type) {
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
  String _getApiStatusLabel(UnifiedLogType type) {
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
  String _getBlocStatusLabel(UnifiedLogType type) {
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

  /// Build main filter chip (Logger Logs, API Logs)
  Widget _buildMainFilterChip({
    required String label,
    required IconData icon,
    required Color color,
    required bool isSelected,
    required int count,
    required VoidCallback onTap,
    required bool isExpanded,
    required VoidCallback onDropdownTap,
    required bool hasSubFiltersSelected,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[100],
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

  /// Build sub-filter chip (logger.d, GET, Success, etc.)
  Widget _buildSubFilterChip({
    required String label,
    required Color color,
    required bool isSelected,
    required int count,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.grey[50],
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

  /// Check if there are any active filters
  bool _hasActiveFilters() {
    return _selectedTypes.isNotEmpty ||
        _selectedSources.isNotEmpty ||
        _selectedClasses.isNotEmpty ||
        _selectedMethods.isNotEmpty ||
        _selectedBlocNames.isNotEmpty ||
        _selectedEventTypes.isNotEmpty ||
        _selectedStateTypes.isNotEmpty ||
        _statsFilter != null;
  }

  /// Get count of active filters
  int _getActiveFilterCount() {
    int count = 0;
    count += _selectedTypes.length;
    count += _selectedSources.length;
    count += _selectedClasses.length;
    count += _selectedMethods.length;
    count += _selectedBlocNames.length;
    count += _selectedEventTypes.length;
    count += _selectedStateTypes.length;
    if (_statsFilter != null) count += 1;
    return count;
  }

  /// Get appropriate label for log type display
  String _getLogTypeLabel(UnifiedLogEntry log) {
    if (log.source == LogSource.api) {
      // For API logs, show the HTTP method
      return log.httpMethod ?? 'API';
    } else if (log.source == LogSource.bloc) {
      // For BLoC logs, show the BLoC type
      return _getBlocStatusLabel(log.type);
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

  /// Handle copy actions for logs
  void _handleCopyAction(String action, UnifiedLogEntry log) {
    String textToCopy = '';
    String successMessage = '';

    switch (action) {
      case 'copy_message':
        textToCopy = log.message;
        successMessage = 'Message copied to clipboard';
        break;
      case 'copy_full':
        textToCopy = log.formattedContent;
        successMessage = 'Full log copied to clipboard';
        break;
      case 'copy_curl':
        if (log.source == LogSource.api && log.apiLogEntry != null) {
          textToCopy = log.apiLogEntry!.curl;
          successMessage = 'cURL command copied to clipboard';
        }
        break;
      case 'copy_url':
        if (log.source == LogSource.api && log.url != null) {
          textToCopy = log.url!;
          successMessage = 'URL copied to clipboard';
        }
        break;
      case 'copy_stack':
        if (log.stackTrace != null) {
          textToCopy = log.stackTrace!;
          successMessage = 'Stack trace copied to clipboard';
        }
        break;
      case 'copy_bloc_command':
        if (log.source == LogSource.bloc && log.blocLogEntry != null) {
          textToCopy = log.blocLogEntry!.command;
          successMessage = 'BLoC command copied to clipboard';
        }
        break;
      case 'copy_bloc_name':
        if (log.blocName != null) {
          textToCopy = log.blocName!;
          successMessage = 'BLoC name copied to clipboard';
        }
        break;
      case 'copy_event_data':
        if (log.source == LogSource.bloc && log.blocLogEntry?.event != null) {
          textToCopy = log.blocLogEntry!.event.toString();
          successMessage = 'Event data copied to clipboard';
        }
        break;
      case 'copy_state_data':
        if (log.source == LogSource.bloc &&
            log.blocLogEntry?.nextState != null) {
          textToCopy = log.blocLogEntry!.nextState.toString();
          successMessage = 'State data copied to clipboard';
        }
        break;
    }

    if (textToCopy.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: textToCopy));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    }
  }

  /// Build API view section with chips and content
  Widget _buildApiViewSection(UnifiedLogEntry log) {
    if (log.apiLogEntry == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // View selector chips
        Row(
          children: [
            _buildViewChip('Request', 'request', log),
            const SizedBox(width: 8),
            if (log.apiLogEntry!.type != ApiLogType.pending)
              _buildViewChip('Response', 'response', log),
            if (log.apiLogEntry!.type != ApiLogType.pending)
              const SizedBox(width: 8),
            _buildViewChip('Curl', 'curl', log),
          ],
        ),
        const SizedBox(height: 12),
        // Content based on selected view
        if (_selectedExpandedView != null) _buildExpandedContent(log),
      ],
    );
  }

  /// Build BLoC view section with chips and content
  Widget _buildBlocViewSection(UnifiedLogEntry log) {
    if (log.blocLogEntry == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // View selector chips
        Row(
          children: [
            _buildViewChip('Request', 'request', log),
            const SizedBox(width: 8),
            _buildViewChip('Response', 'response', log),
            const SizedBox(width: 8),
            _buildViewChip('Command', 'command', log),
          ],
        ),
        const SizedBox(height: 12),
        // Content based on selected view
        if (_selectedExpandedView != null) _buildExpandedContent(log),
      ],
    );
  }

  /// Build view selector chip for expanded content
  Widget _buildViewChip(String label, String viewType, UnifiedLogEntry log) {
    final isSelected = _selectedExpandedView == viewType;

    // Don't show response chip for pending logs
    if (viewType == 'response' && log.apiLogEntry?.type == ApiLogType.pending) {
      return const SizedBox.shrink();
    }

    return FilterChip(
      selected: isSelected,
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onSelected: (selected) {
        setState(() {
          _selectedExpandedView = selected ? viewType : null;
        });
      },
      backgroundColor: isSelected ? Colors.blue[50] : Colors.grey[100],
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  /// Build expanded content based on selected view
  Widget _buildExpandedContent(UnifiedLogEntry log) {
    if (log.source == LogSource.api && log.apiLogEntry != null) {
      switch (_selectedExpandedView) {
        case 'request':
          return _buildContentSection(
              'Request', log.apiLogEntry!.formattedRequest);
        case 'response':
          return _buildContentSection(
              'Response', log.apiLogEntry!.formattedResponse);
        case 'curl':
          return _buildContentSection('Curl Command', log.apiLogEntry!.curl);
        default:
          return const SizedBox.shrink();
      }
    } else if (log.source == LogSource.bloc && log.blocLogEntry != null) {
      switch (_selectedExpandedView) {
        case 'request':
          return _buildContentSection(
              'Request', log.blocLogEntry!.formattedRequest);
        case 'response':
          return _buildContentSection(
              'Response', log.blocLogEntry!.formattedResponse);
        case 'command':
          return _buildContentSection('Command', log.blocLogEntry!.command);
        default:
          return const SizedBox.shrink();
      }
    }
    return const SizedBox.shrink();
  }

  /// Build content section with length limits and more button
  Widget _buildContentSection(String title, String content) {
    const maxLength = 500; // Maximum characters to show initially
    final shouldTruncate = content.length > maxLength;
    final displayContent =
        shouldTruncate ? '${content.substring(0, maxLength)}...' : content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _copyToClipboard(content),
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Copy content',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                if (shouldTruncate)
                  TextButton.icon(
                    onPressed: () => _showFullContent(title, content),
                    icon: const Icon(Icons.expand_more, size: 16),
                    label: const Text('More', style: TextStyle(fontSize: 11)),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: shouldTruncate ? () => _showFullContent(title, content) : null,
          behavior: HitTestBehavior.translucent,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: Text(
              displayContent,
              style: TextStyle(
                fontSize: 11,
                fontFamily: 'monospace',
                height: 1.4,
                color: shouldTruncate ? Colors.blue[700] : Colors.black87,
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Show full content in a bottom sheet
  void _showFullContent(String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          _copyToClipboard(content);
                        },
                        icon: const Icon(Icons.copy),
                        tooltip: 'Copy content',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Text(
                  content,
                  style: const TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    height: 1.4,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Copy content to clipboard and show feedback
  void _copyToClipboard(String content) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Content copied to clipboard'),
          duration: Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredLogs();
    final statistics = _getStatistics();
    final typeCounts = _getTypeCounts();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Awesome Flutter Logger',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: Icon(_isLoggingPaused ? Icons.play_arrow : Icons.pause),
            onPressed: _toggleLoggingPause,
            tooltip: _isLoggingPaused ? 'Resume Logging' : 'Pause Logging',
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportAllLogs,
            tooltip: 'Export All Logs',
          ),
        ],
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Column(
          children: [
            // Pause banner
            if (_isLoggingPaused)
              Container(
                width: double.infinity,
                color: Colors.orange.shade100,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Icon(
                      Icons.pause_circle_filled,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Logging is paused - No new logs will be recorded',
                        style: TextStyle(
                          color: Colors.orange.shade700,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: _toggleLoggingPause,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.play_arrow,
                                color: Colors.white, size: 16),
                            SizedBox(width: 4),
                            Text(
                              'Resume',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Search bar
            LoggerSearchBar(
              controller: _searchController,
              hintText: 'Search all logs...',
              searchQuery: _searchQuery,
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _clearAllLogs,
                  tooltip: 'Clear all logs',
                ),
              ],
            ),

            // Statistics
            // Padding(
            //   padding: const EdgeInsets.symmetric(horizontal: 16),
            //   child: Row(
            //     children: [
            //       Expanded(
            //         child: LoggerStatistics(
            //           statistics: statistics,
            //           onStatisticTapped: _onStatisticTapped,
            //           selectedFilter: _statsFilter,
            //         ),
            //       ),
            //     ],
            //   ),
            // ),

            // Collapsible filter section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter section header with collapse/expand
                  InkWell(
                    onTap: () => setState(() =>
                        _isFilterSectionExpanded = !_isFilterSectionExpanded),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 0),
                      child: Row(
                        children: [
                          // Icon(
                          //   _isFilterSectionExpanded
                          //       ? Icons.expand_less
                          //       : Icons.expand_more,
                          //   size: 20,
                          //   color: Colors.grey[700],
                          // ),
                          // const SizedBox(width: 8),
                          // const Text(
                          //   'Filter by',
                          //   style: TextStyle(
                          //     fontWeight: FontWeight.w600,
                          //     fontSize: 14,
                          //   ),
                          // ),
                          const Spacer(),
                          // Show active filter count when collapsed
                          if (!_isFilterSectionExpanded &&
                              _hasActiveFilters()) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                    color: Colors.blue.withValues(alpha: 0.3)),
                              ),
                              child: Text(
                                '${_getActiveFilterCount()} active',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blue[700],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),

                  // Expandable filter content
                  if (_isFilterSectionExpanded) ...[
                    const SizedBox(height: 8),

                    // Main filter categories
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          // Logger Logs filter
                          _buildMainFilterChip(
                            label: 'Logger Logs',
                            icon: Icons.bug_report,
                            color: Colors.purple,
                            isSelected:
                                _selectedSources.contains(LogSource.general),
                            count: _getGeneralLogCount(),
                            isExpanded: _isLoggerFiltersExpanded,
                            hasSubFiltersSelected:
                                _hasLoggerSubFiltersSelected(),
                            onTap: () {
                              setState(() {
                                if (_selectedSources
                                    .contains(LogSource.general)) {
                                  // If already selected, deselect and collapse
                                  _selectedSources.remove(LogSource.general);
                                  _isLoggerFiltersExpanded = false;
                                  _selectedTypes
                                      .removeWhere((type) => type.isGeneralLog);
                                } else {
                                  // Select
                                  _selectedSources.add(LogSource.general);
                                }
                              });
                            },
                            onDropdownTap: () {
                              setState(() {
                                _isLoggerFiltersExpanded =
                                    !_isLoggerFiltersExpanded;
                              });
                            },
                          ),
                          const SizedBox(width: 8),

                          // API Logs filter
                          _buildMainFilterChip(
                            label: 'API Logs',
                            icon: Icons.api,
                            color: Colors.green,
                            isSelected:
                                _selectedSources.contains(LogSource.api),
                            count: _getApiLogCount(),
                            isExpanded: _isApiFiltersExpanded,
                            hasSubFiltersSelected: _hasApiSubFiltersSelected(),
                            onTap: () {
                              setState(() {
                                if (_selectedSources.contains(LogSource.api)) {
                                  // If already selected, deselect and collapse
                                  _selectedSources.remove(LogSource.api);
                                  _isApiFiltersExpanded = false;
                                  _selectedTypes
                                      .removeWhere((type) => type.isApiLog);
                                  _selectedMethods.clear();
                                } else {
                                  // Select
                                  _selectedSources.add(LogSource.api);
                                }
                              });
                            },
                            onDropdownTap: () {
                              setState(() {
                                _isApiFiltersExpanded = !_isApiFiltersExpanded;
                              });
                            },
                          ),
                          const SizedBox(width: 8),

                          // BLoC Logs filter
                          _buildMainFilterChip(
                            label: 'BLoC Logs',
                            icon: Icons.account_tree,
                            color: Colors.purple,
                            isSelected:
                                _selectedSources.contains(LogSource.bloc),
                            count: _getBlocLogCount(),
                            isExpanded: _isBlocFiltersExpanded,
                            hasSubFiltersSelected: _hasBlocSubFiltersSelected(),
                            onTap: () {
                              setState(() {
                                if (_selectedSources.contains(LogSource.bloc)) {
                                  // If already selected, deselect and collapse
                                  _selectedSources.remove(LogSource.bloc);
                                  _isBlocFiltersExpanded = false;
                                  _selectedTypes
                                      .removeWhere((type) => type.isBlocLog);
                                  _selectedBlocNames.clear();
                                  _selectedEventTypes.clear();
                                  _selectedStateTypes.clear();
                                } else {
                                  // Select
                                  _selectedSources.add(LogSource.bloc);
                                }
                              });
                            },
                            onDropdownTap: () {
                              setState(() {
                                _isBlocFiltersExpanded =
                                    !_isBlocFiltersExpanded;
                              });
                            },
                          ),
                        ],
                      ),
                    ),

                    // Logger sub-filters
                    if (_isLoggerFiltersExpanded) ...[
                      // const SizedBox(height: 12),
                      // const Text(
                      //   'Logger Levels:',
                      //   style: TextStyle(
                      //     fontWeight: FontWeight.w500,
                      //     fontSize: 12,
                      //     color: Colors.grey,
                      //   ),
                      // ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          UnifiedLogType.debug,
                          UnifiedLogType.info,
                          UnifiedLogType.warning,
                          UnifiedLogType.error,
                        ]
                            .map((type) => _buildSubFilterChip(
                                  label: _getLoggerLevelLabel(type),
                                  color: type.color,
                                  isSelected: _selectedTypes.contains(type),
                                  count: typeCounts[type] ?? 0,
                                  onTap: () {
                                    setState(() {
                                      if (_selectedTypes.contains(type)) {
                                        _selectedTypes.remove(type);
                                      } else {
                                        _selectedTypes.add(type);
                                      }
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ],

                    // API sub-filters
                    if (_isApiFiltersExpanded) ...[
                      const SizedBox(height: 12),

                      // HTTP Methods section
                      if (_getAvailableMethods().isNotEmpty) ...[
                        // Divider(height: 1),
                        // const Text(
                        //   'HTTP Methods:',
                        //   style: TextStyle(
                        //     fontWeight: FontWeight.w500,
                        //     fontSize: 12,
                        //     color: Colors.grey,
                        //   ),
                        // ),
                        // const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _getAvailableMethods()
                              .map((method) => _buildSubFilterChip(
                                    label: method,
                                    color: Colors.green,
                                    isSelected:
                                        _selectedMethods.contains(method),
                                    count: _getMethodCount(method),
                                    onTap: () {
                                      setState(() {
                                        if (_selectedMethods.contains(method)) {
                                          _selectedMethods.remove(method);
                                        } else {
                                          _selectedMethods.add(method);
                                        }
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // API Status section
                      // const Text(
                      //   'API Status:',
                      //   style: TextStyle(
                      //     fontWeight: FontWeight.w500,
                      //     fontSize: 12,
                      //     color: Colors.grey,
                      //   ),
                      // ),
                      // const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          UnifiedLogType.apiSuccess,
                          UnifiedLogType.apiRedirect,
                          UnifiedLogType.apiClientError,
                          UnifiedLogType.apiServerError,
                          UnifiedLogType.apiNetworkError,
                          UnifiedLogType.apiPending,
                        ]
                            .map((type) => _buildSubFilterChip(
                                  label: _getApiStatusLabel(type),
                                  color: type.color,
                                  isSelected: _selectedTypes.contains(type),
                                  count: typeCounts[type] ?? 0,
                                  onTap: () {
                                    setState(() {
                                      if (_selectedTypes.contains(type)) {
                                        _selectedTypes.remove(type);
                                      } else {
                                        _selectedTypes.add(type);
                                      }
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ],

                    // BLoC sub-filters
                    if (_isBlocFiltersExpanded) ...[
                      const SizedBox(height: 12),

                      // BLoC Names section
                      if (_getAvailableBlocNames().isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _getAvailableBlocNames()
                              .map((blocName) => _buildSubFilterChip(
                                    label: blocName,
                                    color: Colors.purple,
                                    isSelected:
                                        _selectedBlocNames.contains(blocName),
                                    count: _getBlocNameCount(blocName),
                                    onTap: () {
                                      setState(() {
                                        if (_selectedBlocNames
                                            .contains(blocName)) {
                                          _selectedBlocNames.remove(blocName);
                                        } else {
                                          _selectedBlocNames.add(blocName);
                                        }
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // Event Types section
                      if (_getAvailableEventTypes().isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _getAvailableEventTypes()
                              .map((eventType) => _buildSubFilterChip(
                                    label: eventType,
                                    color: Colors.cyan,
                                    isSelected:
                                        _selectedEventTypes.contains(eventType),
                                    count: _getEventTypeCount(eventType),
                                    onTap: () {
                                      setState(() {
                                        if (_selectedEventTypes
                                            .contains(eventType)) {
                                          _selectedEventTypes.remove(eventType);
                                        } else {
                                          _selectedEventTypes.add(eventType);
                                        }
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // State Types section
                      if (_getAvailableStateTypes().isNotEmpty) ...[
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: _getAvailableStateTypes()
                              .map((stateType) => _buildSubFilterChip(
                                    label: stateType,
                                    color: Colors.indigo,
                                    isSelected:
                                        _selectedStateTypes.contains(stateType),
                                    count: _getStateTypeCount(stateType),
                                    onTap: () {
                                      setState(() {
                                        if (_selectedStateTypes
                                            .contains(stateType)) {
                                          _selectedStateTypes.remove(stateType);
                                        } else {
                                          _selectedStateTypes.add(stateType);
                                        }
                                      });
                                    },
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                      ],

                      // BLoC Status section
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          UnifiedLogType.blocEvent,
                          UnifiedLogType.blocTransition,
                          UnifiedLogType.blocChange,
                          UnifiedLogType.blocCreate,
                          UnifiedLogType.blocClose,
                          UnifiedLogType.blocError,
                        ]
                            .map((type) => _buildSubFilterChip(
                                  label: _getBlocStatusLabel(type),
                                  color: type.color,
                                  isSelected: _selectedTypes.contains(type),
                                  count: typeCounts[type] ?? 0,
                                  onTap: () {
                                    setState(() {
                                      if (_selectedTypes.contains(type)) {
                                        _selectedTypes.remove(type);
                                      } else {
                                        _selectedTypes.add(type);
                                      }
                                    });
                                  },
                                ))
                            .toList(),
                      ),
                    ],
                  ], // End of _isFilterSectionExpanded
                ],
              ),
            ),
            // Sort toggle
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  LoggerSortToggle(
                    sortNewestFirst: _sortNewestFirst,
                    onToggle: () =>
                        setState(() => _sortNewestFirst = !_sortNewestFirst),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LoggerStatistics(
                      statistics: statistics,
                      onStatisticTapped: _onStatisticTapped,
                      selectedFilter: _statsFilter,
                    ),
                  ),
                ],
              ),
            ),
            // Clear all filters button
            if (_selectedTypes.isNotEmpty ||
                _selectedSources.isNotEmpty ||
                _selectedClasses.isNotEmpty ||
                _selectedMethods.isNotEmpty ||
                _selectedBlocNames.isNotEmpty ||
                _selectedEventTypes.isNotEmpty ||
                _selectedStateTypes.isNotEmpty ||
                _statsFilter != null) ...[
              // const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 8),
                child: Row(
                  children: [
                    const Text(
                      'Active filters:',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        setState(() {
                          _selectedTypes.clear();
                          _selectedSources.clear();
                          _selectedClasses.clear();
                          _selectedMethods.clear();
                          _selectedBlocNames.clear();
                          _selectedEventTypes.clear();
                          _selectedStateTypes.clear();
                          _statsFilter = null;
                          _isLoggerFiltersExpanded = false;
                          _isApiFiltersExpanded = false;
                          _isBlocFiltersExpanded = false;
                        });
                      },
                      icon: const Icon(Icons.clear_all, size: 16),
                      label: const Text(
                        'Clear All',
                        style: TextStyle(fontSize: 12),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Logs list
            Expanded(
              child: filteredLogs.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.list_alt,
                              size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No logs available\nStart using the logger to see logs here'
                                : 'No logs matching "${_searchController.text}"',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      itemCount: filteredLogs.length,
                      itemBuilder: (context, index) {
                        final log = filteredLogs[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          elevation: 1,
                          child: ExpansionTile(
                            onExpansionChanged: (expanded) {
                              FocusScope.of(context).unfocus();
                            },
                            leading: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: log.type.color,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  _buildLogType(log),
                                  // Icon(log.type.icon,
                                  //     color: Colors.white, size: 12),
                                  if (log.statusCode != null)
                                    Text(
                                      '${log.statusCode}',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            title: Row(
                              children: [
                                // _buildLogType(log),
                                // const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    log.message,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  log.subtitle,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                                if (log.duration != null)
                                  Text(
                                    'Duration: ${log.duration}ms',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.blue,
                                    ),
                                  ),
                              ],
                            ),
                            trailing: PopupMenuButton<String>(
                              onSelected: (value) =>
                                  _handleCopyAction(value, log),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'copy_message',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.copy, size: 16),
                                      SizedBox(width: 8),
                                      Text('Copy Message'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: 'copy_full',
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.content_copy, size: 16),
                                      SizedBox(width: 8),
                                      Text('Copy Full Log'),
                                    ],
                                  ),
                                ),
                                if (log.source == LogSource.api) ...[
                                  const PopupMenuItem(
                                    value: 'copy_curl',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.terminal, size: 16),
                                        SizedBox(width: 8),
                                        Text('Copy cURL'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'copy_url',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.link, size: 16),
                                        SizedBox(width: 8),
                                        Text('Copy URL'),
                                      ],
                                    ),
                                  ),
                                ],
                                if (log.stackTrace != null)
                                  const PopupMenuItem(
                                    value: 'copy_stack',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.bug_report, size: 16),
                                        SizedBox(width: 8),
                                        Text('Copy Stack Trace'),
                                      ],
                                    ),
                                  ),
                                if (log.source == LogSource.bloc) ...[
                                  const PopupMenuItem(
                                    value: 'copy_bloc_command',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.code, size: 16),
                                        SizedBox(width: 8),
                                        Text('Copy Command'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'copy_bloc_name',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.account_tree, size: 16),
                                        SizedBox(width: 8),
                                        Text('Copy BLoC Name'),
                                      ],
                                    ),
                                  ),
                                  if (log.blocLogEntry?.event != null)
                                    const PopupMenuItem(
                                      value: 'copy_event_data',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.input, size: 16),
                                          SizedBox(width: 8),
                                          Text('Copy Event Data'),
                                        ],
                                      ),
                                    ),
                                  if (log.blocLogEntry?.nextState != null)
                                    const PopupMenuItem(
                                      value: 'copy_state_data',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.change_circle, size: 16),
                                          SizedBox(width: 8),
                                          Text('Copy State Data'),
                                        ],
                                      ),
                                    ),
                                ],
                              ],
                            ),
                            children: [
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16.0),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  border: Border(
                                    top: BorderSide(color: Colors.grey[200]!),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Log type and timestamp
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: log.type.color
                                                .withValues(alpha: 0.1),
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            border: Border.all(
                                              color: log.type.color,
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            log.type.displayName,
                                            style: TextStyle(
                                              color: log.type.color,
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          log.timestamp
                                              .toString()
                                              .substring(0, 19),
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),

                                    // Detailed content
                                    const Text(
                                      'Details:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(
                                            color: Colors.grey[300]!),
                                      ),
                                      child: SelectableText(
                                        log.detailedDescription,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                          height: 1.4,
                                        ),
                                      ),
                                    ),

                                    // API-specific view chips and content
                                    if (log.source == LogSource.api) ...[
                                      const SizedBox(height: 12),
                                      _buildApiViewSection(log),
                                    ],

                                    // BLoC-specific view chips and content
                                    if (log.source == LogSource.bloc) ...[
                                      const SizedBox(height: 12),
                                      _buildBlocViewSection(log),
                                    ],

                                    // File path for general logs
                                    if (widget.showFilePaths &&
                                        log.filePath != null) ...[
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Source:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      SelectableText(
                                        log.filePath!,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],

                                    // Stack trace for error logs
                                    if (log.stackTrace != null) ...[
                                      const SizedBox(height: 12),
                                      const Text(
                                        'Stack Trace:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Container(
                                        width: double.infinity,
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[100],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                          border: Border.all(
                                            color: Colors.grey[300]!,
                                          ),
                                        ),
                                        child: SelectableText(
                                          log.stackTrace!,
                                          style: const TextStyle(
                                            fontFamily: 'monospace',
                                            fontSize: 10,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogType(UnifiedLogEntry log) {
    return FittedBox(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: log.type.color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          _getLogTypeLabel(log),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
