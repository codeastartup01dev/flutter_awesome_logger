# Example App Structure

This example demonstrates the usage of `flutter_awesome_logger` with a focus on API logging and the unified logger interface.

## 📁 Directory Structure

```
lib/
├── main.dart                 # App entry point and configuration
├── models/                   # Data models
│   ├── models.dart          # Barrel export for model files (removed)
│   └── user.dart            # User model class (removed)
├── pages/                    # UI pages/screens
│   ├── pages.dart           # Barrel export for page files
│   ├── api_demo_page.dart   # API calls demo page (NEW!)
│   └── demo_page.dart       # Main demo page
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

### 3. **API Demo Page** (`api_demo_page.dart`)
- GET requests (fetch all users, fetch single user)
- POST requests (create new users)
- Error handling and simulation
- Loading states and user feedback
- Beautiful user cards with detailed information
- Automatic API logging with Dio interceptor
- Real-time log updates in unified interface

### 4. **Unified Logging UI** (`AwesomeLoggerHistoryPage`)
- Filter by log source (General, API)
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

### API Demo Page
- **Open API Demo Page**: Navigate to comprehensive API demo
- **Fetch All Users**: GET request to retrieve user list
- **Fetch User #1**: GET request for specific user
- **Create User**: POST request to add new user
- **Simulate Error**: Demonstrates error handling
- **Clear Results**: Reset demo state

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

### API Demo Page Features

The API demo page showcases advanced API logging capabilities:

```dart
// Example of API logging with Dio interceptor
final dio = Dio();
dio.interceptors.add(FlutterAwesomeLoggerDioInterceptor());

// All requests are automatically logged
final response = await dio.get('https://jsonplaceholder.typicode.com/users');

// View logs in the unified interface
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const AwesomeLoggerHistoryPage()),
);
```

**API Demo Features:**
- Real-time request/response logging
- cURL command generation for testing
- Error state management
- Loading indicators
- User-friendly data presentation
- Comprehensive error handling

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
- [Dio HTTP Client Documentation](https://pub.dev/packages/dio)
- [JSONPlaceholder API](https://jsonplaceholder.typicode.com) - Used for demo API calls
