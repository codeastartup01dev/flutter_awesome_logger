import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_awesome_logger/flutter_awesome_logger.dart';

import '../models/user.dart';
import 'user_state.dart';

/// Global logger instance
final logger = FlutterAwesomeLogger.loggingUsingLogger;

/// Cubit for managing user data with API calls and mock fallback
class UserCubit extends Cubit<UserState> {
  final Dio _dio;

  UserCubit(this._dio) : super(UserInitial());

  /// Fetch all users from JSONPlaceholder API with fallback to mock data
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

  /// Fetch a specific user by ID from JSONPlaceholder API with fallback
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

  /// Load mock data directly (useful for testing offline scenarios)
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

  /// Clear all users and return to initial state
  void clearUsers() {
    logger.i('UserCubit: Clearing users');
    emit(UserInitial());
  }

  /// Private method to use mock data for a specific user ID
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

  /// Create mock users using actual JSONPlaceholder data as fallback
  List<User> _createMockUsers() {
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
}
