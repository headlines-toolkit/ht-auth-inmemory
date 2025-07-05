# ht_auth_inmemory

![coverage: percentage](https://img.shields.io/badge/coverage-XX-green)
[![style: very good analysis](https://img.shields.io/badge/style-very_good_analysis-B22C89.svg)](https://pub.dev/packages/very_good_analysis)
[![License: PolyForm Free Trial](https://img.shields.io/badge/License-PolyForm%20Free%20Trial-blue)](https://polyformproject.org/licenses/free-trial/1.0.0)

An in-memory implementation of the `HtAuthClient` interface. This package provides a mock authentication client that operates entirely on in-memory data, making it suitable for demonstration purposes, local development, and testing without requiring a live backend.

### Getting Started

Add the following to your `pubspec.yaml` dependencies:

```yaml
dependencies:
  ht_auth_inmemory:
    git:
      url: https://github.com/headlines-toolkit/ht-auth-inmemory
```

### Features

This package implements the `HtAuthClient` interface, providing the following in-memory simulated authentication methods:

*   `authStateChanges`: A stream that emits the current authenticated `User` or `null` on state changes.
*   `getCurrentUser`: Retrieves the currently authenticated `User`.
*   `requestSignInCode`: Simulates sending a sign-in code to an email. This method supports an optional `isDashboardLogin` flag. When `true`, it simulates a privileged flow where only `admin@example.com` is allowed to request a code; otherwise, it throws an `UnauthorizedException`.
*   `verifySignInCode`: Simulates verifying a sign-in code and authenticating a user. This method also supports an optional `isDashboardLogin` flag. When `true`, it simulates a privileged flow where only `admin@example.com` can successfully verify a code (throwing a `NotFoundException` for other emails) and the authenticated user is assigned the `UserRoles.admin` role.
*   `signInAnonymously`: Simulates signing in a user anonymously.
*   `signOut`: Simulates signing out the current user.
*   `currentToken`: A custom getter to retrieve the simulated authentication token.

### Usage

Here's how you can use `HtAuthInmemory` in your application for demo or testing environments:

```dart
import 'package:ht_auth_inmemory/ht_auth_inmemory.dart';
import 'package:ht_shared/ht_shared.dart'; // For User and AuthSuccessResponse

void main() async {
  final authClient = HtAuthInmemory();

  // Listen to authentication state changes
  authClient.authStateChanges.listen((user) {
    if (user != null) {
      print('User authenticated: ${user.email ?? 'Anonymous'}');
    } else {
      print('User signed out.');
    }
  });

  // Simulate anonymous sign-in
  try {
    final anonymousAuthResponse = await authClient.signInAnonymously();
    print('Signed in anonymously. User ID: ${anonymousAuthResponse.user.id}');
    print('Current Token: ${authClient.currentToken}');
  } catch (e) {
    print('Anonymous sign-in failed: $e');
  }

  // Simulate email sign-in flow
  const testEmail = 'test@example.com';
  try {
    await authClient.requestSignInCode(testEmail);
    print('Sign-in code requested for $testEmail');

    // In a real app, the user would input the code received via email
    const code = '123456'; // Hardcoded code for in-memory demo

    final verifiedAuthResponse =
        await authClient.verifySignInCode(testEmail, code);
    print('Verified sign-in for ${verifiedAuthResponse.user.email}');
    print('Current Token: ${authClient.currentToken}');
  } on InvalidInputException catch (e) {
    print('Invalid input: ${e.message}');
  } on AuthenticationException catch (e) {
    print('Authentication failed: ${e.message}');
  } catch (e) {
    print('Sign-in failed: $e');
  }

  // Get current user
  final currentUser = await authClient.getCurrentUser();
  print('Current user (after operations): ${currentUser?.email}');

  // Simulate sign-out
  try {
    await authClient.signOut();
    print('User signed out successfully.');
  } catch (e) {
    print('Sign-out failed: $e');
  }
}
```

### License

This package is licensed under the [PolyForm Free Trial](LICENSE). Please review the terms before use.
