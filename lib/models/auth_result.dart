import 'package:firebase_auth/firebase_auth.dart';
import '../l10n/app_localizations.dart';

class AuthResult {
  final bool success;
  final User? user;
  final bool isFirstLogin;
  final AuthError? error;

  const AuthResult._({
    required this.success,
    this.user,
    this.isFirstLogin = false,
    this.error,
  });

  factory AuthResult.success({
    required User? user,
    required bool isFirstLogin,
  }) =>
      AuthResult._(success: true, user: user, isFirstLogin: isFirstLogin);

  factory AuthResult.failure(AuthError error) =>
      AuthResult._(success: false, error: error);

  bool get isFailure => !success;
}

enum AuthError {
  invalidCredentials,
  tooManyAttempts,
  emailAlreadyExists,
  offline,
  timeout,
  serverError,
  cancelled,
  accountDisabled,
}

extension AuthErrorMessage on AuthError {
  /// Messaggio localizzato per l'utente — richiede [BwStrings] perché
  /// l'enum stesso non ha accesso al BuildContext/locale corrente.
  String localizedMessage(BwStrings s) {
    switch (this) {
      case AuthError.invalidCredentials: return s.errorInvalidCredentials;
      case AuthError.tooManyAttempts:    return s.errorTooManyAttempts;
      case AuthError.emailAlreadyExists: return s.errorEmailInUse;
      case AuthError.offline:            return s.errorNetwork;
      case AuthError.timeout:            return s.errorTimeout;
      case AuthError.serverError:        return s.errorGeneral;
      case AuthError.cancelled:          return s.errorCancelled;
      case AuthError.accountDisabled:    return s.errorAccountDisabled;
    }
  }
}
