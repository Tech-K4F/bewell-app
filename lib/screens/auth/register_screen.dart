import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/auth_result.dart';
import '../../utils/validators.dart';
import '../../widgets/auth/auth_widgets.dart';

/// S-03 · Registration Screen
/// Solo per nuovi utenti. Email + password o SSO one-tap.
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  String? _nameError;
  String? _emailError;
  String? _passwordError;
  bool _tosAccepted = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _nameCtrl.text.trim().isNotEmpty &&
      _emailCtrl.text.trim().isNotEmpty &&
      _passwordCtrl.text.length >= 8 &&
      _tosAccepted;

  void _validateAndSubmit() {
    final nameErr = BwValidators.name(_nameCtrl.text);
    final emailErr = BwValidators.email(_emailCtrl.text);
    final passErr = BwValidators.registerPassword(_passwordCtrl.text);

    setState(() {
      _nameError = nameErr;
      _emailError = emailErr;
      _passwordError = passErr;
    });

    if (nameErr != null || emailErr != null || passErr != null) return;

    context.read<AuthProvider>().register(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Navigazione verso verifica email
        if (auth.state == AuthState.emailVerificationPending) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacementNamed(
              '/email-verify',
              arguments: _emailCtrl.text.trim(),
            );
          });
        }

        // Navigazione da SSO
        if (auth.pendingNavigation != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleNavigation(context, auth);
          });
        }

        final isLoading = auth.state == AuthState.loading;

        return Scaffold(
          backgroundColor: const Color(0xFF0B1929),
          body: SafeArea(
            child: Column(
              children: [
                if (!auth.isOnline) const OfflineBanner(),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Back button
                        GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.arrow_back_ios,
                                color: Colors.white.withOpacity(0.4),
                                size: 16,
                              ),
                              Text(
                                'Accedi',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        const Text(
                          'Crea account',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Inizia il tuo percorso di benessere',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // SSO buttons
                        SsoButtonRow(
                          enabled: !isLoading && auth.isOnline,
                          onGoogle: () => auth.loginWithGoogle(),
                          onApple: () => auth.loginWithApple(),
                        ),
                        const SizedBox(height: 20),
                        const OrDivider(),
                        const SizedBox(height: 20),

                        // Errore globale
                        if (auth.state == AuthState.error && auth.lastError != null)
                          _buildErrorBanner(auth.lastError!.userMessage, auth),

                        // Nome
                        BwNameField(
                          controller: _nameCtrl,
                          errorText: _nameError,
                          enabled: !isLoading,
                          focusNode: _nameFocus,
                          onEditingComplete: () =>
                              FocusScope.of(context).requestFocus(_emailFocus),
                        ),
                        const SizedBox(height: 14),

                        // Email
                        BwEmailField(
                          controller: _emailCtrl,
                          errorText: _emailError,
                          enabled: !isLoading,
                          focusNode: _emailFocus,
                          onEditingComplete: () =>
                              FocusScope.of(context).requestFocus(_passwordFocus),
                        ),
                        const SizedBox(height: 14),

                        // Password con barra forza
                        BwPasswordField(
                          controller: _passwordCtrl,
                          errorText: _passwordError,
                          enabled: !isLoading,
                          focusNode: _passwordFocus,
                          showStrengthBar: true,
                          onEditingComplete: _canSubmit ? _validateAndSubmit : null,
                        ),
                        const SizedBox(height: 20),

                        // ToS checkbox
                        _TosCheckbox(
                          accepted: _tosAccepted,
                          onChanged: (v) => setState(() => _tosAccepted = v),
                        ),
                        const SizedBox(height: 24),

                        // Bottone registrazione
                        BwAuthButton(
                          label: 'Crea account',
                          isLoading: isLoading,
                          onPressed: (_canSubmit && !isLoading && auth.isOnline)
                              ? _validateAndSubmit
                              : null,
                        ),
                        const SizedBox(height: 28),

                        // Link login
                        Center(
                          child: GestureDetector(
                            onTap: () =>
                                Navigator.of(context).pushReplacementNamed('/login'),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.4),
                                  fontSize: 14,
                                ),
                                children: const [
                                  TextSpan(text: 'Hai già un account? '),
                                  TextSpan(
                                    text: 'Accedi',
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

  Widget _buildErrorBanner(String message, AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFE05640).withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE05640).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFE05640), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: Color(0xFFE05640), fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: auth.clearError,
            child: Icon(Icons.close,
                size: 16, color: const Color(0xFFE05640).withOpacity(0.6)),
          ),
        ],
      ),
    );
  }

  void _handleNavigation(BuildContext context, AuthProvider auth) {
    final nav = auth.pendingNavigation;
    auth.consumeNavigation();
    switch (nav) {
      case AuthNavigation.toOnboarding:
        Navigator.of(context).pushReplacementNamed('/onboarding');
      case AuthNavigation.toHome:
        Navigator.of(context).pushReplacementNamed('/home');
      default:
        break;
    }
  }
}

class _TosCheckbox extends StatelessWidget {
  final bool accepted;
  final ValueChanged<bool> onChanged;

  const _TosCheckbox({required this.accepted, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!accepted),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: Checkbox(
              value: accepted,
              onChanged: (v) => onChanged(v ?? false),
              activeColor: const Color(0xFF1E9E87),
              side: BorderSide(color: Colors.white.withOpacity(0.25)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.white.withOpacity(0.5),
                  fontSize: 13,
                  height: 1.5,
                ),
                children: const [
                  TextSpan(text: 'Accetto i '),
                  TextSpan(
                    text: 'Termini di Servizio',
                    style: TextStyle(
                      color: Color(0xFF1E9E87),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(text: ' e la '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: Color(0xFF1E9E87),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  TextSpan(text: ' di Be Well'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

