import 'package:flutter/material.dart';

import '../../../core/unified_log_entry.dart';
import '../../../core/unified_log_types.dart';
import '../../managers/filter_manager.dart';
import '../../services/log_data_service.dart';
import 'filter_chips.dart';

/// Widget for the complete filter section
class FilterSection extends StatelessWidget {
  final FilterManager filterManager;
  final List<UnifiedLogEntry> allLogs;

  const FilterSection({
    super.key,
    required this.filterManager,
    required this.allLogs,
  });

  @override
  Widget build(BuildContext context) {
    final typeCounts = LogDataService.getTypeCounts(
      allLogs,
      selectedSources: filterManager.selectedSources,
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter section header with collapse/expand
          InkWell(
            onTap: filterManager.toggleFilterSectionExpanded,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 0),
              child: Row(
                children: [
                  const Spacer(),
                  // Show active filter count when collapsed
                  if (!filterManager.isFilterSectionExpanded &&
                      filterManager.hasActiveFilters()) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0x1A2196F3), // blue with 10% opacity
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(
                                0x4D2196F3)), // blue with 30% opacity
                      ),
                      child: Text(
                        '${filterManager.getActiveFilterCount()} active',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Colors.blue[700],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expandable filter content
          if (filterManager.isFilterSectionExpanded) ...[
            const SizedBox(height: 8),

            // Main filter categories
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  // Logger Logs filter
                  MainFilterChip(
                    label: 'Logger Logs',
                    icon: Icons.bug_report,
                    color: Colors.purple,
                    isSelected: filterManager.selectedSources
                        .contains(LogSource.general),
                    count: LogDataService.getGeneralLogCount(allLogs),
                    isExpanded: filterManager.isLoggerFiltersExpanded,
                    hasSubFiltersSelected:
                        filterManager.hasLoggerSubFiltersSelected(),
                    onTap: () =>
                        filterManager.toggleLogSource(LogSource.general),
                    onDropdownTap: filterManager.toggleLoggerFiltersExpanded,
                  ),
                  const SizedBox(width: 8),

                  // API Logs filter
                  MainFilterChip(
                    label: 'API Logs',
                    icon: Icons.api,
                    color: Colors.green,
                    isSelected:
                        filterManager.selectedSources.contains(LogSource.api),
                    count: LogDataService.getApiLogCount(allLogs),
                    isExpanded: filterManager.isApiFiltersExpanded,
                    hasSubFiltersSelected:
                        filterManager.hasApiSubFiltersSelected(),
                    onTap: () => filterManager.toggleLogSource(LogSource.api),
                    onDropdownTap: filterManager.toggleApiFiltersExpanded,
                  ),
                  const SizedBox(width: 8),

                  // BLoC Logs filter
                  MainFilterChip(
                    label: 'BLoC Logs',
                    icon: Icons.account_tree,
                    color: Colors.purple,
                    isSelected:
                        filterManager.selectedSources.contains(LogSource.bloc),
                    count: LogDataService.getBlocLogCount(allLogs),
                    isExpanded: filterManager.isBlocFiltersExpanded,
                    hasSubFiltersSelected:
                        filterManager.hasBlocSubFiltersSelected(),
                    onTap: () => filterManager.toggleLogSource(LogSource.bloc),
                    onDropdownTap: filterManager.toggleBlocFiltersExpanded,
                  ),
                ],
              ),
            ),

            // Logger sub-filters
            if (filterManager.isLoggerFiltersExpanded) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  UnifiedLogType.debug,
                  UnifiedLogType.info,
                  UnifiedLogType.warning,
                  UnifiedLogType.error,
                ]
                    .map((type) => SubFilterChip(
                          label: FilterLabels.getLoggerLevelLabel(type),
                          color: type.color,
                          isSelected:
                              filterManager.selectedTypes.contains(type),
                          count: typeCounts[type] ?? 0,
                          onTap: () => filterManager.toggleLogType(type),
                        ))
                    .toList(),
              ),
            ],

            // API sub-filters
            if (filterManager.isApiFiltersExpanded) ...[
              const SizedBox(height: 12),

              // HTTP Methods section
              if (LogDataService.getAvailableMethods(
                allLogs,
                selectedSources: filterManager.selectedSources,
              ).isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: LogDataService.getAvailableMethods(
                    allLogs,
                    selectedSources: filterManager.selectedSources,
                  )
                      .map((method) => SubFilterChip(
                            label: method,
                            color: Colors.green,
                            isSelected:
                                filterManager.selectedMethods.contains(method),
                            count: LogDataService.getMethodCount(
                              allLogs,
                              method,
                              selectedSources: filterManager.selectedSources,
                            ),
                            onTap: () => filterManager.toggleMethod(method),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],

              // API Status section
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  UnifiedLogType.apiSuccess,
                  UnifiedLogType.apiRedirect,
                  UnifiedLogType.apiClientError,
                  UnifiedLogType.apiServerError,
                  UnifiedLogType.apiNetworkError,
                  UnifiedLogType.apiPending,
                ]
                    .map((type) => SubFilterChip(
                          label: FilterLabels.getApiStatusLabel(type),
                          color: type.color,
                          isSelected:
                              filterManager.selectedTypes.contains(type),
                          count: typeCounts[type] ?? 0,
                          onTap: () => filterManager.toggleLogType(type),
                        ))
                    .toList(),
              ),
            ],

            // BLoC sub-filters
            if (filterManager.isBlocFiltersExpanded) ...[
              const SizedBox(height: 12),

              // BLoC Names section
              if (LogDataService.getAvailableBlocNames(
                allLogs,
                selectedSources: filterManager.selectedSources,
              ).isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: LogDataService.getAvailableBlocNames(
                    allLogs,
                    selectedSources: filterManager.selectedSources,
                  )
                      .map((blocName) => SubFilterChip(
                            label: blocName,
                            color: Colors.purple,
                            isSelected: filterManager.selectedBlocNames
                                .contains(blocName),
                            count: LogDataService.getBlocNameCount(
                              allLogs,
                              blocName,
                              selectedSources: filterManager.selectedSources,
                            ),
                            onTap: () => filterManager.toggleBlocName(blocName),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],

              // Event Types section
              if (LogDataService.getAvailableEventTypes(
                allLogs,
                selectedSources: filterManager.selectedSources,
              ).isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: LogDataService.getAvailableEventTypes(
                    allLogs,
                    selectedSources: filterManager.selectedSources,
                  )
                      .map((eventType) => SubFilterChip(
                            label: eventType,
                            color: Colors.cyan,
                            isSelected: filterManager.selectedEventTypes
                                .contains(eventType),
                            count: LogDataService.getEventTypeCount(
                              allLogs,
                              eventType,
                              selectedSources: filterManager.selectedSources,
                            ),
                            onTap: () =>
                                filterManager.toggleEventType(eventType),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],

              // State Types section
              if (LogDataService.getAvailableStateTypes(
                allLogs,
                selectedSources: filterManager.selectedSources,
              ).isNotEmpty) ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: LogDataService.getAvailableStateTypes(
                    allLogs,
                    selectedSources: filterManager.selectedSources,
                  )
                      .map((stateType) => SubFilterChip(
                            label: stateType,
                            color: Colors.indigo,
                            isSelected: filterManager.selectedStateTypes
                                .contains(stateType),
                            count: LogDataService.getStateTypeCount(
                              allLogs,
                              stateType,
                              selectedSources: filterManager.selectedSources,
                            ),
                            onTap: () =>
                                filterManager.toggleStateType(stateType),
                          ))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],

              // BLoC Status section
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  UnifiedLogType.blocEvent,
                  UnifiedLogType.blocTransition,
                  UnifiedLogType.blocChange,
                  UnifiedLogType.blocCreate,
                  UnifiedLogType.blocClose,
                  UnifiedLogType.blocError,
                ]
                    .map((type) => SubFilterChip(
                          label: FilterLabels.getBlocStatusLabel(type),
                          color: type.color,
                          isSelected:
                              filterManager.selectedTypes.contains(type),
                          count: typeCounts[type] ?? 0,
                          onTap: () => filterManager.toggleLogType(type),
                        ))
                    .toList(),
              ),
            ],
          ], // End of _isFilterSectionExpanded
        ],
      ),
    );
  }
}
