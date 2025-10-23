import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api_logger/api_log_entry.dart';
import '../../api_logger/api_logger_service.dart';
import 'common/logger_export_dialog.dart';
import 'common/logger_filter_chips.dart';
import 'common/logger_search_bar.dart';
import 'common/logger_sort_toggle.dart';
import 'common/logger_statistics.dart';

/// API logs tab widget for displaying HTTP request/response logs
class ApiLogsTab extends StatefulWidget {
  /// Whether to show file paths in the UI
  final bool showFilePaths;

  const ApiLogsTab({super.key, this.showFilePaths = true});

  @override
  State<ApiLogsTab> createState() => _ApiLogsTabState();
}

class _ApiLogsTabState extends State<ApiLogsTab> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _refreshTimer;
  String _searchQuery = '';
  final Set<String> _selectedMethods = {};
  final Set<ApiLogType> _selectedTypes = {};
  final Set<String> _selectedEndpoints = {};
  bool _sortNewestFirst = false; // true = newest first, false = oldest first
  bool _showFilters = false;

  // Statistics filter: null = show all, 'success' = only success, 'errors' = only errors
  String? _statsFilter;

  // Expanded log view: 'request', 'response', 'curl'
  String? _selectedExpandedView = 'response';

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
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
    // Unfocus search field when scrolling
    FocusScope.of(context).unfocus();
  }

  /// Get filtered API logs based on search and filters
  List<ApiLogEntry> _getFilteredApiLogs() {
    final logs = ApiLoggerService.getApiLogs();
    final filteredLogs = logs.where((log) {
      // Search filter
      final matchesSearch = _searchQuery.isEmpty ||
          log.url.toLowerCase().contains(_searchQuery) ||
          log.method.toLowerCase().contains(_searchQuery) ||
          (log.error?.toLowerCase().contains(_searchQuery) ?? false) ||
          log.curl.toLowerCase().contains(_searchQuery);

      // Method filter
      final matchesMethod =
          _selectedMethods.isEmpty || _selectedMethods.contains(log.method);

      // Type filter
      final matchesType =
          _selectedTypes.isEmpty || _selectedTypes.contains(log.type);

      // Endpoint filter
      final endpoint = '${log.method} ${Uri.parse(log.url).path}';
      final matchesEndpoint =
          _selectedEndpoints.isEmpty || _selectedEndpoints.contains(endpoint);

      // Statistics filter
      final matchesStatsFilter = _statsFilter == null ||
          (_statsFilter == 'success' && log.type == ApiLogType.success) ||
          (_statsFilter == 'success' && log.type == ApiLogType.redirect) ||
          (_statsFilter == 'errors' &&
              (log.type == ApiLogType.clientError ||
                  log.type == ApiLogType.serverError ||
                  log.type == ApiLogType.networkError));

      return matchesSearch &&
          matchesMethod &&
          matchesType &&
          matchesEndpoint &&
          matchesStatsFilter;
    }).toList();

    // Apply sorting
    if (_sortNewestFirst) {
      // Newest first (current default behavior)
      filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else {
      // Oldest first (chronological order)
      filteredLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    return filteredLogs;
  }

  /// Get unique HTTP methods from logs
  List<String> _getUniqueMethods() {
    return ApiLoggerService.getApiLogs()
        .map((log) => log.method)
        .toSet()
        .toList();
  }

  /// Get color based on log type
  Color _getLogColor(ApiLogEntry log) {
    switch (log.type) {
      case ApiLogType.success:
        return Colors.green;
      case ApiLogType.redirect:
        return Colors.blue;
      case ApiLogType.clientError:
        return Colors.orange;
      case ApiLogType.serverError:
        return Colors.red;
      case ApiLogType.networkError:
        return Colors.purple;
      case ApiLogType.pending:
        return Colors.grey;
    }
  }

  /// Get count of successful API calls (2xx, 3xx responses)
  int _getSuccessCount() {
    final allLogs = ApiLoggerService.getApiLogs();
    return allLogs
        .where(
          (log) =>
              log.type == ApiLogType.success || log.type == ApiLogType.redirect,
        )
        .length;
  }

  /// Get count of error API calls (4xx, 5xx, network errors)
  int _getErrorCount() {
    final allLogs = ApiLoggerService.getApiLogs();
    return allLogs
        .where(
          (log) =>
              log.type == ApiLogType.clientError ||
              log.type == ApiLogType.serverError ||
              log.type == ApiLogType.networkError,
        )
        .length;
  }

  /// Get display name for log type
  String _getTypeDisplayName(ApiLogType type) {
    switch (type) {
      case ApiLogType.success:
        return 'Success (2xx)';
      case ApiLogType.redirect:
        return 'Redirect (3xx)';
      case ApiLogType.clientError:
        return 'Client Error (4xx)';
      case ApiLogType.serverError:
        return 'Server Error (5xx)';
      case ApiLogType.networkError:
        return 'Network Error';
      case ApiLogType.pending:
        return 'Pending';
    }
  }

  /// Get color for log type (for filter chips)
  Color _getTypeColor(ApiLogType type) {
    switch (type) {
      case ApiLogType.success:
        return Colors.green;
      case ApiLogType.redirect:
        return Colors.blue;
      case ApiLogType.clientError:
        return Colors.orange;
      case ApiLogType.serverError:
        return Colors.red;
      case ApiLogType.networkError:
        return Colors.purple;
      case ApiLogType.pending:
        return Colors.grey;
    }
  }

  /// Handle copy actions for API logs
  void _handleCopyAction(String action, ApiLogEntry log) {
    String textToCopy = '';
    String successMessage = '';

    switch (action) {
      case 'copy_curl':
        textToCopy = log.curl;
        successMessage = 'cURL command copied to clipboard';
        break;
      case 'copy_request':
        textToCopy = log.formattedRequest;
        successMessage = 'Request details copied to clipboard';
        break;
      case 'copy_response':
        textToCopy = log.formattedResponse;
        successMessage = 'Response details copied to clipboard';
        break;
      case 'copy_full':
        textToCopy = log.formattedFull;
        successMessage = 'Full API log copied to clipboard';
        break;
      case 'copy_url':
        textToCopy = log.url;
        successMessage = 'URL copied to clipboard';
        break;
    }

    if (textToCopy.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: textToCopy));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    }
  }

  /// Export filtered API logs
  void _exportApiLogs() {
    final filteredLogs = _getFilteredApiLogs();
    if (filteredLogs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No API logs to export')),
      );
      return;
    }

    final exportText = ApiLoggerService.exportApiLogs(logs: filteredLogs);
    LoggerExportUtils.exportToClipboard(
      context: context,
      content: exportText,
      successMessage: 'API logs copied to clipboard',
      dialogTitle: 'Exported API Logs',
    );
  }

  Container _buildApiStatus(ApiLogEntry log) {
    return Container(
      width: 40,
      height: 100,
      decoration: BoxDecoration(
        color: _getLogColor(log),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(_getLogIcon(log), color: Colors.white, size: 20),
          if (log.statusCode != null)
            Text(
              '${log.statusCode}',
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
        ],
      ),
    );
  }

  /// Get icon based on log type
  IconData _getLogIcon(ApiLogEntry log) {
    switch (log.type) {
      case ApiLogType.success:
        return Icons.check_circle;
      case ApiLogType.redirect:
        return Icons.redo;
      case ApiLogType.clientError:
        return Icons.warning;
      case ApiLogType.serverError:
        return Icons.error;
      case ApiLogType.networkError:
        return Icons.cloud_off;
      case ApiLogType.pending:
        return Icons.hourglass_empty;
    }
  }

  /// Build view selector chip for expanded content
  Widget _buildViewChip(String label, String viewType, ApiLogEntry log) {
    final isSelected = _selectedExpandedView == viewType;

    // Don't show response chip for pending logs
    if (viewType == 'response' && log.type == ApiLogType.pending) {
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
  Widget _buildExpandedContent(ApiLogEntry log) {
    switch (_selectedExpandedView) {
      case 'request':
        return _buildContentSection('Request', log.formattedRequest);
      case 'response':
        return _buildContentSection('Response', log.formattedResponse);
      case 'curl':
        return _buildContentSection('Curl Command', log.curl);
      default:
        return const SizedBox.shrink();
    }
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
                          //pop
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

  /// Get statistics for display
  List<StatisticItem> _getStatistics() {
    final allLogs = ApiLoggerService.getApiLogs();
    final stats = ApiLoggerService.getApiLogStats();

    return [
      StatisticItem(
        label: 'Total',
        value: '${allLogs.length}',
        color: Colors.blue,
        filterKey: 'total',
      ),
      StatisticItem(
        label: 'Success',
        value: '${_getSuccessCount()}',
        color: Colors.green,
        filterKey: 'success',
      ),
      StatisticItem(
        label: 'Errors',
        value: '${_getErrorCount()}',
        color: Colors.red,
        filterKey: 'errors',
      ),
      StatisticItem(
        label: 'Avg Time',
        value: '${(stats['avgDuration'] as double).toStringAsFixed(0)}ms',
        color: Colors.orange,
        filterKey: 'avg_time',
      ),
    ];
  }

  /// Handle statistic tap for filtering
  void _onStatisticTapped(String filterKey) {
    setState(() {
      if (_statsFilter == filterKey) {
        _statsFilter = null; // Toggle off if already selected
      } else {
        _statsFilter =
            filterKey == 'total' || filterKey == 'avg_time' ? null : filterKey;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredApiLogs();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          // Search bar using reusable component
          LoggerSearchBar(
            controller: _searchController,
            hintText: 'Search API logs...',
            searchQuery: _searchQuery,
            actions: [
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {
                  FocusScope.of(context).unfocus();
                  showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Clear API Logs'),
                      content: const Text(
                        'Are you sure you want to clear all API logs?',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () {
                            ApiLoggerService.clearApiLogs();
                            setState(() {});
                            Navigator.pop(context);
                          },
                          child: const Text('CLEAR'),
                        ),
                      ],
                    ),
                  );
                },
                tooltip: 'Clear logs',
              ),
            ],
          ),

          // Statistics and controls
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withValues(alpha: 0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              children: [
                const SizedBox(height: 12),

                // Statistics using reusable component
                Row(
                  children: [
                    Expanded(
                      child: LoggerStatistics(
                        statistics: _getStatistics(),
                        onStatisticTapped: _onStatisticTapped,
                        selectedFilter: _statsFilter,
                      ),
                    ),

                    //vertical dots menu
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'More options',
                      onSelected: (value) {
                        FocusScope.of(context).unfocus();
                        switch (value) {
                          case 'export':
                            _exportApiLogs();
                            break;
                          case 'toggle_filters':
                            setState(() {
                              _showFilters = !_showFilters;
                            });
                            break;
                        }
                      },
                      itemBuilder: (BuildContext context) => [
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
                              SizedBox(width: 8),
                              Text(
                                _showFilters
                                    ? 'Hide Status Code Filters'
                                    : 'Show Status Code Filters',
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem<String>(
                          value: 'export',
                          child: Row(
                            children: [
                              Icon(Icons.download_outlined, size: 20),
                              SizedBox(width: 8),
                              Text('Export Data'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Sort toggle button using reusable component
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: LoggerSortToggle(
              sortNewestFirst: _sortNewestFirst,
              onToggle: () =>
                  setState(() => _sortNewestFirst = !_sortNewestFirst),
            ),
          ),

          // Filters using reusable components
          if (_showFilters)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type filters
                  LoggerFilterChips(
                    title: 'Status:',
                    options: ApiLogType.values
                        .map((type) => FilterOption(
                              label: _getTypeDisplayName(type),
                              value: type.name,
                              color: _getTypeColor(type),
                            ))
                        .toList(),
                    selectedFilters: _selectedTypes.map((t) => t.name).toSet(),
                    onFilterChanged: (value, selected) {
                      final type =
                          ApiLogType.values.firstWhere((t) => t.name == value);
                      setState(() {
                        if (selected) {
                          _selectedTypes.add(type);
                        } else {
                          _selectedTypes.remove(type);
                        }
                      });
                    },
                    onClearAll: () => setState(() => _selectedTypes.clear()),
                    showClearAll: false, // We'll show a global clear all below
                  ),
                  const SizedBox(height: 8),

                  // Method filters
                  if (_getUniqueMethods().isNotEmpty) ...[
                    LoggerFilterChips(
                      title: 'Methods:',
                      options: _getUniqueMethods()
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
                      showClearAll:
                          false, // We'll show a global clear all below
                    ),
                    const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 8),
                  // Clear all filters button
                  if (_selectedTypes.isNotEmpty ||
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

          // API logs list - This takes up the remaining space
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.api, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No API logs available\nIf using Dio, make sure to add the interceptor to your Dio instance \neg. `dio.interceptors.add(FlutterAwesomeLoggerDioInterceptor());`'
                              : 'No logs matching "${_searchController.text}"',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'API calls will appear here automatically',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 14,
                          ),
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
                        // color: _getLogColor(log),
                        child: ExpansionTile(
                          onExpansionChanged: (expanded) {
                            FocusScope.of(context).unfocus();
                          },
                          leading: _buildApiStatus(log),
                          title: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: _getLogColor(log),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  log.method,
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
                                  log.displayTitle,
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
                                log.shortDescription,
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
                          trailing: Column(
                            children: [
                              // _buildApiStatus(log),
                              PopupMenuButton<String>(
                                child: Icon(Icons.more_horiz, size: 28),
                                onSelected: (value) =>
                                    _handleCopyAction(value, log),
                                itemBuilder: (context) => [
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
                                  const PopupMenuItem(
                                    value: 'copy_request',
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.upload, size: 16),
                                        SizedBox(width: 8),
                                        Text('Copy Request'),
                                      ],
                                    ),
                                  ),
                                  if (log.type != ApiLogType.pending)
                                    const PopupMenuItem(
                                      value: 'copy_response',
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.download, size: 16),
                                          SizedBox(width: 8),
                                          Text('Copy Response'),
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
                                ],
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
                                  // View selector chips
                                  Row(
                                    children: [
                                      _buildViewChip('Request', 'request', log),
                                      const SizedBox(width: 8),
                                      if (log.type != ApiLogType.pending)
                                        _buildViewChip(
                                          'Response',
                                          'response',
                                          log,
                                        ),
                                      if (log.type != ApiLogType.pending)
                                        const SizedBox(width: 8),
                                      _buildViewChip('Curl', 'curl', log),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Content based on selected view
                                  if (_selectedExpandedView != null)
                                    _buildExpandedContent(log),
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
    );
  }
}
