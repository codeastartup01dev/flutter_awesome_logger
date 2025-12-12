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
    this.newestFirstLabel = 'Newest logs first',
    this.oldestFirstLabel = 'Oldest logs first',
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: () {
        FocusScope.of(context).unfocus();
        // Capture the current state before toggling for the SnackBar message
        final wasNewestFirst = sortNewestFirst;
        onToggle();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              wasNewestFirst
                  ? "Showing $oldestFirstLabel"
                  : "Showing $newestFirstLabel",
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
            ? newestFirstLabel ?? 'Newest Logs First'
            : oldestFirstLabel ?? 'Oldest Logs First',
        style: const TextStyle(fontSize: 12),
      ),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: const Color(0x1A673AB7), // deepPurple with 10% opacity
        foregroundColor: Colors.deepPurple,
        elevation: 0,
      ),
    );
  }
}
