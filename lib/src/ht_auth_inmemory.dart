import 'dart:async';

import 'package:ht_auth_client/ht_auth_client.dart';
import 'package:ht_shared/ht_shared.dart';
import 'package:logging/logging.dart';
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
  HtAuthInmemory({this.initialUser, this.initialToken, Logger? logger})
    : _logger = logger ?? Logger('HtAuthInmemory') {
    _logger.fine(
      'Initializing with initialUser: $initialUser, '
      'initialToken: $initialToken',
    );
    _currentUser = initialUser;
    _currentToken = initialToken;
    if (_currentUser != null) {
      _authStateController.add(_currentUser);
      _logger.finer('Added initial user to authStateController.');
    }
    _logger.fine('Initialization complete.');
  }
  final Logger _logger;
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
    _logger.finer('authStateChanges getter called.');
    return _authStateController.stream;
  }

  /// Returns the current authentication token.
  ///
  /// This is a custom getter for the in-memory client to allow the
  /// repository to retrieve the token after successful authentication.
  String? get currentToken {
    _logger.finer('currentToken getter called. Returning $_currentToken');
    return _currentToken;
  }

  @override
  Future<User?> getCurrentUser() async {
    _logger.fine('getCurrentUser called.');
    await Future<void>.delayed(const Duration(milliseconds: 100));
    _logger.fine('getCurrentUser returning $_currentUser');
    return _currentUser;
  }

  @override
  Future<void> requestSignInCode(
    String email, {
    bool isDashboardLogin = false,
  }) async {
    _logger.fine(
      'requestSignInCode called for email: $email, '
      'isDashboardLogin: $isDashboardLogin',
    );
    if (!email.contains('@') || !email.contains('.')) {
      _logger.warning(
        'Invalid email format for $email. Throwing InvalidInputException.',
      );
      throw const InvalidInputException('Invalid email format.');
    }

    if (isDashboardLogin && email != 'admin@example.com') {
      _logger.warning(
        'Dashboard login requested for non-admin email $email. '
        'Throwing UnauthorizedException.',
      );
      throw const UnauthorizedException(
        'Only admin@example.com can access the dashboard.',
      );
    }

    _pendingCodes[email] = '123456'; // Hardcoded for demo
    _logger.info(
      'Generated code 123456 for $email. Pending codes: $_pendingCodes',
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _logger.fine('requestSignInCode completed for email: $email');
  }

  @override
  Future<AuthSuccessResponse> verifySignInCode(
    String email,
    String code, {
    bool isDashboardLogin = false,
  }) async {
    _logger.fine(
      'verifySignInCode called for email: $email, code: $code, '
      '$code, isDashboardLogin: $isDashboardLogin',
    );
    if (!email.contains('@') || !email.contains('.')) {
      _logger.warning(
        'Invalid email format for $email. Throwing InvalidInputException.',
      );
      throw const InvalidInputException('Invalid email format.');
    }

    if (isDashboardLogin && email != 'admin@example.com') {
      _logger.warning(
        'Dashboard login verification for non-admin email $email. '
        'Throwing NotFoundException.',
      );
      throw const NotFoundException('User not found for dashboard access.');
    }

    if (code != _pendingCodes[email]) {
      _logger.warning(
        'Invalid or expired code for $email. Expected: '
        '${_pendingCodes[email]}, Got: $code. Throwing AuthenticationException.',
      );
      throw const AuthenticationException('Invalid or expired code.');
    }

    final user = User(
      id: _uuid.v4(),
      email: email,
      appRole: isDashboardLogin
          ? AppUserRole.premiumUser
          : AppUserRole.standardUser,
      dashboardRole: isDashboardLogin
          ? DashboardUserRole.admin
          : DashboardUserRole.none,
      createdAt: DateTime.now(),
      feedActionStatus: Map.fromEntries(
        FeedActionType.values.map(
          (type) =>
              MapEntry(type, const UserFeedActionStatus(isCompleted: false)),
        ),
      ),
    );
    _currentUser = user;
    _currentToken = _uuid.v4();
    _authStateController.add(_currentUser);
    _pendingCodes.remove(email);

    _logger.info(
      'User $email verified. New user: $_currentUser, token: $_currentToken',
    );
    _logger.finer('Pending codes after verification: $_pendingCodes');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _logger.fine('verifySignInCode completed for email: $email');
    return AuthSuccessResponse(user: user, token: _currentToken!);
  }

  @override
  Future<AuthSuccessResponse> signInAnonymously() async {
    _logger.fine('signInAnonymously called.');
    final user = User(
      id: _uuid.v4(),
      email: 'anonymous@example.com',
      appRole: AppUserRole.guestUser,
      dashboardRole: DashboardUserRole.none,
      createdAt: DateTime.now(),
      feedActionStatus: Map.fromEntries(
        FeedActionType.values.map(
          (type) =>
              MapEntry(type, const UserFeedActionStatus(isCompleted: false)),
        ),
      ),
    );
    _currentUser = user;
    _currentToken = _uuid.v4();
    _authStateController.add(_currentUser);

    _logger.info(
      'Signed in anonymously. User: $_currentUser, token: $_currentToken',
    );
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _logger.fine('signInAnonymously completed.');
    return AuthSuccessResponse(user: user, token: _currentToken!);
  }

  @override
  Future<void> signOut() async {
    _logger.fine('signOut called.');
    _currentUser = null;
    _currentToken = null;
    _authStateController.add(null);
    _pendingCodes.clear();

    _logger.info(
      'User signed out. Current user: $_currentUser, token: $_currentToken',
    );
    _logger.finer('Pending codes after sign out: $_pendingCodes');
    await Future<void>.delayed(const Duration(milliseconds: 500));
    _logger.fine('signOut completed.');
  }
}
