import 'dart:convert';

import 'package:flutter/material.dart';

import '../../../api_logger/api_log_entry.dart';
import '../../../core/unified_log_entry.dart';
import '../../../core/unified_log_types.dart';
import '../../utils/copy_handler.dart';
import '../json/json_widgets.dart';

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
    }
    return const SizedBox.shrink();
  }

  /// Build API view section with chips and content
  Widget _buildApiViewSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Full API URL display
        _buildApiUrlSection(),
        const SizedBox(height: 12),
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

  /// Build API URL section
  Widget _buildApiUrlSection() {
    final url = log.url ?? log.apiLogEntry!.url;
    return Builder(
      builder: (context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.blue[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              url,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Colors.black87,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
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

  /// Build appropriate widget for content (JSON or text)
  Widget _buildContentWidget() {
    const maxLength = 500; // Maximum characters to show initially
    final shouldTruncate = widget.content.length > maxLength;

    // Always show as text with truncation, JSON will be handled in bottom sheet

    // Fallback to text display for non-JSON content
    final displayContent = shouldTruncate
        ? '${widget.content.substring(0, maxLength)}...'
        : widget.content;

    return shouldTruncate
        ? RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: widget.content.substring(0, maxLength),
                  style: TextStyle(
                    fontSize: widget.isSecondary ? 10 : 11,
                    fontFamily: 'monospace',
                    height: 1.4,
                    color:
                        widget.isSecondary ? Colors.grey[800] : Colors.black87,
                  ),
                ),
                TextSpan(
                  text: '...click to view more',
                  style: TextStyle(
                    fontSize: widget.isSecondary ? 10 : 11,
                    fontFamily: 'monospace',
                    height: 1.4,
                    color: Colors.blue[700],
                  ),
                ),
              ],
            ),
          )
        : Text(
            displayContent,
            style: TextStyle(
              fontSize: widget.isSecondary ? 10 : 11,
              fontFamily: 'monospace',
              height: 1.4,
              color: widget.isSecondary ? Colors.grey[800] : Colors.black87,
            ),
          );
  }

  @override
  Widget build(BuildContext context) {
    const maxLength = 500; // Maximum characters to show initially
    final shouldTruncate = widget.content.length > maxLength;

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
              child: _buildContentWidget(),
            ),
          ),
        ],
      ],
    );
  }

  /// Show full content in a bottom sheet with view switching options
  void _showFullContent(BuildContext context, String title, String content) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ContentBottomSheet(
        title: title,
        content: content,
      ),
    );
  }
}

/// Bottom sheet widget for displaying content with view switching options
class _ContentBottomSheet extends StatefulWidget {
  final String title;
  final String content;

  const _ContentBottomSheet({
    required this.title,
    required this.content,
  });

  @override
  State<_ContentBottomSheet> createState() => _ContentBottomSheetState();
}

class _ContentBottomSheetState extends State<_ContentBottomSheet> {
  String _selectedView = 'formatted';

  /// Check if content is valid JSON
  bool _isJson(String content) {
    return CustomJsonViewer.isValidJson(content);
  }

  /// Get parsed JSON object if content is valid JSON
  dynamic _parseJson(String content) {
    try {
      return jsonDecode(content);
    } catch (e) {
      return null;
    }
  }

  /// Build custom JSON view widget (Chrome DevTools style)
  Widget _buildJsonView(dynamic jsonData) {
    return CustomJsonViewer(data: jsonData);
  }

  @override
  Widget build(BuildContext context) {
    final isJsonContent = _isJson(widget.content);
    final jsonData = isJsonContent ? _parseJson(widget.content) : null;

    return Container(
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
          // Header with title and actions
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
                    widget.title,
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
                        CopyHandler.copyToClipboard(context, widget.content);
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
          // View selector chips (only show if JSON)
          if (isJsonContent)
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildViewChip('Raw', 'raw'),
                  const SizedBox(width: 8),
                  _buildViewChip('Formatted', 'formatted'),
                ],
              ),
            ),
          // Content area
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: _buildContent(isJsonContent, jsonData),
            ),
          ),
        ],
      ),
    );
  }

  /// Build view selector chip
  Widget _buildViewChip(String label, String viewType) {
    final isSelected = _selectedView == viewType;

    return FilterChip(
      selected: isSelected,
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onSelected: (selected) {
        setState(() {
          _selectedView = selected ? viewType : 'raw';
        });
      },
      backgroundColor: isSelected ? Colors.blue[50] : Colors.grey[100],
      selectedColor: Colors.blue[100],
      checkmarkColor: Colors.blue[700],
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      visualDensity: VisualDensity.compact,
    );
  }

  /// Build content based on selected view
  Widget _buildContent(bool isJsonContent, dynamic jsonData) {
    if (isJsonContent && _selectedView == 'formatted' && jsonData != null) {
      // Show formatted JSON view
      return _buildJsonView(jsonData);
    } else {
      // Show raw text view
      return Text(
        widget.content,
        style: const TextStyle(
          fontSize: 12,
          fontFamily: 'monospace',
          height: 1.4,
        ),
      );
    }
  }
}
