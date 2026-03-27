import 'package:firebase_auth/firebase_auth.dart';

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

// FIX: aggiunta extension con userMessage
extension AuthErrorMessage on AuthError {
  String get userMessage {
    switch (this) {
      case AuthError.invalidCredentials:
        return 'Email o password non corretti';
      case AuthError.tooManyAttempts:
        return 'Troppi tentativi. Account bloccato temporaneamente';
      case AuthError.emailAlreadyExists:
        return 'Esiste già un account con questa email';
      case AuthError.offline:
        return 'Nessuna connessione. Il login richiede internet';
      case AuthError.timeout:
        return 'Il server non risponde. Riprova tra poco';
      case AuthError.serverError:
        return 'Errore del server. Riprova tra poco';
      case AuthError.cancelled:
        return 'Accesso annullato';
      case AuthError.accountDisabled:
        return 'Account disabilitato. Contatta il supporto';
    }
  }
}
