# Example App Structure

This example demonstrates the usage of `flutter_awesome_logger` with a well-organized project structure.

## 📁 Directory Structure

```
lib/
├── main.dart                 # App entry point and configuration
├── cubit/                    # BLoC/Cubit state management
│   ├── cubit.dart           # Barrel export for cubit files
│   ├── user_cubit.dart      # User management cubit
│   └── user_state.dart      # User state definitions
├── models/                   # Data models
│   ├── models.dart          # Barrel export for model files
│   └── user.dart            # User model class
├── pages/                    # UI pages/screens
│   ├── pages.dart           # Barrel export for page files
│   ├── demo_page.dart       # Main demo page
│   └── cubit_demo_page.dart # BLoC/Cubit demo page
└── README.md                # This file
```

## 🎯 Key Features Demonstrated

### 1. **General Logging** (`demo_page.dart`)
- Debug, Info, Warning, and Error logs
- Stack trace logging
- File path logging
- Emoji and color support

### 2. **API Logging** (`demo_page.dart`, `user_cubit.dart`)
- Automatic request/response logging via Dio interceptor
- Success and error response logging
- Network error handling
- Custom headers and timeout configuration

### 3. **BLoC Logging** (`user_cubit.dart`)
- State change logging
- Event logging
- Transition logging
- Error logging in BLoC context
- Cubit lifecycle logging

### 4. **Unified Logging UI** (`AwesomeLoggerHistoryPage`)
- Filter by log source (General, API, BLoC)
- Search functionality
- Copy log details
- Export capabilities
- Real-time log updates

## 🚀 Getting Started

1. **Run the app**: `flutter run`
2. **Wait 3 seconds** for the logger to enable (or use `enabled: true` for immediate)
3. **Look for the floating logger button** (purple circle with developer icon)
4. **Try different demo actions** to generate various types of logs
5. **Open the logger** to see all logs in a unified interface

## 📱 Demo Actions

### General Logging
- **Generate Logs**: Creates debug, info, warning, and error logs
- **Toggle Logger**: Show/hide the floating logger button
- **Open Logger**: Navigate to the full logger history page

### API Logging
- **Successful API Call**: Makes a successful request to JSONPlaceholder
- **Failing API Call**: Makes a request that returns 500 error
- **Network Error Call**: Makes a request to a non-existent domain

### BLoC Logging
- **Fetch All Users**: Demonstrates API call with BLoC state management
- **Fetch User #1**: Fetches a single user by ID
- **Clear Users**: Resets the state to initial
- **Use Mock Data**: Uses local mock data (useful for offline testing)

## 🎨 Customization

### Logger Configuration
```dart
loggerConfig: const AwesomeLoggerConfig(
  maxLogEntries: 500,        // Maximum logs to keep in memory
  showFilePaths: true,       // Show file paths in logs
  showEmojis: true,          // Use emojis in log display
  useColors: true,           // Use colors for different log levels
),
```

### Floating Logger UI
```dart
config: const FloatingLoggerConfig(
  backgroundColor: Colors.deepPurple,  // Button background color
  icon: Icons.developer_mode,          // Button icon
  showCount: true,                     // Show log count on button
  enableGestures: true,                // Enable drag gestures
  autoSnapToEdges: true,               // Auto-snap to screen edges
),
```

### BLoC Observer Configuration
```dart
Bloc.observer = AwesomeBlocObserver(
  config: AwesomeBlocObserverConfig(
    logEvents: true,           // Log BLoC events
    logTransitions: true,      // Log BLoC transitions
    logChanges: true,          // Log BLoC state changes
    logCreate: true,           // Log BLoC creation
    logClose: true,            // Log BLoC disposal
    logErrors: true,           // Log BLoC errors
    printToConsole: true,      // Also print to console
    maxConsoleLength: 200,     // Max length for console output
  ),
),
```

## 🔧 Architecture Benefits

### Separation of Concerns
- **Models**: Pure data classes with JSON serialization
- **Cubit**: Business logic and state management
- **Pages**: UI components and user interactions
- **Main**: App configuration and dependency injection

### Maintainability
- **Barrel Exports**: Clean imports using `cubit/cubit.dart`, `models/models.dart`, etc.
- **Single Responsibility**: Each file has a clear, focused purpose
- **Testability**: Easy to unit test individual components

### Scalability
- **Modular Structure**: Easy to add new features
- **Consistent Patterns**: Clear conventions for new developers
- **Reusable Components**: Models and cubits can be reused across pages

## 📚 Learn More

- [flutter_awesome_logger Documentation](../README.md)
- [BLoC Library Documentation](https://bloclibrary.dev)
- [Dio HTTP Client Documentation](https://pub.dev/packages/dio)
