import 'dart:async';

import 'package:flutter/material.dart';

import '../core/logging_using_logger.dart';
import '../core/unified_log_entry.dart';
import '../core/unified_log_types.dart';
import 'managers/filter_manager.dart';
import 'services/log_data_service.dart';
import 'utils/copy_handler.dart';
import 'widgets/common/logger_search_bar.dart';
import 'widgets/common/logger_sort_toggle.dart';
import 'widgets/common/logger_statistics.dart';
import 'widgets/filters/class_filter_bottom_sheet.dart';
import 'widgets/filters/filter_section.dart';
import 'widgets/logs/log_entry_widget.dart';

/// Refactored unified logger history page showing general, API, and BLoC logs in chronological order
class AwesomeLoggerHistoryPage extends StatefulWidget {
  /// Whether to show file paths in the UI
  final bool showFilePaths;

  /// Default main filter to be selected when opening the logger history page
  final LogSource? defaultMainFilter;

  /// Static flag to track if logger is currently open
  static bool _isLoggerOpen = false;

  /// Check if logger is currently open
  static bool get isLoggerOpen => _isLoggerOpen;

  const AwesomeLoggerHistoryPage({
    super.key,
    this.showFilePaths = true,
    this.defaultMainFilter,
  });

  @override
  State<AwesomeLoggerHistoryPage> createState() =>
      _AwesomeLoggerHistoryPageState();
}

class _AwesomeLoggerHistoryPageState extends State<AwesomeLoggerHistoryPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  late final FilterManager _filterManager;

  Timer? _refreshTimer;
  bool _isLoggingPaused = false;
  String? _selectedExpandedView = 'response';

  @override
  void initState() {
    super.initState();
    AwesomeLoggerHistoryPage._isLoggerOpen = true;
    _isLoggingPaused = LoggingUsingLogger.isPaused;

    // Initialize FilterManager with default main filter
    _filterManager = FilterManager(defaultMainFilter: widget.defaultMainFilter);

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
    AwesomeLoggerHistoryPage._isLoggerOpen = false;
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

  /// Show settings modal bottom sheet
  void _showSettingsModal() {
    final TextEditingController maxLogEntriesController = TextEditingController(
      text: LoggingUsingLogger.config.maxLogEntries.toString(),
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final currentConfig = LoggingUsingLogger.config;

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 16,
                right: 16,
                top: 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Icon(
                        Icons.settings,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Logger Settings',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                        tooltip: 'Close',
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Settings content
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Max Log Entries
                          Text(
                            'Maximum Log Entries',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: maxLogEntriesController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              hintText: 'Enter maximum log entries',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                            ),
                            onChanged: (value) {
                              // Update immediately as user types
                              final intValue = int.tryParse(value);
                              if (intValue != null && intValue > 0) {
                                final newConfig = currentConfig.copyWith(
                                  maxLogEntries: intValue,
                                );
                                LoggingUsingLogger.configure(newConfig);
                                setModalState(() {});
                                setState(() {});
                              }
                            },
                          ),
                          const SizedBox(height: 20),

                          // Circular Buffer Toggle
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(
                                  0x1F000000), // Semi-transparent black for subtle background
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: const Color(
                                    0x33000000), // Semi-transparent black for outline
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Circular Buffer',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            currentConfig.enableCircularBuffer
                                                ? 'Oldest logs are automatically replaced with new ones when maxLogEntries limit is reached'
                                                : 'Logging stops when maxLogEntries limit is reached',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: currentConfig.enableCircularBuffer,
                                      onChanged: (value) {
                                        final newConfig =
                                            currentConfig.copyWith(
                                          enableCircularBuffer: value,
                                        );
                                        LoggingUsingLogger.configure(newConfig);
                                        setModalState(() {});
                                        setState(() {});
                                      },
                                      materialTapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Console Output Settings
                          Text(
                            'Console Output',
                            style: TextStyle(
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Show File Paths
                          _buildSettingToggle(
                            title: 'Show File Paths',
                            subtitle:
                                'Display file path and line numbers in console logs',
                            value: currentConfig.showFilePaths,
                            onChanged: (value) {
                              final newConfig =
                                  currentConfig.copyWith(showFilePaths: value);
                              LoggingUsingLogger.configure(newConfig);
                              setModalState(() {});
                            },
                          ),

                          // Show Emojis
                          _buildSettingToggle(
                            title: 'Show Emojis',
                            subtitle:
                                'Display emoji indicators in console logs',
                            value: currentConfig.showEmojis,
                            onChanged: (value) {
                              final newConfig =
                                  currentConfig.copyWith(showEmojis: value);
                              LoggingUsingLogger.configure(newConfig);
                              setModalState(() {});
                            },
                          ),

                          // Use Colors
                          _buildSettingToggle(
                            title: 'Use Colors',
                            subtitle:
                                'Apply color coding to console log levels',
                            value: currentConfig.useColors,
                            onChanged: (value) {
                              final newConfig =
                                  currentConfig.copyWith(useColors: value);
                              LoggingUsingLogger.configure(newConfig);
                              setModalState(() {});
                            },
                          ),

                          const SizedBox(height: 24),

                          // Current Stats
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(
                                  0x1F2196F3), // Semi-transparent blue for primary container background
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Current: ${LogDataService.getUnifiedLogs().length} logs stored',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 16),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Build a setting toggle row
  Widget _buildSettingToggle({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
        ],
      ),
    );
  }

  /// Build the classes filter button
  Widget _buildClassesFilterButton(List<UnifiedLogEntry> allLogs) {
    // Count all selections (classes, source names, and file paths)
    final classCount = _filterManager.selectedClasses.length;
    final sourceNameCount = _filterManager.selectedSourceNames.length;
    final filePathCount = _filterManager.selectedFilePaths.length;
    final selectedCount = classCount + sourceNameCount + filePathCount;
    final hasSelection = selectedCount > 0;

    // Check if there are any available sources or file paths
    final availableClasses = LogDataService.getAvailableClasses(
      allLogs,
      selectedSources: _filterManager.selectedSources,
    );
    final availableSources = LogDataService.getAvailableSources(
      allLogs,
      selectedSources: _filterManager.selectedSources,
    );
    final availableFilePaths = LogDataService.getAvailableFilePaths(
      allLogs,
      selectedSources: _filterManager.selectedSources,
    );
    final hasAvailableItems = availableClasses.isNotEmpty ||
        availableSources.isNotEmpty ||
        availableFilePaths.isNotEmpty;

    return ElevatedButton.icon(
      onPressed: () {
        FocusScope.of(context).unfocus();
        ClassFilterBottomSheet.show(
          context: context,
          filterManager: _filterManager,
          allLogs: allLogs,
        );
      },
      icon: Icon(
        Icons.filter_list,
        size: 16,
        color: hasAvailableItems ? null : Colors.grey[400],
      ),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Source',
            style: TextStyle(
              fontSize: 12,
              color: hasAvailableItems ? null : Colors.grey[400],
            ),
          ),
          if (hasSelection) ...[
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: hasAvailableItems
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey[300]!.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$selectedCount',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: hasAvailableItems ? null : Colors.grey[600],
                ),
              ),
            ),
          ],
        ],
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: hasSelection && hasAvailableItems
            ? Colors.blue[900]!
            : hasAvailableItems
                ? const Color(0x1A0000FF) // blue with 10% opacity
                : Colors.grey[200], // grey background when no items
        foregroundColor: hasAvailableItems
            ? (hasSelection ? Colors.white : Colors.blue[900]!)
            : Colors.grey[500], // grey text when disabled
        elevation: 0,
      ),
    );
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
            icon: const Icon(
              Icons.settings,
              color: Colors.blueAccent,
            ),
            onPressed: _showSettingsModal,
            tooltip: 'Settings',
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
          mainAxisAlignment: MainAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
                  // LoggerSortToggle(
                  //   sortNewestFirst: _filterManager.sortNewestFirst,
                  //   onToggle: _filterManager.toggleSortOrder,
                  // ),
                  // const SizedBox(width: 16),
                  LoggerStatistics(
                    statistics: statistics,
                    onStatisticTapped: _onStatisticTapped,
                    selectedFilter: _filterManager.statsFilter,
                  ),
                ],
              ),
            ),

            SizedBox(
              height: 40,
              child: ListView(
                shrinkWrap: true,
                scrollDirection: Axis.horizontal,
                children: [
                  const SizedBox(width: 16),
                  LoggerSortToggle(
                    oldestFirstLabel: 'Oldest logs first',
                    newestFirstLabel: 'Newest logs first',
                    sortNewestFirst: _filterManager.sortNewestFirst,
                    onToggle: _filterManager.toggleSortOrder,
                  ),
                  const SizedBox(width: 8),
                  _buildClassesFilterButton(allLogs),
                  // Clear source filters button (only show when there are selections)
                  if (_filterManager.selectedClasses.isNotEmpty ||
                      _filterManager.selectedSourceNames.isNotEmpty ||
                      _filterManager.selectedFilePaths.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _filterManager.clearAllSourceFilters();
                      },
                      tooltip: 'Clear source filters',
                      padding: const EdgeInsets.all(0),
                      constraints: const BoxConstraints(),
                      style: IconButton.styleFrom(
                        foregroundColor: Colors.blue[900]!,
                      ),
                    ),
                  const SizedBox(width: 8),
                  //copy (count) filtered logs to clipboard
                  InkWell(
                    onTap: () {
                      final allLogs = LogDataService.getUnifiedLogs();
                      final filteredLogs = _filterManager.applyFilters(allLogs);
                      if (filteredLogs.isNotEmpty) {
                        final exportContent =
                            LogDataService.exportLogsToString(filteredLogs);
                        CopyHandler.exportLogsToClipboard(
                          context,
                          exportContent,
                          successMessage:
                              'Copied ${filteredLogs.length} filtered logs to clipboard',
                          dialogTitle: 'Filtered Logs Export',
                        );
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Row(
                        children: [
                          Icon(
                            Icons.copy,
                            size: 16,
                            color: Colors.purple,
                          ),
                          Text('(${filteredLogs.length}) filtered logs'),
                        ],
                      ),
                    ),
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
