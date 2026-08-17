import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/theme_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/auth/auth_widgets.dart';
import '../../widgets/bw_scaffold.dart';
import '../../l10n/app_localizations.dart';

/// S-05 · Forgot Password
/// Flusso 3 step: richiesta → email inviata → (nuova password via deep link).
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailCtrl = TextEditingController();
  String? _emailError;
  int _resendCooldown = 0;
  int _resendCount = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  void _submit() {
    final s = context.sL;
    final err = BwValidators.email(_emailCtrl.text, s);
    setState(() => _emailError = err);
    if (err != null) return;
    context.read<AuthProvider>().sendPasswordReset(_emailCtrl.text.trim());
  }

  void _resend() {
    if (_resendCooldown > 0 || _resendCount >= 3) return;
    setState(() {
      _resendCount++;
      _resendCooldown = 60;
    });
    // Re-invia silenziosamente
    context.read<AuthProvider>().sendPasswordReset(_emailCtrl.text.trim());

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<AuthProvider, ThemeProvider>(
      builder: (context, auth, theme, _) {
        final p = theme.paletteData;
        final s = context.sL;
        final isLoading = auth.state == AuthState.loading;
        final sent = auth.state == AuthState.passwordResetSent;

        return BwScaffold(
          appBar: AppBar(
            backgroundColor: p.bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: p.text, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: sent
                  ? _buildSentState(auth, p, s)
                  : _buildRequestState(auth, isLoading, p, s),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestState(AuthProvider auth, bool isLoading, BwPaletteData p, BwStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: p.primaryLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.primary.withValues(alpha: 0.25)),
          ),
          child: const Center(
            child: Text('🔑', style: TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          s.passwordForgotTitle,
          style: TextStyle(
            color: p.text,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          s.passwordForgotSub,
          style: TextStyle(
            color: p.textSec,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        BwEmailField(
          controller: _emailCtrl,
          errorText: _emailError,
          enabled: !isLoading,
          onEditingComplete: _submit,
        ),
        const SizedBox(height: 24),

        BwAuthButton(
          label: s.sendResetEmail,
          isLoading: isLoading,
          onPressed: isLoading ? null : _submit,
        ),
      ],
    );
  }

  Widget _buildSentState(AuthProvider auth, BwPaletteData p, BwStrings s) {
    final canResend = _resendCooldown == 0 && _resendCount < 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: p.primaryLight,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: p.primary.withValues(alpha: 0.25)),
          ),
          child: const Center(
            child: Text('✉️', style: TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          s.forgotCheckEmailTitle,
          style: TextStyle(
            color: p.text,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          '${s.forgotEmailSentBody(_emailCtrl.text.trim())}\n\n${s.forgotLinkExpiry}',
          style: TextStyle(
            color: p.textSec,
            fontSize: 14,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 32),

        // Reinvia
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: canResend ? _resend : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: p.btn,
              disabledBackgroundColor: p.btn.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _resendCount >= 3
                  ? s.forgotResendLimitReached
                  : _resendCooldown > 0
                      ? s.forgotResendIn(_resendCooldown)
                      : s.resendEmail,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: p.btnText),
            ),
          ),
        ),
        const SizedBox(height: 14),

        // Torna al login
        SizedBox(
          width: double.infinity,
          height: 54,
          child: OutlinedButton(
            onPressed: () =>
                Navigator.of(context).pushReplacementNamed('/login'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: p.cardBorder),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              s.backToLogin,
              style: TextStyle(color: p.text, fontSize: 15),
            ),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}
