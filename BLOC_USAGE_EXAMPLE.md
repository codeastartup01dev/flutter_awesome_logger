# BLoC Logging Integration Guide

This guide shows how to integrate BLoC logging with `flutter_awesome_logger`.

## Setup

### 1. Add Dependencies

```yaml
dependencies:
  flutter_awesome_logger: ^1.2.1
  flutter_bloc: ^8.1.6
```

### 2. Configure BLoC Observer

In your `main.dart` file:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

void main() {
  // Configure BLoC observer for logging
  Bloc.observer = AwesomeBlocObserver(
    config: AwesomeBlocObserverConfig(
      logEvents: true,
      logTransitions: true,
      logChanges: true,
      logCreate: true,
      logClose: true,
      logErrors: true,
      printToConsole: true,
      maxConsoleLength: 200,
      // Optionally exclude specific BLoC types
      excludedBlocTypes: {'SomeInternalBloc'},
      // Optionally exclude specific event types
      excludedEventTypes: {'InternalEvent'},
    ),
  );

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: FlutterAwesomeLogger(
        config: FloatingLoggerConfig(
          enabled: true,
          showFloatingButton: true,
          position: FloatingButtonPosition.bottomRight,
        ),
        child: MyHomePage(),
      ),
    );
  }
}
```

### 3. Create a Sample BLoC

```dart
// counter_event.dart
abstract class CounterEvent {}

class CounterIncremented extends CounterEvent {}
class CounterDecremented extends CounterEvent {}
class CounterReset extends CounterEvent {}

// counter_state.dart
class CounterState {
  final int count;
  
  const CounterState(this.count);
  
  @override
  String toString() => 'CounterState(count: $count)';
}

// counter_bloc.dart
import 'package:flutter_bloc/flutter_bloc.dart';

class CounterBloc extends Bloc<CounterEvent, CounterState> {
  CounterBloc() : super(const CounterState(0)) {
    on<CounterIncremented>((event, emit) {
      emit(CounterState(state.count + 1));
    });

    on<CounterDecremented>((event, emit) {
      emit(CounterState(state.count - 1));
    });

    on<CounterReset>((event, emit) {
      emit(const CounterState(0));
    });
  }
}
```

### 4. Use the BLoC in Your Widget

```dart
class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => CounterBloc(),
      child: Scaffold(
        appBar: AppBar(title: Text('BLoC Logger Demo')),
        body: BlocBuilder<CounterBloc, CounterState>(
          builder: (context, state) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Count: ${state.count}', style: TextStyle(fontSize: 24)),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: () => context.read<CounterBloc>().add(CounterDecremented()),
                        child: Text('-'),
                      ),
                      ElevatedButton(
                        onPressed: () => context.read<CounterBloc>().add(CounterIncremented()),
                        child: Text('+'),
                      ),
                      ElevatedButton(
                        onPressed: () => context.read<CounterBloc>().add(CounterReset()),
                        child: Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
```

## What You'll See in the Logger

When you interact with the BLoC, you'll see logs in three places:

### 1. Console Output
```
🟢 BLoC Created: CounterBloc
🔵 BLoC Event: CounterBloc received CounterIncremented
   Event Data: Instance of 'CounterIncremented'
🔄 BLoC Transition: CounterBloc
   Event: CounterIncremented
   Current: CounterState -> CounterState(count: 0)
   Next: CounterState -> CounterState(count: 1)
🔀 BLoC Change: CounterBloc
   Current: CounterState -> CounterState(count: 0)
   Next: CounterState -> CounterState(count: 1)
```

### 2. Floating Logger UI
- Tap the floating logger button to see real-time BLoC logs
- Filter by "BLoC Logs" to see only BLoC-related entries
- Each log shows the BLoC name, event type, and timestamp

### 3. Logger History Page
- Access comprehensive BLoC logging with advanced filtering:
  - **BLoC Names**: Filter by specific BLoC types (e.g., CounterBloc, AuthBloc)
  - **Event Types**: Filter by event types (e.g., CounterIncremented, LoginRequested)
  - **State Types**: Filter by state types (e.g., CounterState, AuthState)
  - **BLoC Status**: Filter by log types (Event, Transition, Change, Create, Close, Error)

## Advanced Configuration

### Custom BLoC Observer Settings

```dart
Bloc.observer = AwesomeBlocObserver(
  config: AwesomeBlocObserverConfig(
    // Enable/disable specific log types
    logEvents: true,
    logTransitions: true,
    logChanges: false, // Disable change logs to reduce noise
    logCreate: true,
    logClose: true,
    logErrors: true,
    
    // Console output settings
    printToConsole: true,
    maxConsoleLength: 100, // Truncate long state/event strings
    
    // Filter out internal BLoCs you don't want to log
    excludedBlocTypes: {
      'InternalNavigationBloc',
      'ThemeBloc',
    },
    
    // Filter out frequent events you don't want to log
    excludedEventTypes: {
      'TimerTick',
      'LocationUpdate',
    },
  ),
);
```

### Integration with Existing Logging

The BLoC logs integrate seamlessly with your existing general logs and API logs:

```dart
// Your existing logger usage
final logger = FlutterAwesomeLogger.loggingUsingLogger;
logger.i('User started counter interaction');

// BLoC events (automatically logged)
context.read<CounterBloc>().add(CounterIncremented());

// API calls (automatically logged with Dio interceptor)
await dio.get('/api/counter');
```

All three types of logs (General, API, BLoC) appear together in the unified logger history page with consistent filtering and search capabilities.

## Features

### BLoC Log Types
- **Event**: When an event is added to a BLoC
- **Transition**: State transitions with event context
- **Change**: State changes (without event context)
- **Create**: BLoC instance creation
- **Close**: BLoC instance disposal
- **Error**: BLoC errors and exceptions

### Filtering Options
- **By BLoC Name**: See logs from specific BLoC instances
- **By Event Type**: Filter by specific event types
- **By State Type**: Filter by specific state types
- **By Status**: Filter by log type (Event, Transition, etc.)
- **Search**: Full-text search across all BLoC log content

### Export and Sharing
- Copy individual log entries
- Copy BLoC commands (e.g., `bloc.add(CounterIncremented())`)
- Copy BLoC names, event data, or state data
- Export filtered log sets for debugging
- Share logs with team members

This integration provides comprehensive BLoC debugging capabilities while maintaining the same intuitive interface as the existing general and API logging features.
