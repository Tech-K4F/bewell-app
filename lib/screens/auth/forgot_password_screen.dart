import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/auth/auth_widgets.dart';

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
    final err = BwValidators.email(_emailCtrl.text);
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
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final isLoading = auth.state == AuthState.loading;
        final sent = auth.state == AuthState.passwordResetSent;

        return Scaffold(
          backgroundColor: const Color(0xFF0B1929),
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
              child: sent
                  ? _buildSentState(auth)
                  : _buildRequestState(auth, isLoading),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRequestState(AuthProvider auth, bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: const Color(0xFF1E9E87).withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: const Color(0xFF1E9E87).withOpacity(0.25)),
          ),
          child: const Center(
            child: Text('🔑', style: TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Password dimenticata?',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Inserisci l\'email collegata al tuo account. Ti manderemo un link per reimpostare la password.',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
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
          label: 'Invia link di reset',
          isLoading: isLoading,
          onPressed: (_emailCtrl.text.trim().isNotEmpty && !isLoading)
              ? _submit
              : null,
        ),
      ],
    );
  }

  Widget _buildSentState(AuthProvider auth) {
    final canResend = _resendCooldown == 0 && _resendCount < 3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Spacer(),
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: const Color(0xFF1E9E87).withOpacity(0.12),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
                color: const Color(0xFF1E9E87).withOpacity(0.25)),
          ),
          child: const Center(
            child: Text('✉️', style: TextStyle(fontSize: 28)),
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Controlla la tua email',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        RichText(
          text: TextSpan(
            style: TextStyle(
              color: Colors.white.withOpacity(0.5),
              fontSize: 14,
              height: 1.5,
            ),
            children: [
              const TextSpan(text: 'Se esiste un account per '),
              TextSpan(
                text: _emailCtrl.text.trim(),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
              const TextSpan(
                  text:
                      ', riceverai un link per reimpostare la password.\n\nIl link scade tra 30 minuti.'),
            ],
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
              backgroundColor: const Color(0xFF1E9E87),
              disabledBackgroundColor:
                  const Color(0xFF1E9E87).withOpacity(0.3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              _resendCount >= 3
                  ? 'Limite reinvii raggiunto'
                  : _resendCooldown > 0
                      ? 'Reinvia tra ${_resendCooldown}s'
                      : 'Rinvia email',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
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
              side: BorderSide(color: Colors.white.withOpacity(0.15)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text(
              'Torna al login',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
        ),
        const Spacer(flex: 2),
      ],
    );
  }
}
