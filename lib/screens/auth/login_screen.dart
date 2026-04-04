import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../models/auth_result.dart';
import '../../utils/validators.dart';
import '../../widgets/auth/auth_widgets.dart';

/// S-02 · Login Screen
/// Per utenti con account esistente.
/// Stati: default → focused → loading → error (1-4 tentativi) → locked → success
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _formKey = GlobalKey<FormState>();

  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _emailCtrl.text.trim().isNotEmpty &&
      _passwordCtrl.text.isNotEmpty;

  void _validateAndSubmit() {
    // Valida campi
    final emailErr = BwValidators.email(_emailCtrl.text);
    final passErr = BwValidators.loginPassword(_passwordCtrl.text);
    setState(() {
      _emailError = emailErr;
      _passwordError = passErr;
    });
    if (emailErr != null || passErr != null) return;

    context.read<AuthProvider>().loginWithEmail(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Reazione alla navigazione
        if (auth.pendingNavigation != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleNavigation(context, auth);
          });
        }

        final isLoading = auth.state == AuthState.loading;
        final isLocked = auth.state == AuthState.locked;

        return Scaffold(
          backgroundColor: const Color(0xFF0B1929),
          body: SafeArea(
            child: Column(
              children: [
                // Banner offline
                if (!auth.isOnline) const OfflineBanner(),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header
                        _buildHeader(),
                        const SizedBox(height: 36),

                        // Account bloccato — sostituisce il form
                        if (isLocked)
                          AccountLockedWidget(
                            initialSecondsRemaining: auth.lockSecondsRemaining,
                            onUnlock: () => auth.clearError(),
                          )
                        else ...[
                          // Bottoni SSO
                          SsoButtonRow(
                            enabled: !isLoading && auth.isOnline,
                            onGoogle: () => auth.loginWithGoogle(),
                            onApple: () => auth.loginWithApple(),
                          ),
                          const SizedBox(height: 20),
                          const OrDivider(),
                          const SizedBox(height: 20),

                          // Messaggio errore globale
                          if (auth.state == AuthState.error && auth.lastError != null)
                            _ErrorBanner(
                              message: auth.lastError!.userMessage,
                              attemptsRemaining: auth.attemptsRemaining,
                              onDismiss: auth.clearError,
                            ),

                          // Form email
                          BwEmailField(
                            controller: _emailCtrl,
                            errorText: _emailError,
                            enabled: !isLoading,
                            focusNode: _emailFocus,
                            onEditingComplete: () =>
                                FocusScope.of(context).requestFocus(_passwordFocus),
                          ),
                          const SizedBox(height: 14),

                          // Form password
                          BwPasswordField(
                            controller: _passwordCtrl,
                            errorText: _passwordError,
                            enabled: !isLoading,
                            focusNode: _passwordFocus,
                            onEditingComplete: _canSubmit ? _validateAndSubmit : null,
                          ),
                          const SizedBox(height: 8),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.of(context)
                                  .pushNamed('/forgot-password'),
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 0, vertical: 4),
                              ),
                              child: const Text(
                                'Password dimenticata?',
                                style: TextStyle(
                                  color: Color(0xFF1E9E87),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Bottone login
                          BwAuthButton(
                            label: 'Accedi',
                            isLoading: isLoading,
                            onPressed: (!isLoading && auth.isOnline)
                                ? _validateAndSubmit
                                : null,
                          ),

                          // Biometrico (se disponibile)
                          if (auth.biometricAvailable && !isLoading) ...[
                            const SizedBox(height: 14),
                            _BiometricButton(
                              onPressed: () => auth.loginWithBiometric(),
                            ),
                          ],

                          const SizedBox(height: 32),

                          // Link registrazione
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.of(context)
                                  .pushReplacementNamed('/register'),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.4),
                                    fontSize: 14,
                                  ),
                                  children: const [
                                    TextSpan(text: 'Non hai un account? '),
                                    TextSpan(
                                      text: 'Creane uno',
                                      style: TextStyle(
                                        color: Color(0xFF1E9E87),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E9E87), Color(0xFF3A7BD5)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Text('🌿', style: TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'Be Well',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),
        const Text(
          'Bentornato',
          style: TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Accedi per continuare il tuo percorso',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 15,
          ),
        ),
      ],
    );
  }

  void _handleNavigation(BuildContext context, AuthProvider auth) {
    final nav = auth.pendingNavigation;
    auth.consumeNavigation();
    switch (nav) {
      case AuthNavigation.toHome:
        context.read<AppProvider>().onLoginComplete();
        Navigator.of(context).pushReplacementNamed('/home');
      case AuthNavigation.toOnboarding:
        context.read<AppProvider>().onLoginComplete();
        Navigator.of(context).pushReplacementNamed('/onboarding');
      default:
        break;
    }
  }
}

// ── Widgets locali ──────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  final String message;
  final int attemptsRemaining;
  final VoidCallback onDismiss;

  const _ErrorBanner({
    required this.message,
    required this.attemptsRemaining,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFE05640).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE05640).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE05640), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFFE05640),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (attemptsRemaining > 0 && attemptsRemaining < 5)
                  Text(
                    '$attemptsRemaining tentativi rimanenti prima del blocco',
                    style: TextStyle(
                      color: const Color(0xFFE05640).withOpacity(0.7),
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(
              Icons.close,
              size: 16,
              color: const Color(0xFFE05640).withOpacity(0.6),
            ),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

class _BiometricButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _BiometricButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: const Icon(
          Icons.fingerprint,
          color: Color(0xFF1E9E87),
          size: 22,
        ),
        label: const Text(
          'Accedi con biometria',
          style: TextStyle(
            color: Color(0xFF1E9E87),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}





