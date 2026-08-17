import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/auth_result.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _auth = AuthService.instance;
  final LocalAuthentication _localAuth = LocalAuthentication();
  final Connectivity _connectivity = Connectivity();

  AuthState _state = AuthState.initial;
  AuthError? _lastError;
  int _failedAttempts = 0;
  DateTime? _lockUntil;
  bool _isOnline = true;
  bool _biometricAvailable = false;
  bool _isFirstLogin = false;

  AuthState get state => _state;
  AuthError? get lastError => _lastError;
  int get failedAttempts => _failedAttempts;
  bool get isLocked =>
      _lockUntil != null && DateTime.now().isBefore(_lockUntil!);
  bool get isOnline => _isOnline;
  bool get biometricAvailable => _biometricAvailable;
  bool get isFirstLogin => _isFirstLogin;
  bool get isAuthenticated => _auth.isAuthenticated;

  int get lockSecondsRemaining {
    if (_lockUntil == null) return 0;
    final remaining = _lockUntil!.difference(DateTime.now()).inSeconds;
    return remaining > 0 ? remaining : 0;
  }

  int get attemptsRemaining => (5 - _failedAttempts).clamp(0, 5);

  /// Unica fonte di verità per "dove andare dopo l'autenticazione" — legge
  /// welly_welcomed da SharedPreferences invece di fidarsi del flag
  /// isFirstLogin (FlutterSecureStorage, `bw_is_first_login`), che vive in
  /// uno storage separato e poteva disallinearsi da quello che SplashScreen
  /// usa per la stessa decisione: risultato, primo login mostrava il
  /// carosello di benvenuto ma un login successivo poteva ripartire dal
  /// configuratore a 5 fasi, che invece è ora un percorso facoltativo
  /// raggiungibile dalla sezione Abitudini, non un passaggio obbligato.
  Future<AuthNavigation> _postAuthNavigation() async {
    final prefs = await SharedPreferences.getInstance();
    final wellyWelcomed = prefs.getBool('welly_welcomed') ?? false;
    return wellyWelcomed ? AuthNavigation.toHome : AuthNavigation.toWelcome;
  }

  Future<void> init() async {
    // FIX: connectivity_plus 6.x restituisce List<ConnectivityResult>
    _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> results) {
      _isOnline = results.isNotEmpty &&
          results.any((r) => r != ConnectivityResult.none);
      notifyListeners();
    });

    final results = await _connectivity.checkConnectivity();
    // FIX: checkConnectivity restituisce List in v6.x
    _isOnline = results.isNotEmpty &&
        results.any((r) => r != ConnectivityResult.none);

    try {
      _biometricAvailable = await _localAuth.canCheckBiometrics &&
          await _localAuth.isDeviceSupported();
    } catch (_) {
      _biometricAvailable = false;
    }

    await _checkSession();
  }

  Future<void> _checkSession() async {
    _setState(AuthState.checkingSession);
    try {
      final status = await AuthService.instance
          .checkSession()
          .timeout(const Duration(seconds: 4));

      switch (status) {
        case AuthSessionStatus.firstOpen:
          _setState(AuthState.unauthenticated,
              navigate: AuthNavigation.toRegister);
        case AuthSessionStatus.noSession:
          _setState(AuthState.unauthenticated,
              navigate: AuthNavigation.toLogin);
        case AuthSessionStatus.valid:
          _isFirstLogin = false;
          _setState(AuthState.authenticated,
              navigate: await _postAuthNavigation());
        case AuthSessionStatus.validFirstLogin:
          _isFirstLogin = true;
          _setState(AuthState.authenticated,
              navigate: await _postAuthNavigation());
        case AuthSessionStatus.expired:
          _setState(AuthState.unauthenticated,
              navigate: AuthNavigation.toLogin);
      }
    } on TimeoutException {
      _setState(AuthState.unauthenticated, navigate: AuthNavigation.toLogin);
    }
  }

  Future<void> loginWithEmail({
    required String email,
    required String password,
  }) async {
    if (isLocked) return;
    if (!_isOnline) {
      _setError(AuthError.offline);
      return;
    }
    _setState(AuthState.loading);
    final result =
        await _auth.loginWithEmail(email: email, password: password);
    await _handleAuthResult(result);
  }

  Future<void> loginWithGoogle() async {
    if (!_isOnline) {
      _setError(AuthError.offline);
      return;
    }
    _setState(AuthState.loading);
    final result = await _auth.loginWithGoogle();
    await _handleAuthResult(result);
  }

  Future<void> loginWithApple() async {
    if (!_isOnline) {
      _setError(AuthError.offline);
      return;
    }
    _setState(AuthState.loading);
    final result = await _auth.loginWithApple();
    await _handleAuthResult(result);
  }

  Future<void> loginWithBiometric() async {
    if (!_biometricAvailable) return;
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Accedi a Be Well',
        options: const AuthenticationOptions(biometricOnly: true),
      );
      if (authenticated) {
        final status = await _auth.checkSession();
        if (status == AuthSessionStatus.valid ||
            status == AuthSessionStatus.validFirstLogin) {
          _isFirstLogin = status == AuthSessionStatus.validFirstLogin;
          _setState(
            AuthState.authenticated,
            navigate: await _postAuthNavigation(),
          );
        }
      }
    } catch (_) {
      _setError(AuthError.serverError);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    if (!_isOnline) {
      _setError(AuthError.offline);
      return;
    }
    _setState(AuthState.loading);
    final result =
        await _auth.register(name: name, email: email, password: password);
    if (result.success) {
      _setState(AuthState.emailVerificationPending);
    } else {
      _setError(result.error!);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    if (!_isOnline) {
      _setError(AuthError.offline);
      return;
    }
    _setState(AuthState.loading);
    await _auth.sendPasswordReset(email);
    _setState(AuthState.passwordResetSent);
  }

  Future<void> logout() async {
    await _auth.logout();
    _failedAttempts = 0;
    _lockUntil = null;
    _isFirstLogin = false;
    _setState(AuthState.unauthenticated, navigate: AuthNavigation.toLogin);
  }

  Future<void> _handleAuthResult(AuthResult result) async {
    if (result.success) {
      _failedAttempts = 0;
      _lockUntil = null;
      _isFirstLogin = result.isFirstLogin;
      _setState(
        AuthState.authenticated,
        navigate: await _postAuthNavigation(),
      );
    } else {
      if (result.error == AuthError.invalidCredentials) {
        _failedAttempts++;
        if (_failedAttempts >= 5) {
          _lockUntil =
              DateTime.now().add(const Duration(minutes: 15));
          _setState(AuthState.locked);
          Timer(const Duration(minutes: 15), _unlock);
          return;
        }
      }
      _setError(result.error!);
    }
  }

  void _unlock() {
    _lockUntil = null;
    _failedAttempts = 0;
    _setState(AuthState.unauthenticated);
  }

  void _setState(AuthState newState, {AuthNavigation? navigate}) {
    _state = newState;
    _pendingNavigation = navigate;
    _lastError = null;
    notifyListeners();
  }

  void _setError(AuthError error) {
    _lastError = error;
    _state = AuthState.error;
    notifyListeners();
  }

  void clearError() {
    _lastError = null;
    if (_state == AuthState.error) {
      _state = AuthState.unauthenticated;
    }
    notifyListeners();
  }

  AuthNavigation? _pendingNavigation;
  AuthNavigation? get pendingNavigation => _pendingNavigation;

  void consumeNavigation() {
    _pendingNavigation = null;
  }
}

enum AuthState {
  initial,
  checkingSession,
  loading,
  authenticated,
  unauthenticated,
  emailVerificationPending,
  passwordResetSent,
  locked,
  error,
}

enum AuthNavigation {
  toLogin,
  toRegister,
  toHome,
  /// Carosello di benvenuto "Be Well" (`/welly-welcome`) — il configuratore
  /// a 5 fasi NON fa più parte del flusso post-auth: è facoltativo e si
  /// raggiunge dalla sezione Abitudini dopo il primo sblocco.
  toWelcome,
}
