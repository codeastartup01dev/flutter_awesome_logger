import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/unified_log_entry.dart';
import '../../core/unified_log_types.dart';
import '../widgets/common/logger_export_dialog.dart';

/// Utility class for handling copy operations and clipboard functionality
class CopyHandler {
  /// Handle copy actions for logs
  static void handleCopyAction(
    BuildContext context,
    String action,
    UnifiedLogEntry log,
  ) {
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
      copyToClipboard(context, textToCopy, successMessage);
    }
  }

  /// Copy content to clipboard and show feedback
  static Future<void> copyToClipboard(
    BuildContext context,
    String content, [
    String? successMessage,
  ]) async {
    await Clipboard.setData(ClipboardData(text: content));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage ?? 'Content copied to clipboard'),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Export logs to clipboard using the export dialog utility
  static void exportLogsToClipboard(
    BuildContext context,
    String content, {
    String? successMessage,
    String? dialogTitle,
  }) {
    LoggerExportUtils.exportToClipboard(
      context: context,
      content: content,
      successMessage: successMessage ?? 'Logs copied to clipboard',
      dialogTitle: dialogTitle ?? 'Exported Logs',
    );
  }

  /// Get copy menu items for a log entry
  static List<PopupMenuEntry<String>> getCopyMenuItems(UnifiedLogEntry log) {
    final items = <PopupMenuEntry<String>>[
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
    ];

    // Add API-specific menu items
    if (log.source == LogSource.api) {
      items.addAll([
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
      ]);
    }

    // Add stack trace menu item if available
    if (log.stackTrace != null) {
      items.add(
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
      );
    }

    // Add BLoC-specific menu items
    if (log.source == LogSource.bloc) {
      items.addAll([
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
      ]);

      if (log.blocLogEntry?.event != null) {
        items.add(
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
        );
      }

      if (log.blocLogEntry?.nextState != null) {
        items.add(
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
        );
      }
    }

    return items;
  }
}
