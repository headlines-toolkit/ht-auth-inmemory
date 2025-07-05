// ignore_for_file: avoid_print, lines_longer_than_80_chars

import 'dart:async';

import 'package:ht_auth_client/ht_auth_client.dart';
import 'package:ht_shared/ht_shared.dart';
import 'package:uuid/uuid.dart';

/// {@template ht_auth_inmemory}
/// An in-memory implementation of the [HtAuthClient] interface for
/// demonstration and testing purposes.
///
/// This client simulates authentication flows without requiring a backend,
/// managing user and token states purely in memory.
/// {@endtemplate}
class HtAuthInmemory implements HtAuthClient {
  /// {@macro ht_auth_inmemory}
  HtAuthInmemory({this.initialUser, this.initialToken}) {
    print(
      'DEBUG: HtAuthInmemory Initializing with initialUser: $initialUser, '
      'initialToken: $initialToken',
    );
    _currentUser = initialUser;
    _currentToken = initialToken;
    if (_currentUser != null) {
      _authStateController.add(_currentUser);
      print('DEBUG: HtAuthInmemory Added initial user to authStateController.');
    }
    print('DEBUG: HtAuthInmemory Initialization complete.');
  }

  final Uuid _uuid = const Uuid();

  /// The initial user to set for demonstration purposes.
  final User? initialUser;

  /// The initial token to set for demonstration purposes.
  final String? initialToken;

  final StreamController<User?> _authStateController =
      StreamController<User?>.broadcast();

  User? _currentUser;
  String? _currentToken;
  final Map<String, String> _pendingCodes = {};

  @override
  Stream<User?> get authStateChanges {
    print('DEBUG: HtAuthInmemory authStateChanges getter called.');
    return _authStateController.stream;
  }

  /// Returns the current authentication token.
  ///
  /// This is a custom getter for the in-memory client to allow the
  /// repository to retrieve the token after successful authentication.
  String? get currentToken {
    print(
      'DEBUG: HtAuthInmemory currentToken getter called. Returning $_currentToken',
    );
    return _currentToken;
  }

  @override
  Future<User?> getCurrentUser() async {
    print('DEBUG: HtAuthInmemory getCurrentUser called.');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    print('DEBUG: HtAuthInmemory getCurrentUser returning $_currentUser');
    return _currentUser;
  }

  @override
  Future<void> requestSignInCode(
    String email, {
    bool isDashboardLogin = false,
  }) async {
    print('DEBUG: HtAuthInmemory requestSignInCode called for email: $email, '
        'isDashboardLogin: $isDashboardLogin');
    if (!email.contains('@') || !email.contains('.')) {
      print(
        'DEBUG: HtAuthInmemory Invalid email format for $email. Throwing '
        'InvalidInputException.',
      );
      throw const InvalidInputException('Invalid email format.');
    }

    if (isDashboardLogin && email != 'admin@example.com') {
      print(
        'DEBUG: HtAuthInmemory Dashboard login requested for non-admin email '
        '$email. Throwing UnauthorizedException.',
      );
      throw const UnauthorizedException(
        'Only admin@example.com can access the dashboard.',
      );
    }

    // Simulate sending a code
    _pendingCodes[email] = '123456'; // Hardcoded for demo
    print(
      'DEBUG: HtAuthInmemory Generated code 123456 for $email. Pending codes: '
      '$_pendingCodes',
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
    print(
      'DEBUG: HtAuthInmemory requestSignInCode completed for email: $email',
    );
  }

  @override
  Future<AuthSuccessResponse> verifySignInCode(
    String email,
    String code, {
    bool isDashboardLogin = false,
  }) async {
    print(
      'DEBUG: HtAuthInmemory verifySignInCode called for email: $email, code: '
      '$code, isDashboardLogin: $isDashboardLogin',
    );
    if (!email.contains('@') || !email.contains('.')) {
      print(
        'DEBUG: HtAuthInmemory Invalid email format for $email. Throwing '
        'InvalidInputException.',
      );
      throw const InvalidInputException('Invalid email format.');
    }

    if (isDashboardLogin && email != 'admin@example.com') {
      print(
        'DEBUG: HtAuthInmemory Dashboard login verification for non-admin '
        'email $email. Throwing NotFoundException.',
      );
      throw const NotFoundException('User not found for dashboard access.');
    }

    if (code != _pendingCodes[email]) {
      print(
        'DEBUG: HtAuthInmemory Invalid or expired code for $email. Expected: '
        '${_pendingCodes[email]}, Got: $code. Throwing AuthenticationException.',
      );
      throw const AuthenticationException('Invalid or expired code.');
    }

    // Simulate user creation/login
    final user = User(
      id: _uuid.v4(),
      email: email,
      roles: [
        isDashboardLogin ? UserRoles.admin : UserRoles.standardUser,
      ],
    );
    _currentUser = user;
    _currentToken = _uuid.v4(); // Generate a new token
    _authStateController.add(_currentUser);
    _pendingCodes.remove(
      email,
    ); // Clear pending code after successful verification

    print(
      'DEBUG: HtAuthInmemory User $email verified. New user: $_currentUser, '
      'token: $_currentToken',
    );
    print(
      'DEBUG: HtAuthInmemory Pending codes after verification: $_pendingCodes',
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
    print('DEBUG: HtAuthInmemory verifySignInCode completed for email: $email');
    return AuthSuccessResponse(user: user, token: _currentToken!);
  }

  @override
  Future<AuthSuccessResponse> signInAnonymously() async {
    print('DEBUG: HtAuthInmemory signInAnonymously called.');
    final user = User(id: _uuid.v4(), roles: [UserRoles.guestUser]);
    _currentUser = user;
    _currentToken = _uuid.v4(); // Generate a new token
    _authStateController.add(_currentUser);

    print(
      'DEBUG: HtAuthInmemory Signed in anonymously. User: $_currentUser, token: $_currentToken',
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
    print('DEBUG: HtAuthInmemory signInAnonymously completed.');
    return AuthSuccessResponse(user: user, token: _currentToken!);
  }

  @override
  Future<void> signOut() async {
    print('DEBUG: HtAuthInmemory signOut called.');
    _currentUser = null;
    _currentToken = null;
    _authStateController.add(null);
    _pendingCodes.clear(); // Clear all pending codes on sign out

    print(
      'DEBUG: HtAuthInmemory User signed out. Current user: $_currentUser, token: $_currentToken',
    );
    print('DEBUG: HtAuthInmemory Pending codes after sign out: $_pendingCodes');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    print('DEBUG: HtAuthInmemory signOut completed.');
  }
}
