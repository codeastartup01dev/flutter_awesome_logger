import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../api_logger/api_log_entry.dart';
import '../../api_logger/api_logger_service.dart';

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
  bool _sortNewestFirst = true; // true = newest first, false = oldest first
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

  /// Get filtered API logs based on search and filters
  List<ApiLogEntry> _getFilteredApiLogs() {
    final logs = ApiLoggerService.getApiLogs();
    final filteredLogs = logs.where((log) {
      // Search filter
      final matchesSearch =
          _searchQuery.isEmpty ||
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
      final matchesStatsFilter =
          _statsFilter == null ||
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No API logs to export')));
      return;
    }

    final exportText = ApiLoggerService.exportApiLogs(logs: filteredLogs);
    Clipboard.setData(ClipboardData(text: exportText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('API logs copied to clipboard'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _showExportDialog(exportText),
        ),
      ),
    );
  }

  /// Show export dialog
  void _showExportDialog(String exportText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exported API Logs'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: Text(
              exportText,
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Clipboard.setData(ClipboardData(text: exportText));
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Copied to clipboard')),
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
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
    final displayContent = shouldTruncate
        ? '${content.substring(0, maxLength)}...'
        : content;

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

  /// Build statistics item widget
  Widget _buildStatItem(
    String label,
    String value,
    Color color, {
    VoidCallback? onTap,
  }) {
    final isSelected =
        (label == 'Total' && _statsFilter == null) ||
        (label == 'Success' && _statsFilter == 'success') ||
        (label == 'Errors' && _statsFilter == 'errors');

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredApiLogs();
    final stats = ApiLoggerService.getApiLogStats();

    return Column(
      children: [
        // Header with search and actions
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
              // Search bar and actions
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search API logs...',
                        filled: true,
                        fillColor: Colors.grey[100],
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () => _searchController.clear(),
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () {
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
              const SizedBox(height: 12),

              // Statistics and sorting vertical dots menu
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 0,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            'Total',
                            '${ApiLoggerService.getApiLogs().length}',
                            Colors.blue,
                            onTap: () {
                              setState(() {
                                _statsFilter = null; // Show all logs
                              });
                            },
                          ),
                          _buildStatItem(
                            'Success',
                            '${_getSuccessCount()}',
                            Colors.green,
                            onTap: () {
                              setState(() {
                                _statsFilter = _statsFilter == 'success'
                                    ? null
                                    : 'success';
                              });
                            },
                          ),
                          _buildStatItem(
                            'Errors',
                            '${_getErrorCount()}',
                            Colors.red,
                            onTap: () {
                              setState(() {
                                _statsFilter = _statsFilter == 'errors'
                                    ? null
                                    : 'errors';
                              });
                            },
                          ),
                          _buildStatItem(
                            'Avg Time',
                            '${(stats['avgDuration'] as double).toStringAsFixed(0)}ms',
                            Colors.orange,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Sort toggle button
                  _buildToggleButton(context),
                  //vertical dots menu
                  PopupMenuButton<String>(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.more_vert),
                    tooltip: 'More options',
                    onSelected: (value) {
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

        // Filters
        if (_showFilters)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Type filters
                const Text(
                  'Status:',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                ),
                const SizedBox(height: 4),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: ApiLogType.values
                        .map(
                          (type) => Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              selected: _selectedTypes.contains(type),
                              label: Text(
                                _getTypeDisplayName(type),
                                style: const TextStyle(fontSize: 11),
                              ),
                              backgroundColor: _selectedTypes.contains(type)
                                  ? _getTypeColor(type).withValues(alpha: 0.2)
                                  : null,
                              selectedColor: _getTypeColor(
                                type,
                              ).withValues(alpha: 0.3),
                              onSelected: (selected) {
                                setState(() {
                                  if (selected) {
                                    _selectedTypes.add(type);
                                  } else {
                                    _selectedTypes.remove(type);
                                  }
                                });
                              },
                              materialTapTargetSize:
                                  MaterialTapTargetSize.shrinkWrap,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
                const SizedBox(height: 8),

                // Method filters
                if (_getUniqueMethods().isNotEmpty) ...[
                  const Text(
                    'Methods:',
                    style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _getUniqueMethods()
                          .map(
                            (method) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                selected: _selectedMethods.contains(method),
                                label: Text(
                                  method,
                                  style: const TextStyle(fontSize: 11),
                                ),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      _selectedMethods.add(method);
                                    } else {
                                      _selectedMethods.remove(method);
                                    }
                                  });
                                },
                                materialTapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
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
                            ? 'No API logs available'
                            : 'No logs matching "${_searchController.text}"',
                        style: TextStyle(color: Colors.grey[600], fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'API calls will appear here automatically',
                        style: TextStyle(color: Colors.grey[500], fontSize: 14),
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
                        leading: _buildApiStatus(log),
                        title: Text(
                          log.displayTitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
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
    );
  }

  IconButton _buildToggleButton(BuildContext context) {
    return IconButton(
      icon: Icon(
        _sortNewestFirst ? Icons.arrow_downward : Icons.arrow_upward,
        color: Colors.deepPurple,
      ),
      onPressed: () {
        setState(() {
          _sortNewestFirst = !_sortNewestFirst;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _sortNewestFirst
                    ? 'Showing Newest logs first'
                    : 'Showing Oldest logs first',
              ),
            ),
          );
        });
      },
      tooltip: _sortNewestFirst ? 'Newest logs first' : 'Oldest logs first',
    );
  }
}
