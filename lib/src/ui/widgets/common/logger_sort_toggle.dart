import 'package:flutter/material.dart';

/// Reusable sort toggle widget for logger pages
class LoggerSortToggle extends StatelessWidget {
  /// Whether to sort newest first (true) or oldest first (false)
  final bool sortNewestFirst;

  /// Callback when sort order is changed
  final VoidCallback onToggle;

  /// Optional custom labels
  final String? newestFirstLabel;
  final String? oldestFirstLabel;

  const LoggerSortToggle({
    super.key,
    required this.sortNewestFirst,
    required this.onToggle,
    this.newestFirstLabel,
    this.oldestFirstLabel,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        FocusScope.of(context).unfocus();
        onToggle();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              sortNewestFirst
                  ? newestFirstLabel ?? 'Showing Newest logs first'
                  : oldestFirstLabel ?? 'Showing Oldest logs first',
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      },
      icon: Icon(
        sortNewestFirst ? Icons.arrow_downward : Icons.arrow_upward,
        size: 16,
      ),
      label: Text(
        sortNewestFirst
            ? newestFirstLabel ?? 'Showing Newest Logs First'
            : oldestFirstLabel ?? 'Showing Oldest Logs First',
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Colors.deepPurple.withValues(alpha: 0.1),
        foregroundColor: Colors.deepPurple,
        elevation: 0,
      ),
    );
  }
}
