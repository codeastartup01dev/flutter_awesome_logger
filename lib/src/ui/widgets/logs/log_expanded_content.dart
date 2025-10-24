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
          return _buildApiRequestContent(context);
        case 'response':
          return _buildApiResponseContent(context);
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

  /// Build API request content with body first, then headers
  Widget _buildApiRequestContent(BuildContext context) {
    final body = log.apiLogEntry!.formattedRequestBody;
    final headers = log.apiLogEntry!.formattedRequestHeaders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show body first if it exists
        if (body.isNotEmpty)
          ContentSection(
            title: 'Request Body',
            content: body,
          ),
        // Add spacing between sections
        if (body.isNotEmpty && headers.isNotEmpty) const SizedBox(height: 16),
        // Show headers as additional info
        if (headers.isNotEmpty)
          ContentSection(
            title: 'Request Info',
            content: headers,
            isSecondary: true,
          ),
      ],
    );
  }

  /// Build API response content with body first, then headers
  Widget _buildApiResponseContent(BuildContext context) {
    final body = log.apiLogEntry!.formattedResponseBody;
    final headers = log.apiLogEntry!.formattedResponseHeaders;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show body first if it exists
        if (body.isNotEmpty)
          ContentSection(
            title: 'Response Body',
            content: body,
          ),
        // Add spacing between sections
        if (body.isNotEmpty && headers.isNotEmpty) const SizedBox(height: 16),
        // Show headers and metadata as additional info (initially collapsed)
        if (headers.isNotEmpty)
          ContentSection(
            title: 'Response Info',
            content: headers,
            isSecondary: true,
            initiallyCollapsed: true,
          ),
      ],
    );
  }
}

/// Widget for displaying content sections with copy functionality
class ContentSection extends StatefulWidget {
  final String title;
  final String content;
  final bool isSecondary;
  final bool initiallyCollapsed;

  const ContentSection({
    super.key,
    required this.title,
    required this.content,
    this.isSecondary = false,
    this.initiallyCollapsed = false,
  });

  @override
  State<ContentSection> createState() => _ContentSectionState();
}

class _ContentSectionState extends State<ContentSection> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = !widget.initiallyCollapsed;
  }

  @override
  Widget build(BuildContext context) {
    const maxLength = 500; // Maximum characters to show initially
    final shouldTruncate = widget.content.length > maxLength;
    final displayContent = shouldTruncate
        ? '${widget.content.substring(0, maxLength)}...'
        : widget.content;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: widget.isSecondary
              ? () => setState(() => _isExpanded = !_isExpanded)
              : null,
          behavior: HitTestBehavior.translucent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  widget.title,
                  style: TextStyle(
                    fontWeight:
                        widget.isSecondary ? FontWeight.w500 : FontWeight.bold,
                    fontSize: widget.isSecondary ? 11 : 12,
                    color:
                        widget.isSecondary ? Colors.grey[700] : Colors.black87,
                  ),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Expand/collapse button for secondary sections
                  if (widget.isSecondary)
                    IconButton(
                      onPressed: () =>
                          setState(() => _isExpanded = !_isExpanded),
                      icon: Icon(
                        _isExpanded ? Icons.expand_less : Icons.expand_more,
                        size: 14,
                      ),
                      tooltip: _isExpanded ? 'Collapse' : 'Expand',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  IconButton(
                    onPressed: () =>
                        CopyHandler.copyToClipboard(context, widget.content),
                    icon: Icon(Icons.copy, size: widget.isSecondary ? 14 : 16),
                    tooltip: 'Copy content',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  if (shouldTruncate && _isExpanded)
                    TextButton.icon(
                      onPressed: () => _showFullContent(
                          context, widget.title, widget.content),
                      icon: Icon(Icons.expand_more,
                          size: widget.isSecondary ? 14 : 16),
                      label: Text('More',
                          style: TextStyle(
                              fontSize: widget.isSecondary ? 10 : 11)),
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
        // Only show content when expanded
        if (_isExpanded) ...[
          const SizedBox(height: 4),
          GestureDetector(
            onTap: shouldTruncate
                ? () => _showFullContent(context, widget.title, widget.content)
                : null,
            behavior: HitTestBehavior.translucent,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.all(widget.isSecondary ? 10 : 12),
              decoration: BoxDecoration(
                color: widget.isSecondary ? Colors.grey[50] : Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Text(
                displayContent,
                style: TextStyle(
                  fontSize: widget.isSecondary ? 10 : 11,
                  fontFamily: 'monospace',
                  height: 1.4,
                  color: shouldTruncate
                      ? Colors.blue[700]
                      : (widget.isSecondary
                          ? Colors.grey[800]
                          : Colors.black87),
                ),
              ),
            ),
          ),
        ],
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
