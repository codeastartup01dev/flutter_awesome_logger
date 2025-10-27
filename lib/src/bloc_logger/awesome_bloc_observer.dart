import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc_log_entry.dart';
import 'bloc_logger_service.dart';

/// Configuration for AwesomeBlocObserver
class AwesomeBlocObserverConfig {
  /// Whether to log BLoC events
  final bool logEvents;

  /// Whether to log BLoC transitions
  final bool logTransitions;

  /// Whether to log BLoC changes
  final bool logChanges;

  /// Whether to log BLoC creation
  final bool logCreate;

  /// Whether to log BLoC closure
  final bool logClose;

  /// Whether to log BLoC errors
  final bool logErrors;

  /// Whether to print logs to console
  final bool printToConsole;

  /// Maximum length for state/event data in console output
  final int maxConsoleLength;

  /// BLoC types to exclude from logging (by runtime type string)
  final Set<String> excludedBlocTypes;

  /// Event types to exclude from logging (by runtime type string)
  final Set<String> excludedEventTypes;

  const AwesomeBlocObserverConfig({
    this.logEvents = true,
    this.logTransitions = true,
    this.logChanges = true,
    this.logCreate = true,
    this.logClose = true,
    this.logErrors = true,
    this.printToConsole = true,
    this.maxConsoleLength = 200,
    this.excludedBlocTypes = const {},
    this.excludedEventTypes = const {},
  });

  /// Create a copy with updated fields
  AwesomeBlocObserverConfig copyWith({
    bool? logEvents,
    bool? logTransitions,
    bool? logChanges,
    bool? logCreate,
    bool? logClose,
    bool? logErrors,
    bool? printToConsole,
    int? maxConsoleLength,
    Set<String>? excludedBlocTypes,
    Set<String>? excludedEventTypes,
  }) {
    return AwesomeBlocObserverConfig(
      logEvents: logEvents ?? this.logEvents,
      logTransitions: logTransitions ?? this.logTransitions,
      logChanges: logChanges ?? this.logChanges,
      logCreate: logCreate ?? this.logCreate,
      logClose: logClose ?? this.logClose,
      logErrors: logErrors ?? this.logErrors,
      printToConsole: printToConsole ?? this.printToConsole,
      maxConsoleLength: maxConsoleLength ?? this.maxConsoleLength,
      excludedBlocTypes: excludedBlocTypes ?? this.excludedBlocTypes,
      excludedEventTypes: excludedEventTypes ?? this.excludedEventTypes,
    );
  }
}

/// Custom BlocObserver that integrates with flutter_awesome_logger
class AwesomeBlocObserver extends BlocObserver {
  final AwesomeBlocObserverConfig config;

  AwesomeBlocObserver({
    this.config = const AwesomeBlocObserverConfig(),
  });

  @override
  void onCreate(BlocBase bloc) {
    super.onCreate(bloc);

    if (!config.logCreate) return;

    final blocName = _getBlocName(bloc);
    if (config.excludedBlocTypes.contains(bloc.runtimeType.toString())) return;

    final logEntry = BlocLogEntry.create(
      blocName: blocName,
      metadata: {
        'runtimeType': bloc.runtimeType.toString(),
      },
    );

    BlocLoggerService.addBlocLog(logEntry);

    if (config.printToConsole) {
      print('🟢 BLoC Created: $blocName'); // ignore: avoid_print
    }
  }

  @override
  void onEvent(BlocBase bloc, Object? event) {
    if (bloc is Bloc) {
      super.onEvent(bloc, event);
    }

    if (!config.logEvents || event == null) return;

    final blocName = _getBlocName(bloc);
    if (config.excludedBlocTypes.contains(bloc.runtimeType.toString())) return;
    if (config.excludedEventTypes.contains(event.runtimeType.toString())) {
      return;
    }

    final logEntry = BlocLogEntry.event(
      blocName: blocName,
      event: event,
      metadata: {
        'blocRuntimeType': bloc.runtimeType.toString(),
        'eventRuntimeType': event.runtimeType.toString(),
      },
    );

    BlocLoggerService.addBlocLog(logEntry);

    if (config.printToConsole) {
      final eventStr =
          _truncateString(event.toString(), config.maxConsoleLength);
      print(// ignore: avoid_print
          '🔵 BLoC Event: $blocName received ${event.runtimeType}');
      print('   Event Data: $eventStr'); // ignore: avoid_print
    }
  }

  @override
  void onTransition(BlocBase bloc, Transition transition) {
    if (bloc is Bloc) {
      super.onTransition(bloc, transition);
    }

    if (!config.logTransitions) return;

    final blocName = _getBlocName(bloc);
    if (config.excludedBlocTypes.contains(bloc.runtimeType.toString())) return;

    final logEntry = BlocLogEntry.transition(
      blocName: blocName,
      event: transition.event,
      currentState: transition.currentState,
      nextState: transition.nextState,
      metadata: {
        'blocRuntimeType': bloc.runtimeType.toString(),
        'eventRuntimeType': transition.event.runtimeType.toString(),
        'currentStateRuntimeType':
            transition.currentState.runtimeType.toString(),
        'nextStateRuntimeType': transition.nextState.runtimeType.toString(),
      },
    );

    BlocLoggerService.addBlocLog(logEntry);

    if (config.printToConsole) {
      final currentStateStr = _truncateString(
        transition.currentState.toString(),
        config.maxConsoleLength,
      );
      final nextStateStr = _truncateString(
        transition.nextState.toString(),
        config.maxConsoleLength,
      );
      print('🔄 BLoC Transition: $blocName'); // ignore: avoid_print
      print('   Event: ${transition.event.runtimeType}'); // ignore: avoid_print
      print(// ignore: avoid_print
          '   Current: ${transition.currentState.runtimeType} -> $currentStateStr');
      print(// ignore: avoid_print
          '   Next: ${transition.nextState.runtimeType} -> $nextStateStr');
    }
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);

    if (!config.logChanges) return;

    final blocName = _getBlocName(bloc);
    if (config.excludedBlocTypes.contains(bloc.runtimeType.toString())) return;

    final logEntry = BlocLogEntry.change(
      blocName: blocName,
      currentState: change.currentState,
      nextState: change.nextState,
      metadata: {
        'blocRuntimeType': bloc.runtimeType.toString(),
        'currentStateRuntimeType': change.currentState.runtimeType.toString(),
        'nextStateRuntimeType': change.nextState.runtimeType.toString(),
      },
    );

    BlocLoggerService.addBlocLog(logEntry);

    if (config.printToConsole) {
      final currentStateStr = _truncateString(
        change.currentState.toString(),
        config.maxConsoleLength,
      );
      final nextStateStr = _truncateString(
        change.nextState.toString(),
        config.maxConsoleLength,
      );
      print('🔀 BLoC Change: $blocName'); // ignore: avoid_print
      print(// ignore: avoid_print
          '   Current: ${change.currentState.runtimeType} -> $currentStateStr');
      print(// ignore: avoid_print
          '   Next: ${change.nextState.runtimeType} -> $nextStateStr');
    }
  }

  @override
  void onClose(BlocBase bloc) {
    super.onClose(bloc);

    if (!config.logClose) return;

    final blocName = _getBlocName(bloc);
    if (config.excludedBlocTypes.contains(bloc.runtimeType.toString())) return;

    final logEntry = BlocLogEntry.close(
      blocName: blocName,
      metadata: {
        'runtimeType': bloc.runtimeType.toString(),
      },
    );

    BlocLoggerService.addBlocLog(logEntry);

    if (config.printToConsole) {
      print('🔴 BLoC Closed: $blocName'); // ignore: avoid_print
    }
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    super.onError(bloc, error, stackTrace);

    if (!config.logErrors) return;

    final blocName = _getBlocName(bloc);
    if (config.excludedBlocTypes.contains(bloc.runtimeType.toString())) return;

    final logEntry = BlocLogEntry.error(
      blocName: blocName,
      error: error,
      stackTrace: stackTrace,
      metadata: {
        'blocRuntimeType': bloc.runtimeType.toString(),
        'errorRuntimeType': error.runtimeType.toString(),
      },
    );

    BlocLoggerService.addBlocLog(logEntry);

    if (config.printToConsole) {
      print('❌ BLoC Error: $blocName'); // ignore: avoid_print
      print('   Error: ${error.runtimeType} -> $error'); // ignore: avoid_print
      print(// ignore: avoid_print
          '   Stack Trace: ${stackTrace.toString().split('\n').take(3).join('\n')}...');
    }
  }

  /// Get a readable name for the BLoC
  String _getBlocName(BlocBase bloc) {
    final typeName = bloc.runtimeType.toString();
    // Remove generic type parameters if present
    final cleanName = typeName.split('<').first;
    return cleanName;
  }

  /// Truncate string to specified length
  String _truncateString(String str, int maxLength) {
    if (str.length <= maxLength) return str;
    return '${str.substring(0, maxLength)}...';
  }
}
