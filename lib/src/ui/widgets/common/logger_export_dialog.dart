import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Reusable export dialog for logger pages
class LoggerExportDialog extends StatelessWidget {
  /// Title for the dialog
  final String title;

  /// Content to display and export
  final String content;

  const LoggerExportDialog({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: SingleChildScrollView(
          child: SelectableText(
            content,
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
            Clipboard.setData(ClipboardData(text: content));
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Copied to clipboard')),
            );
          },
          child: const Text('Copy'),
        ),
      ],
    );
  }

  /// Show the export dialog
  static void show(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (context) => LoggerExportDialog(
        title: title,
        content: content,
      ),
    );
  }
}

/// Utility class for handling log exports
class LoggerExportUtils {
  /// Export logs to clipboard and show snackbar with optional view action
  static void exportToClipboard({
    required BuildContext context,
    required String content,
    required String successMessage,
    String? dialogTitle,
  }) {
    Clipboard.setData(ClipboardData(text: content));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(successMessage),
        action: dialogTitle != null
            ? SnackBarAction(
                label: 'View',
                onPressed: () => LoggerExportDialog.show(
                  context,
                  dialogTitle,
                  content,
                ),
              )
            : null,
      ),
    );
  }
}
