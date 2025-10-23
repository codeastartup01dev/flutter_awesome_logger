import 'package:flutter/material.dart';

/// Reusable search bar widget for logger pages
class LoggerSearchBar extends StatelessWidget {
  /// Controller for the search text field
  final TextEditingController controller;

  /// Hint text to display in the search field
  final String hintText;

  /// Current search query
  final String searchQuery;

  /// Callback when clear button is pressed
  final VoidCallback? onClear;

  /// Additional actions to show on the right side
  final List<Widget>? actions;

  const LoggerSearchBar({
    super.key,
    required this.controller,
    required this.hintText,
    required this.searchQuery,
    this.onClear,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: hintText,
                filled: true,
                fillColor: Colors.grey[100],
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: onClear ?? () => controller.clear(),
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
          if (actions != null) ...[
            const SizedBox(width: 8),
            ...actions!,
          ],
        ],
      ),
    );
  }
}
