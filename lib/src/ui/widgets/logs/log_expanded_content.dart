import 'dart:convert';

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
  String _selectedView = 'raw';

  /// Check if content is valid JSON
  bool _isJson(String content) {
    try {
      jsonDecode(content);
      return true;
    } catch (e) {
      return false;
    }
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

/// Custom JSON viewer that mimics Chrome DevTools style
class CustomJsonViewer extends StatefulWidget {
  final dynamic data;
  final int indentLevel;

  const CustomJsonViewer({
    super.key,
    required this.data,
    this.indentLevel = 0,
  });

  @override
  State<CustomJsonViewer> createState() => _CustomJsonViewerState();
}

class _CustomJsonViewerState extends State<CustomJsonViewer> {
  final Map<String, bool> _expandedStates = {};
  int _nodeCounter = 0;

  @override
  Widget build(BuildContext context) {
    _nodeCounter = 0; // Reset counter for each build
    return _buildJsonNode(widget.data, '', widget.indentLevel, '');
  }

  Widget _buildJsonNode(
      dynamic data, String key, int indentLevel, String path) {
    if (data is Map<String, dynamic>) {
      return _buildMapNode(data, key, indentLevel, path);
    } else if (data is List) {
      return _buildListNode(data, key, indentLevel, path);
    } else {
      return _buildPrimitiveNode(data, key, indentLevel);
    }
  }

  Widget _buildMapNode(Map<String, dynamic> map, String parentKey,
      int indentLevel, String path) {
    final currentPath = path.isEmpty ? parentKey : '$path.$parentKey';
    final nodeKey = 'map_${currentPath}_${_nodeCounter++}';
    // Root level (indentLevel 0) starts expanded, others start collapsed
    final defaultExpanded = indentLevel == 0;
    final isExpanded = _expandedStates[nodeKey] ?? defaultExpanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Object header with expand/collapse
        GestureDetector(
          onTap: () => setState(() => _expandedStates[nodeKey] = !isExpanded),
          child: Row(
            children: [
              SizedBox(width: indentLevel * 16.0),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              if (parentKey.isNotEmpty) ...[
                Text(
                  '"$parentKey": ',
                  style: TextStyle(
                    color: Colors.purple[700],
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              Text(
                isExpanded ? '{' : '{ ... }',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              if (!isExpanded) ...[
                const SizedBox(width: 4),
                Text(
                  '// ${map.length} ${map.length == 1 ? 'item' : 'items'}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Object content
        if (isExpanded) ...[
          ...map.entries.map((entry) => Padding(
                padding: const EdgeInsets.only(left: 16),
                child: _buildJsonNode(
                    entry.value, entry.key, indentLevel + 1, currentPath),
              )),
          Row(
            children: [
              SizedBox(width: indentLevel * 16.0),
              const SizedBox(width: 20), // Space for arrow
              const Text(
                '}',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildListNode(
      List list, String parentKey, int indentLevel, String path) {
    final currentPath = path.isEmpty ? parentKey : '$path.$parentKey';
    final nodeKey = 'list_${currentPath}_${_nodeCounter++}';
    // Root level (indentLevel 0) starts expanded, others start collapsed
    final defaultExpanded = indentLevel == 0;
    final isExpanded = _expandedStates[nodeKey] ?? defaultExpanded;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Array header with expand/collapse
        GestureDetector(
          onTap: () => setState(() => _expandedStates[nodeKey] = !isExpanded),
          child: Row(
            children: [
              SizedBox(width: indentLevel * 16.0),
              Icon(
                isExpanded
                    ? Icons.keyboard_arrow_down
                    : Icons.keyboard_arrow_right,
                size: 16,
                color: Colors.grey[600],
              ),
              const SizedBox(width: 4),
              if (parentKey.isNotEmpty) ...[
                Text(
                  '"$parentKey": ',
                  style: TextStyle(
                    color: Colors.purple[700],
                    fontSize: 12,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
              Text(
                isExpanded ? '[' : '[ ... ]',
                style: const TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
              if (!isExpanded) ...[
                const SizedBox(width: 4),
                Text(
                  '// ${list.length} ${list.length == 1 ? 'item' : 'items'}',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        // Array content
        if (isExpanded) ...[
          ...list.asMap().entries.map((entry) => Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(width: indentLevel * 16.0),
                    const SizedBox(width: 20), // Space for arrow
                    Text(
                      '${entry.key}: ',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                    Expanded(
                      child: _buildJsonNode(entry.value, '${entry.key}',
                          indentLevel + 1, currentPath),
                    ),
                  ],
                ),
              )),
          Row(
            children: [
              SizedBox(width: indentLevel * 16.0),
              const SizedBox(width: 20), // Space for arrow
              const Text(
                ']',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildPrimitiveNode(dynamic value, String key, int indentLevel) {
    Color valueColor;
    String displayValue;

    if (value is String) {
      valueColor = Colors.green[700]!;
      displayValue = '"$value"';
    } else if (value is num) {
      valueColor = Colors.blue[700]!;
      displayValue = value.toString();
    } else if (value is bool) {
      valueColor = Colors.purple[700]!;
      displayValue = value.toString();
    } else if (value == null) {
      valueColor = Colors.grey[500]!;
      displayValue = 'null';
    } else {
      valueColor = Colors.black87;
      displayValue = value.toString();
    }

    return Padding(
      padding: EdgeInsets.only(left: indentLevel * 16.0),
      child: Row(
        children: [
          const SizedBox(
              width: 20), // Space for arrow (no arrow for primitives)
          if (key.isNotEmpty) ...[
            Text(
              '"$key": ',
              style: TextStyle(
                color: Colors.purple[700],
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
          Flexible(
            child: Text(
              displayValue,
              style: TextStyle(
                color: valueColor,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
