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
    _currentUser = initialUser;
    _currentToken = initialToken;
    if (_currentUser != null) {
      _authStateController.add(_currentUser);
    }
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
  Stream<User?> get authStateChanges => _authStateController.stream;

  /// Returns the current authentication token.
  ///
  /// This is a custom getter for the in-memory client to allow the
  /// repository to retrieve the token after successful authentication.
  String? get currentToken => _currentToken;

  @override
  Future<User?> getCurrentUser() async {
    return _currentUser;
  }

  @override
  Future<void> requestSignInCode(String email) async {
    if (!email.contains('@') || !email.contains('.')) {
      throw const InvalidInputException('Invalid email format.');
    }
    // Simulate sending a code
    _pendingCodes[email] = '123456'; // Hardcoded for demo
    await Future<void>.delayed(const Duration(milliseconds: 500));
  }

  @override
  Future<AuthSuccessResponse> verifySignInCode(
    String email,
    String code,
  ) async {
    if (!email.contains('@') || !email.contains('.')) {
      throw const InvalidInputException('Invalid email format.');
    }
    if (code != _pendingCodes[email]) {
      throw const AuthenticationException('Invalid or expired code.');
    }

    // Simulate user creation/login
    final user = User(
      id: _uuid.v4(),
      email: email,
      role: UserRole.standardUser,
    );
    _currentUser = user;
    _currentToken = _uuid.v4(); // Generate a new token
    _authStateController.add(_currentUser);
    _pendingCodes.remove(
      email,
    ); // Clear pending code after successful verification

    await Future<void>.delayed(const Duration(milliseconds: 500));
    return AuthSuccessResponse(user: user, token: _currentToken!);
  }

  @override
  Future<AuthSuccessResponse> signInAnonymously() async {
    final user = User(id: _uuid.v4(), role: UserRole.guestUser);
    _currentUser = user;
    _currentToken = _uuid.v4(); // Generate a new token
    _authStateController.add(_currentUser);

    await Future<void>.delayed(const Duration(milliseconds: 500));
    return AuthSuccessResponse(user: user, token: _currentToken!);
  }

  @override
  Future<void> signOut() async {
    _currentUser = null;
    _currentToken = null;
    _authStateController.add(null);
    _pendingCodes.clear(); // Clear all pending codes on sign out

    await Future<void>.delayed(const Duration(milliseconds: 500));
  }
}
