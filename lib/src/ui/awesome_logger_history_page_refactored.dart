import 'dart:async';

import 'package:flutter/material.dart';

import '../core/logging_using_logger.dart';
import 'managers/filter_manager.dart';
import 'services/log_data_service.dart';
import 'utils/copy_handler.dart';
import 'widgets/common/logger_search_bar.dart';
import 'widgets/common/logger_sort_toggle.dart';
import 'widgets/common/logger_statistics.dart';
import 'widgets/filters/filter_section.dart';
import 'widgets/logs/log_entry_widget.dart';

/// Refactored unified logger history page showing general, API, and BLoC logs in chronological order
class AwesomeLoggerHistoryPageRefactored extends StatefulWidget {
  /// Whether to show file paths in the UI
  final bool showFilePaths;

  /// Static flag to track if logger is currently open
  static bool _isLoggerOpen = false;

  /// Check if logger is currently open
  static bool get isLoggerOpen => _isLoggerOpen;

  const AwesomeLoggerHistoryPageRefactored(
      {super.key, this.showFilePaths = true});

  @override
  State<AwesomeLoggerHistoryPageRefactored> createState() =>
      _AwesomeLoggerHistoryPageRefactoredState();
}

class _AwesomeLoggerHistoryPageRefactoredState
    extends State<AwesomeLoggerHistoryPageRefactored> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  final FilterManager _filterManager = FilterManager();

  Timer? _refreshTimer;
  bool _isLoggingPaused = false;
  String? _selectedExpandedView = 'response';

  @override
  void initState() {
    super.initState();
    AwesomeLoggerHistoryPageRefactored._isLoggerOpen = true;
    _isLoggingPaused = LoggingUsingLogger.isPaused;

    // Set up periodic refresh
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _isLoggingPaused = LoggingUsingLogger.isPaused;
        });
      }
    });

    // Set up listeners
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
    _filterManager.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    AwesomeLoggerHistoryPageRefactored._isLoggerOpen = false;
    _refreshTimer?.cancel();
    _scrollController.dispose();
    _searchController.dispose();
    _filterManager.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    _filterManager.updateSearchQuery(_searchController.text);
  }

  void _onScroll() {
    FocusScope.of(context).unfocus();
  }

  void _onFilterChanged() {
    setState(() {});
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
    final allLogs = LogDataService.getUnifiedLogs();
    final filteredLogs = _filterManager.applyFilters(allLogs);

    if (filteredLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No logs to export')),
      );
      return;
    }

    final exportContent = LogDataService.exportLogsToString(filteredLogs);
    CopyHandler.exportLogsToClipboard(
      context,
      exportContent,
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
              LogDataService.clearAllLogs();
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
    _filterManager.setStatsFilter(filterKey);
  }

  @override
  Widget build(BuildContext context) {
    final allLogs = LogDataService.getUnifiedLogs();
    final filteredLogs = _filterManager.applyFilters(allLogs);
    final statistics = LogDataService.getStatistics(
      allLogs,
      selectedSources: _filterManager.selectedSources,
    );

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
              searchQuery: _filterManager.searchQuery,
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _clearAllLogs,
                  tooltip: 'Clear all logs',
                ),
              ],
            ),

            // Filter section
            FilterSection(
              filterManager: _filterManager,
              allLogs: allLogs,
            ),

            // Sort toggle and statistics
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 8),
              child: Row(
                children: [
                  LoggerSortToggle(
                    sortNewestFirst: _filterManager.sortNewestFirst,
                    onToggle: _filterManager.toggleSortOrder,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: LoggerStatistics(
                      statistics: statistics,
                      onStatisticTapped: _onStatisticTapped,
                      selectedFilter: _filterManager.statsFilter,
                    ),
                  ),
                ],
              ),
            ),

            // Clear all filters button
            if (_filterManager.hasActiveFilters()) ...[
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
                      onPressed: _filterManager.clearAllFilters,
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
                            _filterManager.searchQuery.isEmpty
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
                        return LogEntryWidget(
                          log: log,
                          showFilePaths: widget.showFilePaths,
                          selectedExpandedView: _selectedExpandedView,
                          onExpandedViewChanged: (view) {
                            setState(() {
                              _selectedExpandedView = view;
                            });
                          },
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
