import 'package:flutter/material.dart';

import '../../../api_logger/api_log_entry.dart';
import '../../../core/unified_log_entry.dart';
import '../../../core/unified_log_types.dart';
import '../../utils/copy_handler.dart';

/// Widget for displaying expanded content of logs (API/BLoC specific views)
class LogExpandedContent extends StatelessWidget {
  final UnifiedLogEntry log;
  final String? selectedView;
  final ValueChanged<String?> onViewChanged;

  const LogExpandedContent({
    super.key,
    required this.log,
    this.selectedView,
    required this.onViewChanged,
  });

  @override
  Widget build(BuildContext context) {
    if (log.source == LogSource.api && log.apiLogEntry != null) {
      return _buildApiViewSection(context);
    } else if (log.source == LogSource.bloc && log.blocLogEntry != null) {
      return _buildBlocViewSection(context);
    }
    return const SizedBox.shrink();
  }

  /// Build API view section with chips and content
  Widget _buildApiViewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // View selector chips
        Row(
          children: [
            _buildViewChip('Request', 'request'),
            const SizedBox(width: 8),
            if (log.apiLogEntry!.type != ApiLogType.pending)
              _buildViewChip('Response', 'response'),
            if (log.apiLogEntry!.type != ApiLogType.pending)
              const SizedBox(width: 8),
            _buildViewChip('Curl', 'curl'),
          ],
        ),
        const SizedBox(height: 12),
        // Content based on selected view
        if (selectedView != null) _buildExpandedContent(context),
      ],
    );
  }

  /// Build BLoC view section with chips and content
  Widget _buildBlocViewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // View selector chips
        Row(
          children: [
            _buildViewChip('Request', 'request'),
            const SizedBox(width: 8),
            _buildViewChip('Response', 'response'),
            const SizedBox(width: 8),
            _buildViewChip('Command', 'command'),
          ],
        ),
        const SizedBox(height: 12),
        // Content based on selected view
        if (selectedView != null) _buildExpandedContent(context),
      ],
    );
  }

  /// Build view selector chip for expanded content
  Widget _buildViewChip(String label, String viewType) {
    final isSelected = selectedView == viewType;

    // Don't show response chip for pending logs
    if (viewType == 'response' && log.apiLogEntry?.type == ApiLogType.pending) {
      return const SizedBox.shrink();
    }

    return FilterChip(
      selected: isSelected,
      label: Text(label, style: const TextStyle(fontSize: 11)),
      onSelected: (selected) {
        onViewChanged(selected ? viewType : null);
      },
      backgroundColor: isSelected ? Colors.blue[50] : Colors.grey[100],
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  /// Build expanded content based on selected view
  Widget _buildExpandedContent(BuildContext context) {
    if (log.source == LogSource.api && log.apiLogEntry != null) {
      switch (selectedView) {
        case 'request':
          return ContentSection(
            title: 'Request',
            content: log.apiLogEntry!.formattedRequest,
          );
        case 'response':
          return ContentSection(
            title: 'Response',
            content: log.apiLogEntry!.formattedResponse,
          );
        case 'curl':
          return ContentSection(
            title: 'Curl Command',
            content: log.apiLogEntry!.curl,
          );
        default:
          return const SizedBox.shrink();
      }
    } else if (log.source == LogSource.bloc && log.blocLogEntry != null) {
      switch (selectedView) {
        case 'request':
          return ContentSection(
            title: 'Request',
            content: log.blocLogEntry!.formattedRequest,
          );
        case 'response':
          return ContentSection(
            title: 'Response',
            content: log.blocLogEntry!.formattedResponse,
          );
        case 'command':
          return ContentSection(
            title: 'Command',
            content: log.blocLogEntry!.command,
          );
        default:
          return const SizedBox.shrink();
      }
    }
    return const SizedBox.shrink();
  }
}

/// Widget for displaying content sections with copy functionality
class ContentSection extends StatelessWidget {
  final String title;
  final String content;

  const ContentSection({
    super.key,
    required this.title,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
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
                  onPressed: () =>
                      CopyHandler.copyToClipboard(context, content),
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Copy content',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                if (shouldTruncate)
                  TextButton.icon(
                    onPressed: () => _showFullContent(context, title, content),
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
          onTap: shouldTruncate
              ? () => _showFullContent(context, title, content)
              : null,
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
  void _showFullContent(BuildContext context, String title, String content) {
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
                          Navigator.of(context).pop();
                          CopyHandler.copyToClipboard(context, content);
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
}
