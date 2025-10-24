import 'dart:convert';

import 'package:flutter/material.dart';

/// Custom JSON viewer that mimics Chrome DevTools style
///
/// Features:
/// - Chrome DevTools-like expand/collapse arrows
/// - Individual node control (each button works independently)
/// - Color-coded values (strings, numbers, booleans, null)
/// - Proper indentation and hierarchy
/// - Collapse indicators with item counts
/// - Smart default states (root expanded, nested collapsed)
///
/// Usage:
/// ```dart
/// // From JSON string
/// CustomJsonViewer.fromString('{"key": "value"}')
///
/// // From parsed data
/// CustomJsonViewer(data: jsonData)
/// ```
class CustomJsonViewer extends StatefulWidget {
  final dynamic data;
  final int indentLevel;

  const CustomJsonViewer({
    super.key,
    required this.data,
    this.indentLevel = 0,
  });

  /// Create JSON viewer from JSON string
  factory CustomJsonViewer.fromString(String jsonString) {
    try {
      final data = jsonDecode(jsonString);
      return CustomJsonViewer(data: data);
    } catch (e) {
      return CustomJsonViewer(data: {'error': 'Invalid JSON: $e'});
    }
  }

  /// Check if a string is valid JSON
  static bool isValidJson(String jsonString) {
    try {
      jsonDecode(jsonString);
      return true;
    } catch (e) {
      return false;
    }
  }

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
