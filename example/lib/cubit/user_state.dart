import '../models/user.dart';

/// Base class for all user states
abstract class UserState {}

/// Initial state when no users are loaded
class UserInitial extends UserState {}

/// Loading state when fetching users
class UserLoading extends UserState {}

/// Success state when users are loaded
class UserLoaded extends UserState {
  final List<User> users;

  UserLoaded(this.users);

  @override
  String toString() => 'UserLoaded(${users.length} users)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserLoaded &&
        other.users.length == users.length &&
        other.users.every((user) => users.contains(user));
  }

  @override
  int get hashCode => users.hashCode;
}

/// Error state when user loading fails
class UserError extends UserState {
  final String message;

  UserError(this.message);

  @override
  String toString() => 'UserError(message: $message)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserError && other.message == message;
  }

  @override
  int get hashCode => message.hashCode;
}
