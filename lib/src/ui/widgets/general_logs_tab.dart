import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/logging_using_logger.dart';
import '../../core/log_entry.dart';

/// General logs tab widget for displaying application logs
class GeneralLogsTab extends StatefulWidget {
  /// Whether to show file paths in the UI
  final bool showFilePaths;

  const GeneralLogsTab({super.key, this.showFilePaths = true});

  @override
  State<GeneralLogsTab> createState() => _GeneralLogsTabState();
}

class _GeneralLogsTabState extends State<GeneralLogsTab> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  Timer? _refreshTimer;
  String _searchQuery = '';
  final Set<String> _selectedClasses = {};
  final Set<String> _selectedLevels = {};
  bool _sortNewestFirst = true;
  bool _autoScroll = true;

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

  List<String> _getUniqueClasses() {
    final logs = LoggingUsingLogger.getLogs();
    return logs
        .map((log) => log.filePath.split('/').last.split('.').first)
        .toSet()
        .toList();
  }

  List<LogEntry> _getFilteredLogs() {
    final logs = LoggingUsingLogger.getLogs();
    final filteredLogs = logs.where((log) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          log.message.toLowerCase().contains(_searchQuery) ||
          log.filePath.toLowerCase().contains(_searchQuery) ||
          log.level.toLowerCase().contains(_searchQuery) ||
          (log.stackTrace?.toLowerCase().contains(_searchQuery) ?? false);

      final matchesClass =
          _selectedClasses.isEmpty ||
          _selectedClasses.contains(
            log.filePath.split('/').last.split('.').first,
          );

      final matchesLevel =
          _selectedLevels.isEmpty || _selectedLevels.contains(log.level);

      return matchesSearch && matchesClass && matchesLevel;
    }).toList();

    // Apply sorting
    if (_sortNewestFirst) {
      filteredLogs.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else {
      filteredLogs.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    return filteredLogs;
  }

  Color _getLevelColor(String level) {
    switch (level) {
      case 'DEBUG':
        return Colors.grey;
      case 'INFO':
        return Colors.blue;
      case 'WARNING':
        return Colors.orange;
      case 'ERROR':
        return Colors.red;
      default:
        return Colors.black;
    }
  }

  IconData _getLevelIcon(String level) {
    switch (level) {
      case 'DEBUG':
        return Icons.bug_report;
      case 'INFO':
        return Icons.info;
      case 'WARNING':
        return Icons.warning;
      case 'ERROR':
        return Icons.error;
      default:
        return Icons.circle;
    }
  }

  List<String> _getAvailableLevels() {
    return ['DEBUG', 'INFO', 'ERROR', 'WARNING'];
  }

  void _exportLogs() {
    final filteredLogs = _getFilteredLogs();
    if (filteredLogs.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No logs to export')));
      return;
    }

    final exportText = LoggingUsingLogger.exportLogs(logs: filteredLogs);
    Clipboard.setData(ClipboardData(text: exportText));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Logs copied to clipboard'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _showExportDialog(exportText),
        ),
      ),
    );
  }

  void _showExportDialog(String exportText) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exported Logs'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
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

  void _handleLogAction(String action, LogEntry log) {
    String textToCopy = '';
    String successMessage = '';

    switch (action) {
      case 'copy_message':
        textToCopy = log.message;
        successMessage = 'Message copied to clipboard';
        break;
      case 'copy_full':
        final buffer = StringBuffer();
        buffer.writeln('Level: ${log.level}');
        buffer.writeln('Time: ${log.timestamp}');
        buffer.writeln('File: ${log.filePath}');
        buffer.writeln('Message: ${log.message}');
        if (log.stackTrace != null) {
          buffer.writeln('Stack Trace:');
          buffer.writeln(log.stackTrace);
        }
        textToCopy = buffer.toString();
        successMessage = 'Full log copied to clipboard';
        break;
      case 'copy_stack':
        textToCopy = log.stackTrace ?? '';
        successMessage = 'Stack trace copied to clipboard';
        break;
    }

    if (textToCopy.isNotEmpty) {
      Clipboard.setData(ClipboardData(text: textToCopy));
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    }
  }

  Map<String, int> _getFilteredLogStats() {
    final filteredLogs = _getFilteredLogs();
    final stats = <String, int>{};
    for (final log in filteredLogs) {
      stats[log.level] = (stats[log.level] ?? 0) + 1;
    }
    return stats;
  }

  String _getFilterButtonLabel() {
    if (_selectedClasses.isEmpty) return 'All Classes';
    if (_selectedClasses.length == 1) return _selectedClasses.first;
    return '${_selectedClasses.length} Classes Selected';
  }

  Widget _buildClassFilterSheet() {
    final uniqueClasses = _getUniqueClasses();
    return StatefulBuilder(
      builder: (context, setSheetState) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: ListView(
            shrinkWrap: true,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Filter by Classes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedClasses.clear());
                      setSheetState(() {});
                      Navigator.pop(context);
                    },
                    child: const Text('Clear All'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: uniqueClasses
                    .map(
                      (className) => FilterChip(
                        selected: _selectedClasses.contains(className),
                        label: Text(className),
                        onSelected: (selected) {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            if (selected) {
                              _selectedClasses.add(className);
                            } else {
                              _selectedClasses.remove(className);
                            }
                          });
                          setSheetState(() {});
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Apply Filters'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredLogs = _getFilteredLogs();

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Column(
        children: [
          // Search bar and controls
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 0, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search logs...',
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => _searchController.clear(),
                            )
                          : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ),
                // Clear logs
                _buildClearLogsButton(context),
                // Controls
              ],
            ),
          ),

          // Level filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ..._getAvailableLevels().map(
                    (level) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: _selectedLevels.contains(level),
                        label: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '(${_getFilteredLogStats()[level] ?? 0})',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(level),
                          ],
                        ),
                        onSelected: (selected) {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            if (selected) {
                              _selectedLevels.add(level);
                            } else {
                              _selectedLevels.remove(level);
                            }
                          });
                        },
                        selectedColor: _getLevelColor(level),
                        checkmarkColor: Colors.white,
                      ),
                    ),
                  ),
                  // Clear filters
                  if (_selectedLevels.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: IconButton(
                        icon: const Icon(Icons.clear_all),
                        onPressed: () {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _selectedLevels.clear();
                          });
                        },
                        tooltip: 'Clear level filters',
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Class filter and export
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      FocusScope.of(context).unfocus();
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => _buildClassFilterSheet(),
                      );
                    },
                    icon: const Icon(Icons.filter_list),
                    label: Text(_getFilterButtonLabel()),
                  ),
                ),

                _buildSortLogsToggle(context),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.content_copy),
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    _exportLogs();
                  },
                  tooltip: 'Copy all logs',
                ),
              ],
            ),
          ),

          // Logs list
          Expanded(
            child: filteredLogs.isEmpty
                ? Center(
                    child: Text(
                      _searchQuery.isEmpty
                          ? 'No logs available'
                          : 'No logs matching "${_searchController.text}"',
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    itemCount: filteredLogs.length,
                    itemBuilder: (context, index) {
                      final log = filteredLogs[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        child: ExpansionTile(
                          onExpansionChanged: (expanded) {
                            FocusScope.of(context).unfocus();
                          },
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _getLevelColor(log.level),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _getLevelIcon(log.level),
                              color: Colors.white,
                              size: 18,
                            ),
                          ),
                          title: Text(
                            log.message,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(
                                log.timestamp.toString().substring(0, 19),
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                              if (widget.showFilePaths)
                                Text(
                                  log.filePath,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontFamily: 'monospace',
                                    color: Colors.blue,
                                  ),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) => _handleLogAction(value, log),
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'copy_message',
                                child: Row(
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
                                  children: [
                                    Icon(Icons.content_copy, size: 16),
                                    SizedBox(width: 8),
                                    Text('Copy Full Log'),
                                  ],
                                ),
                              ),
                              if (log.stackTrace != null)
                                const PopupMenuItem(
                                  value: 'copy_stack',
                                  child: Row(
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
                                  // Full message
                                  const Text(
                                    'Message:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  SelectableText(
                                    log.message,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                  const SizedBox(height: 12),

                                  // File info
                                  if (widget.showFilePaths) ...[
                                    const Text(
                                      'Source:',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    SelectableText(
                                      log.filePath,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                  ],

                                  // Stack trace if available
                                  if (log.stackTrace != null) ...[
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
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: Colors.grey[300]!,
                                        ),
                                      ),
                                      child: SelectableText(
                                        log.stackTrace!,
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 11,
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
    );
  }

  Padding _buildSortLogsToggle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        children: [
          // Sort toggle
          IconButton(
            icon: Icon(
              _sortNewestFirst ? Icons.arrow_downward : Icons.arrow_upward,
              color: Colors.deepPurple,
            ),
            onPressed: () {
              FocusScope.of(context).unfocus();
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
            tooltip: _sortNewestFirst
                ? 'Newest logs first'
                : 'Oldest logs first',
          ),
        ],
      ),
    );
  }

  IconButton _buildClearLogsButton(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.delete_outline),
      onPressed: () {
        FocusScope.of(context).unfocus();
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Clear Logs'),
            content: const Text('Are you sure you want to clear all logs?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('CANCEL'),
              ),
              TextButton(
                onPressed: () {
                  LoggingUsingLogger.clearLogs();
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
    );
  }
}
