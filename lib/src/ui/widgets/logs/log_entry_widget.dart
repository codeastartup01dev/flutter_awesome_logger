import 'package:flutter/material.dart';

import '../../../core/unified_log_entry.dart';
import '../../../core/unified_log_types.dart';
import '../../services/log_data_service.dart';
import '../../utils/copy_handler.dart';
import '../filters/filter_chips.dart';
import 'log_expanded_content.dart';

/// Widget for displaying a single log entry
class LogEntryWidget extends StatefulWidget {
  final UnifiedLogEntry log;
  final bool showFilePaths;
  final String? selectedExpandedView;
  final ValueChanged<String?> onExpandedViewChanged;

  const LogEntryWidget({
    super.key,
    required this.log,
    this.showFilePaths = true,
    this.selectedExpandedView,
    required this.onExpandedViewChanged,
  });

  @override
  State<LogEntryWidget> createState() => _LogEntryWidgetState();
}

class _LogEntryWidgetState extends State<LogEntryWidget> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: widget.log.type.color.withOpacity(0.5),
          width: 2,
        ),
      ),
      child: ExpansionTile(
        onExpansionChanged: (expanded) {
          FocusScope.of(context).unfocus();
        },
        leading: _buildLogTypeIndicator(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                widget.log.message,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.log.subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            if (widget.log.duration != null)
              Text(
                'Duration: ${widget.log.duration}ms',
                style: const TextStyle(
                  fontSize: 10,
                  color: Colors.blue,
                ),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => CopyHandler.handleCopyAction(
            context,
            value,
            widget.log,
          ),
          itemBuilder: (context) => CopyHandler.getCopyMenuItems(widget.log),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                top: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Log type and timestamp
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors
                            .white, // Semi-transparent black for subtle background
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: widget.log.type.color,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        widget.log.type.displayName,
                        style: TextStyle(
                          color: widget.log.type.color,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      widget.log.timestamp.toString().substring(0, 19),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Detailed content
                const Text(
                  'Details:',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: SelectableText(
                    widget.log.detailedDescription,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      height: 1.4,
                    ),
                  ),
                ),

                // API-specific view chips and content
                if (widget.log.source == LogSource.api) ...[
                  const SizedBox(height: 12),
                  LogExpandedContent(
                    log: widget.log,
                    selectedView: widget.selectedExpandedView,
                    onViewChanged: widget.onExpandedViewChanged,
                  ),
                ],

                // Source and/or File path for general logs
                if (widget.showFilePaths &&
                    (widget.log.filePath != null ||
                        widget.log.sourceName != null)) ...[
                  const SizedBox(height: 12),
                  _buildSourceInfoSection(),
                ],

                // Stack trace for error logs
                if (widget.log.stackTrace != null) ...[
                  const SizedBox(height: 12),
                  const Text(
                    'Stack Trace:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: Colors.grey[300]!,
                      ),
                    ),
                    child: SelectableText(
                      widget.log.stackTrace!,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build source info section showing both source name and file path when available
  Widget _buildSourceInfoSection() {
    final log = widget.log;
    final hasSource = LogDataService.hasExplicitSource(log);
    final hasPath = LogDataService.hasFilePath(log);
    final filePath = log.filePath;
    final sourceName = log.sourceName;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Show explicit source name (passed via source: parameter in logger)
        if (hasSource) ...[
          Row(
            children: [
              Icon(Icons.class_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              const Text(
                'Source:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            sourceName!,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.purple,
            ),
          ),
          if (hasPath) const SizedBox(height: 8),
        ],
        // Show file path for terminal navigation (always show if available)
        if (hasPath) ...[
          Row(
            children: [
              Icon(Icons.folder_outlined, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              const Text(
                'File:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          SelectableText(
            filePath!,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              color: Colors.blue,
            ),
          ),
        ],
        // Show "unknown" in grey if no source and no valid file path
        if (!hasSource && !hasPath && filePath == 'unknown') ...[
          Row(
            children: [
              Icon(Icons.help_outline, size: 14, color: Colors.grey[400]),
              const SizedBox(width: 4),
              Text(
                'Source: unknown (release build)',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[400],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// Build the log type indicator
  Widget _buildLogTypeIndicator() {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: widget.log.type.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Show icon for errors, otherwise show text label
          if (widget.log.type.isError)
            Icon(
              widget.log.type.icon,
              color: Colors.white,
              size: 20,
            )
          else
            _buildLogTypeLabel(),
          if (widget.log.statusCode != null)
            Text(
              '${widget.log.statusCode}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            )
          else if (widget.log.source == LogSource.api &&
              widget.log.statusCode == null)
            const Text(
              '...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
              ),
            ),
        ],
      ),
    );
  }

  /// Build the log type label
  Widget _buildLogTypeLabel() {
    return FittedBox(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 6,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: widget.log.type.color,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          FilterLabels.getLogTypeLabel(widget.log),
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
