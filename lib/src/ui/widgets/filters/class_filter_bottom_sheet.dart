import 'package:flutter/material.dart';

import '../../../core/unified_log_entry.dart';
import '../../managers/filter_manager.dart';
import '../../services/log_data_service.dart';

/// Enum for class filter mode
enum ClassFilterMode {
  all, // Shows both sources and file paths combined
  source, // Only explicit source parameter logs
  filePath, // Only file path logs
}

/// Bottom sheet for filtering logs by class names
class ClassFilterBottomSheet extends StatefulWidget {
  /// The filter manager instance
  final FilterManager filterManager;

  /// All available logs to extract class names from
  final List<UnifiedLogEntry> allLogs;

  const ClassFilterBottomSheet({
    super.key,
    required this.filterManager,
    required this.allLogs,
  });

  /// Show the class filter bottom sheet
  static void show({
    required BuildContext context,
    required FilterManager filterManager,
    required List<UnifiedLogEntry> allLogs,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => ClassFilterBottomSheet(
        filterManager: filterManager,
        allLogs: allLogs,
      ),
    );
  }

  @override
  State<ClassFilterBottomSheet> createState() => _ClassFilterBottomSheetState();
}

class _ClassFilterBottomSheetState extends State<ClassFilterBottomSheet> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isCompactView = true; // false = list view, true = compact chip view
  ClassFilterMode _filterMode = ClassFilterMode.all; // default to all

  @override
  void initState() {
    super.initState();
    widget.filterManager.addListener(_onFilterChanged);
  }

  @override
  void dispose() {
    widget.filterManager.removeListener(_onFilterChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onFilterChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Check if any items are selected across all filter modes
  bool get _hasAnySelectedItems =>
      widget.filterManager.selectedClasses.isNotEmpty ||
      widget.filterManager.selectedSourceNames.isNotEmpty ||
      widget.filterManager.selectedFilePaths.isNotEmpty;

  /// Clear all filters from all modes
  void _clearAllFilters() {
    widget.filterManager.clearClassFilters();
    widget.filterManager.clearSourceNameFilters();
    widget.filterManager.clearFilePathFilters();
  }

  /// Get count of selected items for a specific filter mode
  int _getSelectedCountForMode(ClassFilterMode mode) {
    switch (mode) {
      case ClassFilterMode.all:
        return widget.filterManager.selectedClasses.length;
      case ClassFilterMode.source:
        return widget.filterManager.selectedSourceNames.length;
      case ClassFilterMode.filePath:
        return widget.filterManager.selectedFilePaths.length;
    }
  }

  /// Build a filter mode chip with optional badge
  Widget _buildFilterModeChip({
    required BuildContext context,
    required ClassFilterMode mode,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final selectedCount = _getSelectedCountForMode(mode);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? Theme.of(context).colorScheme.primaryContainer
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              // Badge showing selected count
              if (selectedCount > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 16,
                    minHeight: 16,
                  ),
                  child: Text(
                    '$selectedCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get available data based on filter mode
    final Map<String, int> filterData;
    final Set<String> selectedItems;
    final String itemLabel;
    final String searchHint;

    switch (_filterMode) {
      case ClassFilterMode.all:
        filterData = LogDataService.getAvailableClasses(
          widget.allLogs,
          selectedSources: widget.filterManager.selectedSources,
        );
        selectedItems = widget.filterManager.selectedClasses;
        itemLabel = 'item';
        searchHint = 'Search all...';
        break;
      case ClassFilterMode.source:
        filterData = LogDataService.getAvailableSources(
          widget.allLogs,
          selectedSources: widget.filterManager.selectedSources,
        );
        selectedItems = widget.filterManager.selectedSourceNames;
        itemLabel = 'source';
        searchHint = 'Search sources...';
        break;
      case ClassFilterMode.filePath:
        filterData = LogDataService.getAvailableFilePaths(
          widget.allLogs,
          selectedSources: widget.filterManager.selectedSources,
        );
        selectedItems = widget.filterManager.selectedFilePaths;
        itemLabel = 'file path';
        searchHint = 'Search file paths...';
        break;
    }

    // Filter based on search query
    final filteredItems = filterData.entries.where((entry) {
      if (_searchQuery.isEmpty) return true;
      return entry.key.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    // Sort by count (descending) then by name
    filteredItems.sort((a, b) {
      final countCompare = b.value.compareTo(a.value);
      if (countCompare != 0) return countCompare;
      return a.key.compareTo(b.key);
    });

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.3,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Icon(
                    _filterMode == ClassFilterMode.all
                        ? Icons.filter_list
                        : _filterMode == ClassFilterMode.source
                            ? Icons.class_outlined
                            : Icons.folder_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _filterMode == ClassFilterMode.all
                              ? 'Filter Logs'
                              : _filterMode == ClassFilterMode.source
                                  ? 'Filter by Source'
                                  : 'Filter by File Path',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Flexible(child: _buildClearAllFiltersButton(context)),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                    tooltip: 'Close',
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Filter mode toggle (3 options)
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    // All option
                    _buildFilterModeChip(
                      context: context,
                      mode: ClassFilterMode.all,
                      icon: Icons.filter_list,
                      label: 'All',
                      isSelected: _filterMode == ClassFilterMode.all,
                      onTap: () {
                        setState(() {
                          _filterMode = ClassFilterMode.all;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
                    // Source option
                    _buildFilterModeChip(
                      context: context,
                      mode: ClassFilterMode.source,
                      icon: Icons.class_outlined,
                      label: 'Source',
                      isSelected: _filterMode == ClassFilterMode.source,
                      onTap: () {
                        setState(() {
                          _filterMode = ClassFilterMode.source;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
                    // File Path option
                    _buildFilterModeChip(
                      context: context,
                      mode: ClassFilterMode.filePath,
                      icon: Icons.folder_outlined,
                      label: 'Path',
                      isSelected: _filterMode == ClassFilterMode.filePath,
                      onTap: () {
                        setState(() {
                          _filterMode = ClassFilterMode.filePath;
                          _searchQuery = '';
                          _searchController.clear();
                        });
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // selected items display (always visible)

              _buildAllSelectedItemsChips(context),

              // Search field and view toggle button
              Row(
                children: [
                  // Search field
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: searchHint,
                        prefixIcon: const Icon(Icons.search, size: 20),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 20),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchQuery = '';
                                  });
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.5),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  // View toggle button
                  IconButton(
                    icon: Icon(
                      _isCompactView ? Icons.list : Icons.grid_view,
                      size: 20,
                    ),
                    tooltip: _isCompactView
                        ? 'Switch to list view'
                        : 'Switch to compact view',
                    onPressed: () {
                      setState(() {
                        _isCompactView = !_isCompactView;
                      });
                    },
                  ),
                ],
              ),

              // Item count info
              Padding(
                padding: const EdgeInsets.only(bottom: 8, top: 8),
                child: Text(
                  '${filteredItems.length} ${filteredItems.length == 1 ? itemLabel : '${itemLabel}s'} found',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),

              // Item list
              Expanded(
                child: filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty
                                  ? Icons.search_off
                                  : _filterMode == ClassFilterMode.source
                                      ? Icons.class_outlined
                                      : Icons.folder_outlined,
                              size: 48,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchQuery.isNotEmpty
                                  ? 'No ${itemLabel}s matching "$_searchQuery"'
                                  : 'No ${itemLabel}s found in logs',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (_searchQuery.isEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                _filterMode == ClassFilterMode.all
                                    ? 'Shows all log sources (both explicit sources and file paths combined).\nSelect Logger Logs to see available items.'
                                    : _filterMode == ClassFilterMode.source
                                        ? 'Source filtering shows logs where the source parameter was explicitly passed.\nExample: logger.d("msg", source: "MyClass")'
                                        : 'File path filtering shows logs from specific files in your app (auto-detected in debug builds).',
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ],
                        ),
                      )
                    : _isCompactView
                        ? SingleChildScrollView(
                            controller: scrollController,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: filteredItems.map((entry) {
                                  final itemName = entry.key;
                                  final count = entry.value;
                                  final isSelected =
                                      selectedItems.contains(itemName);

                                  // Display name - for file paths, show just the filename
                                  final displayName =
                                      _filterMode == ClassFilterMode.filePath
                                          ? itemName
                                              .split('/')
                                              .last
                                              .split(':')
                                              .first
                                          : itemName;

                                  return _ClassChipTile(
                                    className: displayName,
                                    count: count,
                                    isSelected: isSelected,
                                    onTap: () {
                                      switch (_filterMode) {
                                        case ClassFilterMode.all:
                                          widget.filterManager
                                              .toggleClass(itemName);
                                          break;
                                        case ClassFilterMode.source:
                                          widget.filterManager
                                              .toggleSourceName(itemName);
                                          break;
                                        case ClassFilterMode.filePath:
                                          widget.filterManager
                                              .toggleFilePath(itemName);
                                          break;
                                      }
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: filteredItems.length,
                            itemBuilder: (context, index) {
                              final entry = filteredItems[index];
                              final itemName = entry.key;
                              final count = entry.value;
                              final isSelected =
                                  selectedItems.contains(itemName);

                              // Display name - for file paths in list view, show full path
                              final displayName =
                                  _filterMode == ClassFilterMode.filePath
                                      ? itemName
                                      : itemName;

                              return _ClassFilterTile(
                                className: displayName,
                                count: count,
                                isSelected: isSelected,
                                onTap: () {
                                  switch (_filterMode) {
                                    case ClassFilterMode.all:
                                      widget.filterManager
                                          .toggleClass(itemName);
                                      break;
                                    case ClassFilterMode.source:
                                      widget.filterManager
                                          .toggleSourceName(itemName);
                                      break;
                                    case ClassFilterMode.filePath:
                                      widget.filterManager
                                          .toggleFilePath(itemName);
                                      break;
                                  }
                                },
                              );
                            },
                          ),
              ),
            ],
          ),
        );
      },
    );
  }

  Container _buildClearAllFiltersButton(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      child: OutlinedButton.icon(
        onPressed: !_hasAnySelectedItems
            ? null // Disabled when no items selected
            : _clearAllFilters,
        icon: const Icon(Icons.clear_all),
        label: const Text('Clear'),
        style: OutlinedButton.styleFrom(
          foregroundColor: _hasAnySelectedItems
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          side: BorderSide(
            color: _hasAnySelectedItems
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: _hasAnySelectedItems ? 2 : 1,
          ),
          backgroundColor: _hasAnySelectedItems
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1)
              : null,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        ),
      ),
    );
  }

  /// Build selected items chips from all filter modes
  Widget _buildAllSelectedItemsChips(BuildContext context) {
    // Collect all selected items from all modes
    final allSelectedItems = <MapEntry<String, String>>[];

    // Add class items
    for (final item in widget.filterManager.selectedClasses) {
      final count = LogDataService.getClassCount(
        widget.allLogs,
        item,
        selectedSources: widget.filterManager.selectedSources,
      );
      allSelectedItems.add(MapEntry(item, 'class:$item:$count'));
    }

    // Add source items
    for (final item in widget.filterManager.selectedSourceNames) {
      final count = LogDataService.getSourceCount(
        widget.allLogs,
        item,
        selectedSources: widget.filterManager.selectedSources,
      );
      allSelectedItems.add(MapEntry(item, 'source:$item:$count'));
    }

    // Add file path items
    for (final item in widget.filterManager.selectedFilePaths) {
      final count = LogDataService.getFilePathCount(
        widget.allLogs,
        item,
        selectedSources: widget.filterManager.selectedSources,
      );
      final displayName = item.split('/').last.split(':').first;
      allSelectedItems.add(MapEntry(displayName, 'path:$item:$count'));
    }

    if (allSelectedItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              '${allSelectedItems.length} selected',
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: _clearAllFilters,
              child: const Text('Clear All'),
            ),
          ],
        ),
        Container(
          height: 36,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: allSelectedItems.length,
            itemBuilder: (context, index) {
              final entry = allSelectedItems[index];
              final displayName = entry.key;
              final data = entry.value.split(':');
              final type = data[0];
              final originalName = data[1];
              final count = int.parse(data[2]);

              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Chip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '$count',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    switch (type) {
                      case 'class':
                        widget.filterManager.toggleClass(originalName);
                        break;
                      case 'source':
                        widget.filterManager.toggleSourceName(originalName);
                        break;
                      case 'path':
                        widget.filterManager.toggleFilePath(originalName);
                        break;
                    }
                  },
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withOpacity(0.3),
                  side: BorderSide(
                    color:
                        Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    width: 1,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  labelPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  padding: EdgeInsets.zero,
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Individual tile for a class in the filter list
class _ClassFilterTile extends StatelessWidget {
  final String className;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClassFilterTile({
    required this.className,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.only(bottom: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                )
              : null,
        ),
        child: Row(
          children: [
            // Checkbox indicator
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.outline,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 16,
                      color: Colors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),

            // Class name
            Expanded(
              child: Text(
                className,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),

            // Count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact chip tile for a class in the filter grid view
class _ClassChipTile extends StatelessWidget {
  final String className;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _ClassChipTile({
    required this.className,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3)
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withOpacity(0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
                : Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Class name
            Text(
              className,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),

            const SizedBox(width: 6),

            // Count badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.2)
                    : Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
