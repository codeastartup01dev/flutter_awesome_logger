/// Represents a single BLoC log entry with metadata
class BlocLogEntry {
  /// Unique identifier for this log entry
  final String id;

  /// The BLoC instance name/type
  final String blocName;

  /// Type of BLoC log (event, transition, change, create, close, error)
  final BlocLogType type;

  /// When this log entry was created
  final DateTime timestamp;

  /// The event that triggered this log (for event/transition logs)
  final Object? event;

  /// The current state (for transition/change logs)
  final Object? currentState;

  /// The next state (for transition logs)
  final Object? nextState;

  /// Error information (for error logs)
  final Object? error;

  /// Stack trace (for error logs)
  final StackTrace? stackTrace;

  /// Additional context or metadata
  final Map<String, dynamic>? metadata;

  const BlocLogEntry({
    required this.id,
    required this.blocName,
    required this.type,
    required this.timestamp,
    this.event,
    this.currentState,
    this.nextState,
    this.error,
    this.stackTrace,
    this.metadata,
  });

  /// Create a BLoC event log entry
  factory BlocLogEntry.event({
    required String blocName,
    required Object event,
    Map<String, dynamic>? metadata,
  }) {
    final timestamp = DateTime.now();
    return BlocLogEntry(
      id: '${timestamp.millisecondsSinceEpoch}_bloc_event',
      blocName: blocName,
      type: BlocLogType.event,
      timestamp: timestamp,
      event: event,
      metadata: metadata,
    );
  }

  /// Create a BLoC transition log entry
  factory BlocLogEntry.transition({
    required String blocName,
    required Object event,
    required Object currentState,
    required Object nextState,
    Map<String, dynamic>? metadata,
  }) {
    final timestamp = DateTime.now();
    return BlocLogEntry(
      id: '${timestamp.millisecondsSinceEpoch}_bloc_transition',
      blocName: blocName,
      type: BlocLogType.transition,
      timestamp: timestamp,
      event: event,
      currentState: currentState,
      nextState: nextState,
      metadata: metadata,
    );
  }

  /// Create a BLoC change log entry
  factory BlocLogEntry.change({
    required String blocName,
    required Object currentState,
    required Object nextState,
    Map<String, dynamic>? metadata,
  }) {
    final timestamp = DateTime.now();
    return BlocLogEntry(
      id: '${timestamp.millisecondsSinceEpoch}_bloc_change',
      blocName: blocName,
      type: BlocLogType.change,
      timestamp: timestamp,
      currentState: currentState,
      nextState: nextState,
      metadata: metadata,
    );
  }

  /// Create a BLoC create log entry
  factory BlocLogEntry.create({
    required String blocName,
    Map<String, dynamic>? metadata,
  }) {
    final timestamp = DateTime.now();
    return BlocLogEntry(
      id: '${timestamp.millisecondsSinceEpoch}_bloc_create',
      blocName: blocName,
      type: BlocLogType.create,
      timestamp: timestamp,
      metadata: metadata,
    );
  }

  /// Create a BLoC close log entry
  factory BlocLogEntry.close({
    required String blocName,
    Map<String, dynamic>? metadata,
  }) {
    final timestamp = DateTime.now();
    return BlocLogEntry(
      id: '${timestamp.millisecondsSinceEpoch}_bloc_close',
      blocName: blocName,
      type: BlocLogType.close,
      timestamp: timestamp,
      metadata: metadata,
    );
  }

  /// Create a BLoC error log entry
  factory BlocLogEntry.error({
    required String blocName,
    required Object error,
    StackTrace? stackTrace,
    Map<String, dynamic>? metadata,
  }) {
    final timestamp = DateTime.now();
    return BlocLogEntry(
      id: '${timestamp.millisecondsSinceEpoch}_bloc_error',
      blocName: blocName,
      type: BlocLogType.error,
      timestamp: timestamp,
      error: error,
      stackTrace: stackTrace,
      metadata: metadata,
    );
  }

  /// Get display title for this log entry
  String get displayTitle {
    switch (type) {
      case BlocLogType.event:
        return '$blocName received ${event.runtimeType}';
      case BlocLogType.transition:
        return '$blocName: ${currentState.runtimeType} → ${nextState.runtimeType}';
      case BlocLogType.change:
        return '$blocName state changed to ${nextState.runtimeType}';
      case BlocLogType.create:
        return '$blocName created';
      case BlocLogType.close:
        return '$blocName closed';
      case BlocLogType.error:
        return '$blocName error: ${error.runtimeType}';
    }
  }

  /// Get formatted content for display
  String get formattedContent {
    final buffer = StringBuffer();
    buffer.writeln('=== BLOC LOG ===');
    buffer.writeln('BLoC: $blocName');
    buffer.writeln('Type: ${type.displayName}');
    buffer.writeln('Time: $timestamp');

    switch (type) {
      case BlocLogType.event:
        buffer.writeln('Event: ${event.runtimeType}');
        buffer.writeln('Event Data: $event');
        break;
      case BlocLogType.transition:
        buffer.writeln('Event: ${event.runtimeType}');
        buffer.writeln('Event Data: $event');
        buffer.writeln('Current State: ${currentState.runtimeType}');
        buffer.writeln('Current State Data: $currentState');
        buffer.writeln('Next State: ${nextState.runtimeType}');
        buffer.writeln('Next State Data: $nextState');
        break;
      case BlocLogType.change:
        buffer.writeln('Current State: ${currentState.runtimeType}');
        buffer.writeln('Current State Data: $currentState');
        buffer.writeln('Next State: ${nextState.runtimeType}');
        buffer.writeln('Next State Data: $nextState');
        break;
      case BlocLogType.create:
        buffer.writeln('BLoC instance created');
        break;
      case BlocLogType.close:
        buffer.writeln('BLoC instance closed');
        break;
      case BlocLogType.error:
        buffer.writeln('Error: ${error.runtimeType}');
        buffer.writeln('Error Details: $error');
        if (stackTrace != null) {
          buffer.writeln('Stack Trace:');
          buffer.writeln(stackTrace.toString());
        }
        break;
    }

    if (metadata != null && metadata!.isNotEmpty) {
      buffer.writeln('Metadata: $metadata');
    }

    return buffer.toString();
  }

  /// Get formatted request-like content (for consistency with API logs)
  String get formattedRequest {
    final buffer = StringBuffer();
    buffer.writeln('BLoC: $blocName');
    buffer.writeln('Type: ${type.displayName}');

    if (event != null) {
      buffer.writeln('Event: ${event.runtimeType}');
      buffer.writeln('Event Data: $event');
    }

    if (currentState != null) {
      buffer.writeln('Current State: ${currentState.runtimeType}');
      buffer.writeln('Current State Data: $currentState');
    }

    return buffer.toString();
  }

  /// Get formatted response-like content (for consistency with API logs)
  String get formattedResponse {
    final buffer = StringBuffer();

    if (nextState != null) {
      buffer.writeln('Next State: ${nextState.runtimeType}');
      buffer.writeln('Next State Data: $nextState');
    }

    if (error != null) {
      buffer.writeln('Error: ${error.runtimeType}');
      buffer.writeln('Error Details: $error');
      if (stackTrace != null) {
        buffer.writeln('Stack Trace:');
        buffer.writeln(stackTrace.toString());
      }
    }

    if (type == BlocLogType.create) {
      buffer.writeln('BLoC instance created successfully');
    } else if (type == BlocLogType.close) {
      buffer.writeln('BLoC instance closed successfully');
    }

    return buffer.toString();
  }

  /// Get command-like content (for consistency with API logs)
  String get command {
    switch (type) {
      case BlocLogType.event:
        return 'bloc.add(${event.runtimeType}())';
      case BlocLogType.transition:
        return 'bloc.emit(${nextState.runtimeType}())';
      case BlocLogType.change:
        return 'bloc.emit(${nextState.runtimeType}())';
      case BlocLogType.create:
        return '$blocName()';
      case BlocLogType.close:
        return 'bloc.close()';
      case BlocLogType.error:
        return 'throw ${error.runtimeType}()';
    }
  }

  @override
  String toString() {
    return 'BlocLogEntry(id: $id, blocName: $blocName, type: $type, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BlocLogEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Types of BLoC log entries
enum BlocLogType {
  event,
  transition,
  change,
  create,
  close,
  error,
}

/// Extension for BlocLogType
extension BlocLogTypeExtension on BlocLogType {
  String get displayName {
    switch (this) {
      case BlocLogType.event:
        return 'Event';
      case BlocLogType.transition:
        return 'Transition';
      case BlocLogType.change:
        return 'Change';
      case BlocLogType.create:
        return 'Create';
      case BlocLogType.close:
        return 'Close';
      case BlocLogType.error:
        return 'Error';
    }
  }
}
