import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth_result.dart';

/// Unico punto di contatto con Firebase Auth.
/// Tutte le schermate passano da qui — mai chiamare FirebaseAuth direttamente.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _firebase = FirebaseAuth.instance;
  final GoogleSignIn _google = GoogleSignIn();
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  // ── Chiavi secure storage ──────────────────────────────────────────────
  static const _kUserId = 'bw_user_id';
  static const _kIsFirstLogin = 'bw_is_first_login';
  static const _kInstallFlag = 'bw_installed';

  // ── Stream sessione ────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _firebase.authStateChanges();
  User? get currentUser => _firebase.currentUser;
  bool get isAuthenticated => _firebase.currentUser != null;

  // ── Sessione ───────────────────────────────────────────────────────────

  /// Ritorna AuthSessionStatus in base allo stato corrente.
  Future<AuthSessionStatus> checkSession() async {
    final installed = await _storage.read(key: _kInstallFlag);
    if (installed == null) {
      // Prima apertura assoluta
      await _storage.write(key: _kInstallFlag, value: 'true');
      return AuthSessionStatus.firstOpen;
    }

    final user = _firebase.currentUser;
    if (user == null) return AuthSessionStatus.noSession;

    // Prova a rinfrescare il token silenziosamente
    try {
      await user.getIdToken(true);
      final isFirst = await _storage.read(key: _kIsFirstLogin);
      return isFirst == 'true'
          ? AuthSessionStatus.validFirstLogin
          : AuthSessionStatus.valid;
    } catch (_) {
      return AuthSessionStatus.expired;
    }
  }

  // ── Login email/password ───────────────────────────────────────────────

  Future<AuthResult> loginWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _firebase
          .signInWithEmailAndPassword(email: email, password: password)
          .timeout(const Duration(seconds: 10));

      final isFirst = await _isFirstLogin(cred.user!.uid);
      return AuthResult.success(
        user: cred.user!,
        isFirstLogin: isFirst,
      );
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } on TimeoutException {
      return AuthResult.failure(AuthError.timeout);
    } catch (_) {
      return AuthResult.failure(AuthError.serverError);
    }
  }

  // ── Google SSO ─────────────────────────────────────────────────────────

  Future<AuthResult> loginWithGoogle() async {
    try {
      final googleUser = await _google.signIn();
      if (googleUser == null) return AuthResult.failure(AuthError.cancelled);

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final cred = await _firebase.signInWithCredential(credential);
      final isFirst = await _isFirstLogin(cred.user!.uid);
      return AuthResult.success(user: cred.user!, isFirstLogin: isFirst);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (_) {
      return AuthResult.failure(AuthError.serverError);
    }
  }

  // ── Apple SSO ─────────────────────────────────────────────────────────

  Future<AuthResult> loginWithApple() async {
    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      final cred = await _firebase.signInWithCredential(oauthCredential);
      final isFirst = await _isFirstLogin(cred.user!.uid);
      return AuthResult.success(user: cred.user!, isFirstLogin: isFirst);
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return AuthResult.failure(AuthError.cancelled);
      }
      return AuthResult.failure(AuthError.serverError);
    } catch (_) {
      return AuthResult.failure(AuthError.serverError);
    }
  }

  // ── Registrazione ──────────────────────────────────────────────────────

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _firebase.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // Imposta display name
      await cred.user!.updateDisplayName(name);

      // Invia email di verifica
      await cred.user!.sendEmailVerification();

      // Marca come primo login
      await _storage.write(key: _kIsFirstLogin, value: 'true');
      await _storage.write(key: _kUserId, value: cred.user!.uid);

      return AuthResult.success(user: cred.user!, isFirstLogin: true);
    } on FirebaseAuthException catch (e) {
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (_) {
      return AuthResult.failure(AuthError.serverError);
    }
  }

  // ── Reset password ─────────────────────────────────────────────────────

  Future<AuthResult> sendPasswordReset(String email) async {
    try {
      await _firebase.sendPasswordResetEmail(email: email);
      return AuthResult.success(user: null, isFirstLogin: false);
    } on FirebaseAuthException catch (e) {
      // Per sicurezza, non rivelare se l'email esiste o meno
      if (e.code == 'user-not-found') {
        return AuthResult.success(user: null, isFirstLogin: false);
      }
      return AuthResult.failure(_mapFirebaseError(e));
    } catch (_) {
      return AuthResult.failure(AuthError.serverError);
    }
  }

  // ── Logout ─────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _google.signOut();
    await _firebase.signOut();
    // NON cancellare _kInstallFlag — serve per distinguere primo avvio
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Future<bool> _isFirstLogin(String uid) async {
    final stored = await _storage.read(key: _kIsFirstLogin);
    if (stored == 'true') {
      // Consumato — il prossimo login non sarà più "first"
      await _storage.write(key: _kIsFirstLogin, value: 'false');
      await _storage.write(key: _kUserId, value: uid);
      return true;
    }
    return false;
  }

  AuthError _mapFirebaseError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return AuthError.invalidCredentials;
      case 'too-many-requests':
        return AuthError.tooManyAttempts;
      case 'email-already-in-use':
        return AuthError.emailAlreadyExists;
      case 'network-request-failed':
        return AuthError.offline;
      case 'user-disabled':
        return AuthError.accountDisabled;
      default:
        return AuthError.serverError;
    }
  }
}

// ── Enums e status ─────────────────────────────────────────────────────────

enum AuthSessionStatus {
  firstOpen,
  noSession,
  valid,
  validFirstLogin,
  expired,
}
