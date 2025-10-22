import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api_logger/api_logger_service.dart';
import '../core/logging_using_logger.dart';
import '../core/unified_log_entry.dart';
import '../core/unified_log_types.dart';
import 'widgets/common/logger_export_dialog.dart';
import 'widgets/common/logger_filter_chips.dart';
import 'widgets/common/logger_search_bar.dart';
import 'widgets/common/logger_sort_toggle.dart';
import 'widgets/common/logger_statistics.dart';

/// Unified logger history page showing both general and API logs in chronological order
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
  bool _sortNewestFirst = true;
  bool _showFilters = false;
  bool _isLoggingPaused = false;

  // Filter sets
  final Set<UnifiedLogType> _selectedTypes = {};
  final Set<LogSource> _selectedSources = {};
  final Set<String> _selectedClasses = {}; // For general logs
  final Set<String> _selectedMethods = {}; // For API logs

  // Statistics filter
  String? _statsFilter;

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

  /// Get statistics for the current logs
  List<StatisticItem> _getStatistics() {
    final allLogs = _getUnifiedLogs();
    final generalCount =
        allLogs.where((l) => l.source == LogSource.general).length;
    final apiCount = allLogs.where((l) => l.source == LogSource.api).length;
    final successCount = allLogs.where((l) => l.type.isSuccess).length;
    final errorCount = allLogs.where((l) => l.type.isError).length;

    return [
      StatisticItem(
        label: 'Total',
        value: '${allLogs.length}',
        color: Colors.blue,
        filterKey: 'total',
      ),
      StatisticItem(
        label: 'General',
        value: '$generalCount',
        color: Colors.purple,
        filterKey: 'general',
      ),
      StatisticItem(
        label: 'API',
        value: '$apiCount',
        color: Colors.green,
        filterKey: 'api',
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

  /// Get available log types from current logs
  List<UnifiedLogType> _getAvailableTypes() {
    final allLogs = _getUnifiedLogs();
    return allLogs.map((l) => l.type).toSet().toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Get type counts for filter chips
  Map<UnifiedLogType, int> _getTypeCounts() {
    final allLogs = _getUnifiedLogs();
    final counts = <UnifiedLogType, int>{};
    for (final log in allLogs) {
      counts[log.type] = (counts[log.type] ?? 0) + 1;
    }
    return counts;
  }

  /// Get available classes from general logs
  List<String> _getAvailableClasses() {
    final allLogs = _getUnifiedLogs();
    return allLogs
        .where((l) => l.source == LogSource.general && l.className != null)
        .map((l) => l.className!)
        .toSet()
        .toList()
      ..sort();
  }

  /// Get available HTTP methods from API logs
  List<String> _getAvailableMethods() {
    final allLogs = _getUnifiedLogs();
    return allLogs
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
            'Are you sure you want to clear all general and API logs?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              LoggingUsingLogger.clearLogs();
              ApiLoggerService.clearApiLogs();
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
    }

    if (textToCopy.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: textToCopy));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredLogs();
    final statistics = _getStatistics();
    final availableTypes = _getAvailableTypes();
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: LoggerStatistics(
                      statistics: statistics,
                      onStatisticTapped: _onStatisticTapped,
                      selectedFilter: _statsFilter,
                    ),
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'More options',
                    onSelected: (value) {
                      FocusScope.of(context).unfocus();
                      switch (value) {
                        case 'toggle_filters':
                          setState(() {
                            _showFilters = !_showFilters;
                          });
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem<String>(
                        value: 'toggle_filters',
                        child: Row(
                          children: [
                            Icon(
                              _showFilters
                                  ? Icons.filter_alt_off
                                  : Icons.filter_alt,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _showFilters ? 'Hide Filters' : 'Show Filters',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Sort toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  LoggerSortToggle(
                    sortNewestFirst: _sortNewestFirst,
                    onToggle: () =>
                        setState(() => _sortNewestFirst = !_sortNewestFirst),
                  ),
                ],
              ),
            ),

            // Filters
            if (_showFilters)
              Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Log type filters
                    UnifiedLogTypeFilterChips(
                      availableTypes: availableTypes,
                      selectedTypes: _selectedTypes,
                      typeCounts: typeCounts,
                      onTypeChanged: (type, selected) {
                        setState(() {
                          if (selected) {
                            _selectedTypes.add(type);
                          } else {
                            _selectedTypes.remove(type);
                          }
                        });
                      },
                      onClearAll: () => setState(() => _selectedTypes.clear()),
                    ),
                    const SizedBox(height: 12),

                    // Source filters
                    LoggerFilterChips(
                      title: 'Sources:',
                      options: LogSource.values
                          .map((source) => FilterOption(
                                label: source.displayName,
                                value: source.name,
                                color: source.color,
                              ))
                          .toList(),
                      selectedFilters:
                          _selectedSources.map((s) => s.name).toSet(),
                      onFilterChanged: (value, selected) {
                        final source =
                            LogSource.values.firstWhere((s) => s.name == value);
                        setState(() {
                          if (selected) {
                            _selectedSources.add(source);
                          } else {
                            _selectedSources.remove(source);
                          }
                        });
                      },
                      onClearAll: () =>
                          setState(() => _selectedSources.clear()),
                    ),
                    const SizedBox(height: 12),

                    // Class filters (for general logs)
                    if (_getAvailableClasses().isNotEmpty) ...[
                      LoggerFilterChips(
                        title: 'Classes:',
                        options: _getAvailableClasses()
                            .map((className) => FilterOption(
                                  label: className,
                                  value: className,
                                ))
                            .toList(),
                        selectedFilters: _selectedClasses,
                        onFilterChanged: (value, selected) {
                          setState(() {
                            if (selected) {
                              _selectedClasses.add(value);
                            } else {
                              _selectedClasses.remove(value);
                            }
                          });
                        },
                        onClearAll: () =>
                            setState(() => _selectedClasses.clear()),
                      ),
                      const SizedBox(height: 12),
                    ],

                    // Method filters (for API logs)
                    if (_getAvailableMethods().isNotEmpty) ...[
                      LoggerFilterChips(
                        title: 'HTTP Methods:',
                        options: _getAvailableMethods()
                            .map((method) => FilterOption(
                                  label: method,
                                  value: method,
                                ))
                            .toList(),
                        selectedFilters: _selectedMethods,
                        onFilterChanged: (value, selected) {
                          setState(() {
                            if (selected) {
                              _selectedMethods.add(value);
                            } else {
                              _selectedMethods.remove(value);
                            }
                          });
                        },
                        onClearAll: () =>
                            setState(() => _selectedMethods.clear()),
                      ),
                    ],

                    // Clear all filters
                    if (_selectedTypes.isNotEmpty ||
                        _selectedSources.isNotEmpty ||
                        _selectedClasses.isNotEmpty ||
                        _selectedMethods.isNotEmpty ||
                        _statsFilter != null)
                      Row(
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
                                _statsFilter = null;
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
                  ],
                ),
              ),

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
                                  Icon(log.type.icon,
                                      color: Colors.white, size: 16),
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
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: log.source.color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    log.source.displayName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
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
                                            color:
                                                log.type.color.withOpacity(0.1),
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
}
