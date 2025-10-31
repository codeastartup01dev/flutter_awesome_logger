import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

/// Global logger instance for API demo
final logger = FlutterAwesomeLogger.loggingUsingLogger;

/// Model class for User data
class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String website;
  final String companyName;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.website,
    required this.companyName,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      website: json['website'],
      companyName: json['company']?['name'] ?? '',
    );
  }
}

/// Demo page for API calls that fetch dummy user data
class ApiDemoPage extends StatefulWidget {
  const ApiDemoPage({super.key});

  @override
  State<ApiDemoPage> createState() => _ApiDemoPageState();
}

class _ApiDemoPageState extends State<ApiDemoPage> {
  late Dio _dio;
  bool _isLoading = false;
  List<User> _users = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _setupDio();
    logger.i('API Demo Page initialized');
  }

  void _setupDio() {
    _dio = Dio();
    // Add the awesome logger interceptor
    _dio.interceptors.add(FlutterAwesomeLoggerDioInterceptor());
    logger.d('Dio configured with AwesomeLoggerInterceptor for API demo');
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      logger.i('Fetching users from JSONPlaceholder API');

      final response =
          await _dio.get('https://jsonplaceholder.typicode.com/users');

      if (response.statusCode == 200) {
        final List<dynamic> userData = response.data;
        final users = userData.map((json) => User.fromJson(json)).toList();

        setState(() {
          _users = users;
          _isLoading = false;
        });

        logger.i('Successfully fetched ${users.length} users');
      } else {
        throw Exception('Failed to load users: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      logger.e('Failed to fetch users', error: e, stackTrace: stackTrace);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchSingleUser(int userId) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      logger.i('Fetching user with ID: $userId');

      final response =
          await _dio.get('https://jsonplaceholder.typicode.com/users/$userId');

      if (response.statusCode == 200) {
        final user = User.fromJson(response.data);

        setState(() {
          _users = [user];
          _isLoading = false;
        });

        logger.i('Successfully fetched user: ${user.name}');
      } else {
        throw Exception('Failed to load user: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      logger.e('Failed to fetch user $userId',
          error: e, stackTrace: stackTrace);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _createUser() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      logger.i('Creating a new user via POST request');

      final newUserData = {
        'name': 'John Doe',
        'email': 'john.doe@example.com',
        'phone': '+1-555-1234',
        'website': 'johndoe.com',
        'company': {'name': 'Example Corp'},
      };

      final response = await _dio.post(
        'https://jsonplaceholder.typicode.com/users',
        data: newUserData,
      );

      if (response.statusCode == 201) {
        final createdUser = User.fromJson(response.data);

        setState(() {
          _users = [createdUser];
          _isLoading = false;
        });

        logger.i('Successfully created user: ${createdUser.name}');
      } else {
        throw Exception('Failed to create user: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      logger.e('Failed to create user', error: e, stackTrace: stackTrace);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _simulateError() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      logger.w('Simulating API error with invalid endpoint');

      // This will cause a 404 error
      await _dio.get('https://jsonplaceholder.typicode.com/users/invalid');

      logger.i('Unexpected success - should have failed');
    } catch (e, stackTrace) {
      logger.e('Expected API error occurred', error: e, stackTrace: stackTrace);
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _clearResults() {
    setState(() {
      _users = [];
      _error = null;
    });
    logger.i('Cleared API demo results');
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Text(
                    user.id.toString(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        user.email,
                        style: TextStyle(
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.phone, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(user.phone),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.web, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(user.website),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(user.companyName),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Demo - Users'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_users.isNotEmpty || _error != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearResults,
              tooltip: 'Clear Results',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🌐 API Call Demo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This page demonstrates various API calls with automatic logging using Flutter Awesome Logger.',
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '• GET requests to fetch users\n'
                        '• POST requests to create users\n'
                        '• Error handling and logging\n'
                        '• All requests are automatically logged',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'API Actions:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // API Action Buttons
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _fetchUsers,
                    icon: const Icon(Icons.group),
                    label: const Text('Fetch All Users'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : () => _fetchSingleUser(1),
                    icon: const Icon(Icons.person),
                    label: const Text('Fetch User #1'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _createUser,
                    icon: const Icon(Icons.add),
                    label: const Text('Create User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _isLoading ? null : _simulateError,
                    icon: const Icon(Icons.error),
                    label: const Text('Simulate Error'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),

              // Loading indicator
              if (_isLoading) ...[
                const SizedBox(height: 24),
                const Center(
                  child: Column(
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Making API call...'),
                    ],
                  ),
                ),
              ],

              // Error display
              if (_error != null) ...[
                const SizedBox(height: 24),
                Card(
                  color: Colors.red[50],
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.error, color: Colors.red),
                            SizedBox(width: 8),
                            Text(
                              'API Error',
                              style: TextStyle(
                                color: Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              // Results display
              if (_users.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Results (${_users.length} user${_users.length == 1 ? '' : 's'}):',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                ..._users.map(_buildUserCard),
              ],

              const SizedBox(height: 24),
              Card(
                color: Colors.blue[50],
                child: const Padding(
                  padding: EdgeInsets.all(12.0),
                  child: Text(
                    '💡 Tip: Check the logger to see detailed API request/response logs for all these calls!',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
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
