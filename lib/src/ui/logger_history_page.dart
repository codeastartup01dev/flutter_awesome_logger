import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../api_logger/api_logger_service.dart';
import '../core/logging_using_logger.dart';
import 'widgets/api_logs_tab.dart';
import 'widgets/general_logs_tab.dart';

/// Main logger history page with tabbed interface for general and API logs
class LoggerHistoryPage extends StatefulWidget {
  /// Whether to show file paths in the UI
  final bool showFilePaths;

  /// Static flag to track if logger is currently open
  static bool _isLoggerOpen = false;

  /// Check if logger is currently open
  static bool get isLoggerOpen => _isLoggerOpen;

  const LoggerHistoryPage({super.key, this.showFilePaths = true});

  @override
  State<LoggerHistoryPage> createState() => _LoggerHistoryPageState();
}

class _LoggerHistoryPageState extends State<LoggerHistoryPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    LoggerHistoryPage._isLoggerOpen = true;
    _tabController = TabController(length: 2, vsync: this);
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    LoggerHistoryPage._isLoggerOpen = false;
    _refreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final apiLogs = ApiLoggerService.getApiLogs();
    final apiLogCount = apiLogs.length;
    final generalLogCount = LoggingUsingLogger.getLogs().length;

    // Calculate API error count
    final apiErrorCount = apiLogs
        .where(
          (log) =>
              log.type.name.contains('Error') ||
              log.type.name == 'networkError',
        )
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Flutter Awesome Logger',
          style: TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: _exportAllLogs,
            tooltip: 'Export All Logs',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('API Logs'),
                  if (apiLogCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: apiErrorCount > 0 ? Colors.red : Colors.green,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$apiLogCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    // Show error count separately if there are errors
                    if (apiErrorCount > 0) ...[
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '⚠$apiErrorCount',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('General Logs'),
                  if (generalLogCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[600],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$generalLogCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          ApiLogsTab(showFilePaths: widget.showFilePaths),
          GeneralLogsTab(showFilePaths: widget.showFilePaths),
        ],
      ),
    );
  }

  /// Export all logs (both general and API)
  void _exportAllLogs() {
    final generalLogs = LoggingUsingLogger.exportLogs();
    final apiLogs = ApiLoggerService.exportApiLogs();

    final combinedExport = [
      '=== AWESOME FLUTTER LOGGER - COMPLETE EXPORT ===',
      'Generated: ${DateTime.now().toIso8601String()}',
      '',
      '=== GENERAL LOGS ===',
      generalLogs,
      '',
      '=== API LOGS ===',
      apiLogs,
    ].join('\n');

    Clipboard.setData(ClipboardData(text: combinedExport));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('All logs copied to clipboard'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () => _showExportDialog(combinedExport),
        ),
      ),
    );
  }

  /// Show export dialog
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
}
