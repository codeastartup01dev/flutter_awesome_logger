import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

final navigatorKey = GlobalKey<NavigatorState>();

// Create global logger instance using FlutterAwesomeLogger
final logger = FlutterAwesomeLogger.loggingUsingLogger;

// User model
class User {
  final int id;
  final String name;
  final String email;
  final String phone;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
    );
  }

  @override
  String toString() => 'User(id: $id, name: $name, email: $email)';
}

// User state
abstract class UserState {}

class UserInitial extends UserState {}

class UserLoading extends UserState {}

class UserLoaded extends UserState {
  final List<User> users;
  UserLoaded(this.users);

  @override
  String toString() => 'UserLoaded(${users.length} users)';
}

class UserError extends UserState {
  final String message;
  UserError(this.message);

  @override
  String toString() => 'UserError(message: $message)';
}

// User Cubit
class UserCubit extends Cubit<UserState> {
  final Dio _dio;

  UserCubit(this._dio) : super(UserInitial());

  Future<void> fetchUsers() async {
    try {
      emit(UserLoading());
      logger.i('UserCubit: Starting to fetch users from JSONPlaceholder');

      // Try JSONPlaceholder API first
      final response = await _dio.get(
        'https://jsonplaceholder.typicode.com/users',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Flutter Demo App',
          },
        ),
      );

      if (response.statusCode == 200) {
        final users =
            (response.data as List).map((json) => User.fromJson(json)).toList();
        logger.i(
            'UserCubit: Successfully fetched ${users.length} users from JSONPlaceholder');
        emit(UserLoaded(users));
      } else {
        logger.w('UserCubit: Unexpected status code: ${response.statusCode}');
      }
    } catch (e) {
      logger.w('UserCubit: JSONPlaceholder API failed, using mock data');
      logger.e('API Error details', error: e);
    }
  }

  void useMockData() {
    try {
      final mockUsers = _createMockUsers();
      logger.i('UserCubit: Using mock data - ${mockUsers.length} users');
      emit(UserLoaded(mockUsers));
    } catch (e) {
      logger.e('UserCubit: Failed to create mock data', error: e);
      emit(UserError(
          'Failed to load users. Please check your internet connection.'));
    }
  }

  List<User> _createMockUsers() {
    // Using the actual JSONPlaceholder data as fallback
    return [
      User(
          id: 1,
          name: 'Leanne Graham',
          email: 'Sincere@april.biz',
          phone: '1-770-736-8031 x56442'),
      User(
          id: 2,
          name: 'Ervin Howell',
          email: 'Shanna@melissa.tv',
          phone: '010-692-6593 x09125'),
      User(
          id: 3,
          name: 'Clementine Bauch',
          email: 'Nathan@yesenia.net',
          phone: '1-463-123-4447'),
      User(
          id: 4,
          name: 'Patricia Lebsack',
          email: 'Julianne.OConner@kory.org',
          phone: '493-170-9623 x156'),
      User(
          id: 5,
          name: 'Chelsey Dietrich',
          email: 'Lucio_Hettinger@annie.ca',
          phone: '(254)954-1289'),
      User(
          id: 6,
          name: 'Mrs. Dennis Schulist',
          email: 'Karley_Dach@jasper.info',
          phone: '1-477-935-8478 x6430'),
      User(
          id: 7,
          name: 'Kurtis Weissnat',
          email: 'Telly.Hoeger@billy.biz',
          phone: '210.067.6132'),
      User(
          id: 8,
          name: 'Nicholas Runolfsdottir V',
          email: 'Sherwood@rosamond.me',
          phone: '586.493.6943 x140'),
      User(
          id: 9,
          name: 'Glenna Reichert',
          email: 'Chaim_McDermott@dana.io',
          phone: '(775)976-6794 x41206'),
      User(
          id: 10,
          name: 'Clementina DuBuque',
          email: 'Rey.Padberg@karina.biz',
          phone: '024-648-3804'),
    ];
  }

  Future<void> fetchUserById(int id) async {
    try {
      emit(UserLoading());
      logger.i('UserCubit: Fetching user with ID: $id from JSONPlaceholder');

      final response = await _dio.get(
        'https://jsonplaceholder.typicode.com/users/$id',
        options: Options(
          headers: {
            'Accept': 'application/json',
            'User-Agent': 'Flutter Demo App',
          },
        ),
      );

      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);
        logger.i('UserCubit: Successfully fetched user: ${user.name}');
        emit(UserLoaded([user]));
      } else {
        logger.w(
            'UserCubit: Unexpected status code for user $id: ${response.statusCode}');
        _useMockUserById(id);
      }
    } catch (e) {
      logger
          .w('UserCubit: JSONPlaceholder failed for user $id, using mock data');
      logger.e('API Error details for user $id', error: e);
      _useMockUserById(id);
    }
  }

  void _useMockUserById(int id) {
    try {
      final mockUsers = _createMockUsers();
      if (id > 0 && id <= mockUsers.length) {
        final user = mockUsers[id - 1]; // Get user by index (id is 1-based)
        logger.i('UserCubit: Using mock data - fetched user: ${user.name}');
        emit(UserLoaded([user]));
      } else {
        logger.w('UserCubit: Invalid user ID: $id');
        emit(UserError('User with ID $id not found'));
      }
    } catch (e) {
      logger.e('UserCubit: Mock data fetch failed for user $id', error: e);
      emit(UserError('Failed to fetch user: $e'));
    }
  }

  void clearUsers() {
    logger.i('UserCubit: Clearing users');
    emit(UserInitial());
  }
}

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
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // Future that resolves to true after 3 seconds
  Future<bool> _shouldEnableLogger() async {
    await Future.delayed(const Duration(seconds: 3));
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey:
          navigatorKey, // IMPORTANT: add it here and in the FlutterAwesomeLogger if logger history page doesn't open on clicking the floating button
      title: 'Awesome Flutter Logger Demo',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: BlocProvider(
        create: (context) {
          final dio = Dio(
            BaseOptions(
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
                'User-Agent': 'Flutter App',
              },
              connectTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
              validateStatus: (status) =>
                  status! < 500, // Allow 4xx errors to be handled
            ),
          );
          dio.interceptors.add(FlutterAwesomeLoggerDioInterceptor());
          return UserCubit(dio);
        },
        child: FlutterAwesomeLogger(
          // enabled:true, //or
          // 🔄 Enable logging after 3 seconds using Future
          enabled: _shouldEnableLogger(),
          navigatorKey:
              navigatorKey, // IMPORTANT: add it here and in the MaterialApp if logger history page doesn't open on clicking the floating button
          // ✨ logger config (optional)
          loggerConfig: const AwesomeLoggerConfig(
            maxLogEntries: 500,
            showFilePaths: true,
            showEmojis: true,
            useColors: true,
          ),

          // 🎨 Floating logger UI configuration (optional)
          config: const FloatingLoggerConfig(
            backgroundColor: Colors.deepPurple,
            icon: Icons.developer_mode,
            showCount: true,
            enableGestures: true,
            autoSnapToEdges: true,
            enableShakeToShowHideFloatingButton: true,
            enableShakeToEnableLogger: true,
            shakeSensitivity: 8,
          ),

          child: const DemoPage(),
        ),
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}

class DemoPage extends StatefulWidget {
  const DemoPage({super.key});

  @override
  State<DemoPage> createState() => _DemoPageState();
}

class _DemoPageState extends State<DemoPage> {
  late Dio _dio;
  int _logCounter = 0;

  @override
  void initState() {
    super.initState();
    _setupDio();
    logger.i('DemoPage initialized - Logger will be enabled in 3 seconds!');
  }

  void _setupDio() {
    _dio = Dio();
    // Add the awesome logger interceptor
    _dio.interceptors.add(FlutterAwesomeLoggerDioInterceptor());
    logger.d('Dio configured with AwesomeLoggerInterceptor');
  }

  void _generateDifferentLogs() {
    setState(() {
      _logCounter++;
    });

    logger.d('Debug log #$_logCounter - This is a debug message');
    logger.i('Info log #$_logCounter - Application state updated');
    logger.w('Warning log #$_logCounter - This is a warning message');

    if (_logCounter % 3 == 0) {
      try {
        throw Exception('Sample error for demonstration');
      } catch (e, stackTrace) {
        logger.e(
          'Error log #$_logCounter - Something went wrong!',
          error: e,
          stackTrace: stackTrace,
        );
      }
    }
  }

  Future<void> _makeApiCall(String endpoint) async {
    try {
      logger.i('Making API call to: $endpoint');
      final response = await _dio.get(endpoint);
      logger.i('API call successful: ${response.statusCode}');
    } catch (e) {
      logger.e('API call failed', error: e);
    }
  }

  void _openLogger() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AwesomeLoggerHistoryPage()),
    );
  }

  void _toggleLoggerVisibility() {
    FlutterAwesomeLogger.toggleVisibility();
    final isVisible = FlutterAwesomeLogger.isVisible();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Floating logger ${isVisible ? 'shown' : 'hidden'}'),
        ),
      );
    }
  }

  void _openCubitDemo() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BlocProvider(
          create: (context) => UserCubit(_dio),
          child: const CubitDemoPage(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Awesome Logger Demo'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: _toggleLoggerVisibility,
            tooltip: 'Toggle Floating Logger',
          ),
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: _openLogger,
            tooltip: 'Open Logger History',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🚀 Awesome Flutter Logger Demo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        '\n🎯 Floating logger button (look for the floating button!)',
                      ),
                      Text(
                        '\n📊 General logging with different levels using logger.d, logger.i, logger.w, logger.e',
                      ),
                      Text(
                        '\n🌐 API request/response logging using Dio interceptor (FlutterAwesomeLoggerDioInterceptor)',
                      ),
                      Text(
                        '\n🧊 BLoC/Cubit state management logging with AwesomeBlocObserver',
                      ),
                      Text(
                          '\n🎨 Unified UI for browsing and searching all logs in one place'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Demo Actions:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _generateDifferentLogs,
                icon: const Icon(Icons.note_add),
                label: Text('Generate GeneralLogs ($_logCounter generated)'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _makeApiCall(
                  'https://jsonplaceholder.typicode.com/posts/1/',
                ),
                icon: const Icon(Icons.web),
                label: const Text('Make Successful API Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _makeApiCall('https://httpstat.us/500'),
                icon: const Icon(Icons.error),
                label: const Text('Make Failing API Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () =>
                    _makeApiCall('https://nonexistent-domain-xyz.com/api'),
                icon: const Icon(Icons.cloud_off),
                label: const Text('Make Network Error Call'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _openCubitDemo(),
                icon: const Icon(Icons.account_tree),
                label: const Text('Example with Cubit (BLoC)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _openLogger,
                icon: const Icon(Icons.list_alt),
                label: const Text('Open Awesome Logger'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                  backgroundColor: Colors.purple.withValues(alpha: 0.1),
                  foregroundColor: Colors.purple,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _toggleLoggerVisibility,
                icon: const Icon(Icons.visibility),
                label: const Text('Toggle Floating Logger'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 16),
              const Card(
                color: Colors.blue,
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Icon(Icons.info, color: Colors.white),
                      SizedBox(height: 8),
                      Text(
                        'Tap the floating button to access logs quickly!\n\n🤳 Shake your device to show/hide the logger button!\n\n🤳 Shake when logger is disabled to enable it!',
                        style: TextStyle(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CubitDemoPage extends StatelessWidget {
  const CubitDemoPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cubit (BLoC) Demo'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              color: Colors.purple,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '🧊 Cubit Demo with API Calls',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This demo shows BLoC logging with Cubit state management.\n\n'
                      '• Watch BLoC logs in the logger\n'
                      '• See state changes and API calls\n'
                      '• Filter by "BLoC Logs" in the logger\n'
                      '• Uses JSONPlaceholder API with mock fallback',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.read<UserCubit>().fetchUsers(),
                    icon: const Icon(Icons.people),
                    label: const Text('Fetch All Users'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.read<UserCubit>().fetchUserById(1),
                    icon: const Icon(Icons.person),
                    label: const Text('Fetch User #1'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.read<UserCubit>().clearUsers(),
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Users'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => context.read<UserCubit>().useMockData(),
                    icon: const Icon(Icons.offline_bolt),
                    label: const Text('Use Mock Data'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: BlocBuilder<UserCubit, UserState>(
                builder: (context, state) {
                  if (state is UserInitial) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.people_outline,
                              size: 64, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No users loaded\nTap a button above to start',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  } else if (state is UserLoading) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Loading users...'),
                        ],
                      ),
                    );
                  } else if (state is UserLoaded) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Loaded ${state.users.length} user(s):',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: ListView.builder(
                            itemCount: state.users.length,
                            itemBuilder: (context, index) {
                              final user = state.users[index];
                              return Card(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: Colors.purple,
                                    child: Text(
                                      user.name.substring(0, 1),
                                      style:
                                          const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(user.name),
                                  subtitle: Text(user.email),
                                  trailing: Text('#${user.id}'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    );
                  } else if (state is UserError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline,
                              size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error: ${state.message}',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                color: Colors.red, fontSize: 16),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                context.read<UserCubit>().fetchUsers(),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AwesomeLoggerHistoryPage(),
                  ),
                );
              },
              icon: const Icon(Icons.list_alt),
              label: const Text('Open Logger (Check BLoC Logs!)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.purple.withValues(alpha: 0.1),
                foregroundColor: Colors.purple,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
