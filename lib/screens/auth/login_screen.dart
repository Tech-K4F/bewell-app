import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../utils/validators.dart';
import '../../models/auth_result.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../../widgets/bw_scaffold.dart';
import '../../widgets/locale_selector.dart';

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
      _emailCtrl.text.trim().isNotEmpty && _passwordCtrl.text.isNotEmpty;

  void _validateAndSubmit() {
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
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, auth, theme, _) {
        final p = theme.paletteData;
        final isAmb = theme.isAmbient;
        final s = context.sL;

        if (auth.pendingNavigation != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _handleNavigation(context, auth);
          });
        }

        final isLoading = auth.state == AuthState.loading;
        final isLocked = auth.state == AuthState.locked;

        return BwScaffold(
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

                        // ── Logo + titolo ─────────────────────────
                        Row(
                          children: [
                            Image.asset(
                              'assets/images/companion/companion_base.png',
                              width: 40,
                              height: 40,
                              errorBuilder: (_, __, ___) => Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(
                                  color: p.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text('🌿',
                                      style: const TextStyle(fontSize: 20)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              'Be Well',
                              style: TextStyle(
                                color: p.text,
                                fontSize: 22,
                                fontWeight: isAmb
                                    ? FontWeight.w300
                                    : FontWeight.w700,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        Text(
                          s.welcomeBack,
                          style: TextStyle(
                            color: p.text,
                            fontSize: isAmb ? 32 : 28,
                            fontWeight: isAmb
                                ? FontWeight.w300
                                : FontWeight.w700,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          s.continueJourney,
                          style: TextStyle(
                            color: p.textSec,
                            fontSize: 15,
                            fontStyle: isAmb
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),

                        const SizedBox(height: 32),

                        if (isLocked)
                          AccountLockedWidget(
                            initialSecondsRemaining:
                                auth.lockSecondsRemaining,
                            onUnlock: () => auth.clearError(),
                          )
                        else ...[
                          // SSO
                          SsoButtonRow(
                            enabled: !isLoading && auth.isOnline,
                            onGoogle: () => auth.loginWithGoogle(),
                            onApple: () => auth.loginWithApple(),
                          ),
                          const SizedBox(height: 20),
                          _OrDivider(p: p, label: s.orDivider),
                          const SizedBox(height: 20),

                          // Errore
                          if (auth.state == AuthState.error &&
                              auth.lastError != null)
                            _ErrorBanner(
                              message: auth.lastError!.userMessage,
                              attemptsRemaining: auth.attemptsRemaining,
                              onDismiss: auth.clearError,
                              p: p,
                              attemptsLabel: s.attemptsRemaining,
                            ),

                          // Email
                          _ThemedField(
                            controller: _emailCtrl,
                            label: s.email,
                            errorText: _emailError,
                            enabled: !isLoading,
                            focusNode: _emailFocus,
                            keyboardType: TextInputType.emailAddress,
                            p: p,
                            onEditingComplete: () => FocusScope.of(context)
                                .requestFocus(_passwordFocus),
                          ),
                          const SizedBox(height: 14),

                          // Password
                          _ThemedField(
                            controller: _passwordCtrl,
                            label: s.password,
                            errorText: _passwordError,
                            enabled: !isLoading,
                            focusNode: _passwordFocus,
                            obscureText: true,
                            p: p,
                            onEditingComplete:
                                _canSubmit ? _validateAndSubmit : null,
                          ),
                          const SizedBox(height: 8),

                          // Forgot password
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.of(context)
                                  .pushNamed('/forgot-password'),
                              style: TextButton.styleFrom(
                                  padding: EdgeInsets.zero),
                              child: Text(
                                s.forgotPassword,
                                style: TextStyle(
                                  color: p.primary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Bottone login
                          GestureDetector(
                            onTap: (_canSubmit && !isLoading && auth.isOnline)
                                ? _validateAndSubmit
                                : null,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: double.infinity,
                              height: 52,
                              decoration: BoxDecoration(
                                color: (_canSubmit && !isLoading)
                                    ? p.btn
                                    : p.bg2,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: isLoading
                                    ? SizedBox(
                                        width: 20, height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: p.btnText,
                                        ),
                                      )
                                    : Text(
                                        s.login,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: (_canSubmit && !isLoading)
                                              ? p.btnText
                                              : p.textMut,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          // Biometrico
                          if (auth.biometricAvailable && !isLoading) ...[
                            const SizedBox(height: 14),
                            Center(
                              child: TextButton.icon(
                                onPressed: () => auth.loginWithBiometric(),
                                icon: Icon(Icons.fingerprint,
                                    color: p.primary, size: 22),
                                label: Text(
                                  s.loginWithBiometrics,
                                  style: TextStyle(
                                    color: p.primary,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
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
                                    color: p.textSec,
                                    fontSize: 14,
                                  ),
                                  children: [
                                    TextSpan(text: s.noAccount),
                                    TextSpan(
                                      text: s.createOne,
                                      style: TextStyle(
                                        color: p.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 32),

                          // Selettore lingua
                          const LocaleSelector(),
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

  Future<void> _handleNavigation(BuildContext context, AuthProvider auth) async {
    final nav = auth.pendingNavigation;
    auth.consumeNavigation();
    switch (nav) {
      case AuthNavigation.toHome:
        await context.read<AppProvider>().onLoginComplete();
        if (context.mounted) Navigator.of(context).pushReplacementNamed('/home');
      case AuthNavigation.toOnboarding:
        Navigator.of(context).pushReplacementNamed('/onboarding');
      default:
        break;
    }
  }
}

// ── Componenti themed ─────────────────────────────────────────────────────────

class _ThemedField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? errorText;
  final bool enabled;
  final FocusNode focusNode;
  final bool obscureText;
  final TextInputType keyboardType;
  final BwPaletteData p;
  final VoidCallback? onEditingComplete;

  const _ThemedField({
    required this.controller,
    required this.label,
    this.errorText,
    required this.enabled,
    required this.focusNode,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    required this.p,
    this.onEditingComplete,
  });

  @override
  State<_ThemedField> createState() => _ThemedFieldState();
}

class _ThemedFieldState extends State<_ThemedField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: widget.errorText != null
                  ? Colors.redAccent.withValues(alpha: 0.6)
                  : p.cardBorder,
              width: 0.5,
            ),
          ),
          child: TextField(
            controller: widget.controller,
            focusNode: widget.focusNode,
            enabled: widget.enabled,
            obscureText: widget.obscureText && _obscure,
            keyboardType: widget.keyboardType,
            onEditingComplete: widget.onEditingComplete,
            style: TextStyle(color: p.text, fontSize: 15),
            decoration: InputDecoration(
              labelText: widget.label,
              labelStyle:
                  TextStyle(color: p.textSec, fontSize: 14),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 16),
              suffixIcon: widget.obscureText
                  ? IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: p.textMut,
                        size: 18,
                      ),
                      onPressed: () =>
                          setState(() => _obscure = !_obscure),
                    )
                  : null,
            ),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              widget.errorText!,
              style: const TextStyle(
                  color: Colors.redAccent, fontSize: 11),
            ),
          ),
      ],
    );
  }
}

class _OrDivider extends StatelessWidget {
  final BwPaletteData p;
  final String label;
  const _OrDivider({required this.p, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: p.cardBorder, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label,
              style: TextStyle(color: p.textMut, fontSize: 12)),
        ),
        Expanded(child: Divider(color: p.cardBorder, height: 1)),
      ],
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final int attemptsRemaining;
  final VoidCallback onDismiss;
  final BwPaletteData p;
  final String attemptsLabel;

  const _ErrorBanner({
    required this.message,
    required this.attemptsRemaining,
    required this.onDismiss,
    required this.p,
    required this.attemptsLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.redAccent.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.redAccent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline,
              color: Colors.redAccent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message,
                    style: const TextStyle(
                        color: Colors.redAccent,
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                if (attemptsRemaining > 0 &&
                    attemptsRemaining < 5)
                  Text(
                    '$attemptsRemaining $attemptsLabel',
                    style: TextStyle(
                        color: Colors.redAccent.withValues(alpha: 0.7),
                        fontSize: 11),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            icon: Icon(Icons.close,
                size: 16,
                color: Colors.redAccent.withValues(alpha: 0.6)),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}







