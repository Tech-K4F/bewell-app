import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/legal_links.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/theme_provider.dart';
import '../../models/auth_result.dart';
import '../../utils/validators.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../../widgets/bw_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../../services/cloud_sync_service.dart';
import '../../widgets/restart_widget.dart';

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
    final s = context.sL;
    final nameErr = BwValidators.name(_nameCtrl.text, s);
    final emailErr = BwValidators.email(_emailCtrl.text, s);
    final passErr = BwValidators.registerPassword(_passwordCtrl.text, s);

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
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, auth, theme, _) {
        final p = theme.paletteData;
        final s = context.sL;

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
                        // Torna al login — Register è sempre raggiunta con
                        // pushReplacementNamed, quindi non c'è nulla sotto
                        // nello stack: pop() non farebbe nulla.
                        Semantics(
                            button: true,
                            container: true,
                            child: GestureDetector(
                              onTap: () => Navigator.of(context)
                                  .pushReplacementNamed('/login'),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.arrow_back_ios,
                                    color: p.textMut,
                                    size: 16,
                                  ),
                                  Text(
                                    s.signIn,
                                    style: TextStyle(
                                      color: p.textMut,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        const SizedBox(height: 24),

                        Text(
                          s.createAccount,
                          style: TextStyle(
                            color: p.text,
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          s.registerSubtitle,
                          style: TextStyle(
                            color: p.textSec,
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
                        if (auth.state == AuthState.error &&
                            auth.lastError != null)
                          _buildErrorBanner(
                              auth.lastError!.localizedMessage(s), auth, p),

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
                          onEditingComplete: () => FocusScope.of(context)
                              .requestFocus(_passwordFocus),
                        ),
                        const SizedBox(height: 14),

                        // Password con barra forza
                        BwPasswordField(
                          controller: _passwordCtrl,
                          errorText: _passwordError,
                          enabled: !isLoading,
                          focusNode: _passwordFocus,
                          showStrengthBar: true,
                          onEditingComplete:
                              _canSubmit ? _validateAndSubmit : null,
                        ),
                        const SizedBox(height: 20),

                        // ToS checkbox
                        _TosCheckbox(
                          accepted: _tosAccepted,
                          onChanged: (v) => setState(() => _tosAccepted = v),
                          p: p,
                          s: s,
                        ),
                        const SizedBox(height: 24),

                        // Bottone registrazione
                        BwAuthButton(
                          label: s.createAccount,
                          isLoading: isLoading,
                          onPressed: (_canSubmit && !isLoading && auth.isOnline)
                              ? _validateAndSubmit
                              : null,
                        ),
                        const SizedBox(height: 28),

                        // Link login
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context)
                                .pushReplacementNamed('/login'),
                            child: RichText(
                              text: TextSpan(
                                style: TextStyle(
                                  color: p.textMut,
                                  fontSize: 14,
                                ),
                                children: [
                                  TextSpan(text: s.alreadyHaveAccount),
                                  TextSpan(
                                    text: s.signIn,
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

  Widget _buildErrorBanner(String message, AuthProvider auth, BwPaletteData p) {
    const error = Color(0xFFE05640);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: error, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(color: error, fontSize: 13),
            ),
          ),
          GestureDetector(
            onTap: auth.clearError,
            child: Icon(Icons.close,
                size: 16, color: error.withValues(alpha: 0.6)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleNavigation(
      BuildContext context, AuthProvider auth) async {
    final nav = auth.pendingNavigation;
    auth.consumeNavigation();
    // Installazione nuova ma account con progressi nel cloud: ripristina e
    // riparte da capo con lo stato caricato (niente onboarding da rifare).
    if ((nav == AuthNavigation.toHome || nav == AuthNavigation.toWelcome) &&
        await CloudSyncService.instance.restoreIfFresh()) {
      if (context.mounted) RestartWidget.restart(context);
      return;
    }
    switch (nav) {
      case AuthNavigation.toWelcome:
        // Vedi commento gemello in login_screen.dart: senza sincronizzare
        // qui, AppProvider.user restava nullo per l'intero onboarding di
        // un utente nuovo e la schermata Profilo appariva bianca.
        await context.read<AppProvider>().onLoginComplete();
        if (context.mounted) {
          Navigator.of(context).pushReplacementNamed('/welly-welcome');
        }
      case AuthNavigation.toHome:
        await context.read<AppProvider>().onLoginComplete();
        if (context.mounted)
          Navigator.of(context).pushReplacementNamed('/home');
      default:
        break;
    }
  }
}

class _TosCheckbox extends StatefulWidget {
  final bool accepted;
  final ValueChanged<bool> onChanged;
  final BwPaletteData p;
  final BwStrings s;

  const _TosCheckbox({
    required this.accepted,
    required this.onChanged,
    required this.p,
    required this.s,
  });

  @override
  State<_TosCheckbox> createState() => _TosCheckboxState();
}

class _TosCheckboxState extends State<_TosCheckbox> {
  // I link ai Termini/Privacy erano testo colorato senza nessun tap handler
  // — l'utente spuntava una casella che referenzia documenti che non poteva
  // aprire da nessuna parte nell'app.
  late final TapGestureRecognizer _termsTap;
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    _termsTap = TapGestureRecognizer()
      ..onTap = () => _open(LegalLinks.termsOfService);
    _privacyTap = TapGestureRecognizer()
      ..onTap = () => _open(LegalLinks.privacyPolicy);
  }

  @override
  void dispose() {
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final s = widget.s;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: Checkbox(
            value: widget.accepted,
            onChanged: (v) => widget.onChanged(v ?? false),
            activeColor: p.primary,
            side: BorderSide(color: p.textMut),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: GestureDetector(
            // Il tap sul resto della riga (fuori dai due link) continua a
            // spuntare la casella, come prima.
            onTap: () => widget.onChanged(!widget.accepted),
            child: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: p.textSec,
                  fontSize: 13,
                  height: 1.5,
                ),
                children: [
                  TextSpan(text: s.tosAccept),
                  TextSpan(
                    text: s.tosTerms,
                    recognizer: _termsTap,
                    style: TextStyle(
                      color: p.primary,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: p.primary,
                    ),
                  ),
                  TextSpan(text: s.tosAnd),
                  TextSpan(
                    text: s.tosPrivacy,
                    recognizer: _privacyTap,
                    style: TextStyle(
                      color: p.primary,
                      fontWeight: FontWeight.w500,
                      decoration: TextDecoration.underline,
                      decorationColor: p.primary,
                    ),
                  ),
                  TextSpan(text: s.tosSuffix),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
