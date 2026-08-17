import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// FIX: import esplicito per evitare conflitto con firebase_auth AuthProvider
import 'package:bewell/providers/auth_provider.dart' as bw;
import '../../providers/theme_provider.dart';
import '../../widgets/bw_scaffold.dart';
import '../../l10n/app_localizations.dart';

/// S-04 · Email Verification
class EmailVerifyScreen extends StatefulWidget {
  final String email;
  const EmailVerifyScreen({super.key, required this.email});

  @override
  State<EmailVerifyScreen> createState() => _EmailVerifyScreenState();
}

class _EmailVerifyScreenState extends State<EmailVerifyScreen> {
  int _resendCooldown = 0;
  int _resendCount = 0;
  Timer? _cooldownTimer;
  Timer? _pollTimer;
  bool _checking = false;

  static const _maxResends = 3;
  static const _cooldownSeconds = 60;

  @override
  void initState() {
    super.initState();
    _pollTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _checkVerified());
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _pollTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkVerified() async {
    if (_checking) return;
    _checking = true;
    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      if (user?.emailVerified == true && mounted) {
        _pollTimer?.cancel();
        Navigator.of(context).pushReplacementNamed('/onboarding');
      }
    } finally {
      _checking = false;
    }
  }

  Future<void> _resendEmail() async {
    if (_resendCooldown > 0 || _resendCount >= _maxResends) return;
    final messenger = ScaffoldMessenger.of(context);
    final s = context.sL;
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text(s.verifySendError),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }

    setState(() {
      _resendCount++;
      _resendCooldown = _cooldownSeconds;
    });

    _cooldownTimer =
        Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) t.cancel();
    });
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().paletteData;
    final s = context.sL;
    final canResend =
        _resendCooldown == 0 && _resendCount < _maxResends;

    return BwScaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
          child: Column(
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
                    child: Text('📧', style: TextStyle(fontSize: 28))),
              ),
              const SizedBox(height: 24),
              Text(
                s.verifyEmail,
                style: TextStyle(
                  color: p.text,
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.15,
                ),
              ),
              const SizedBox(height: 12),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    color: p.textSec,
                    fontSize: 15,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(text: '${s.verifyEmailSent} '),
                    TextSpan(
                      text: widget.email,
                      style: TextStyle(color: p.text, fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: '.\n\n${s.verifyEmailCta}'),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: canResend ? _resendEmail : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: p.btn,
                    disabledBackgroundColor: p.btn.withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _resendCount >= _maxResends
                        ? s.forgotResendLimitReached
                        : _resendCooldown > 0
                            ? s.forgotResendIn(_resendCooldown)
                            : s.verifyResendCta,
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: p.btnText),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: OutlinedButton(
                  onPressed: _checkVerified,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: p.cardBorder),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(s.verifyChecked,
                      style: TextStyle(color: p.text, fontSize: 15)),
                ),
              ),
              const Spacer(flex: 2),
              Center(
                child: GestureDetector(
                  onTap: () {
                    // FIX: usa alias bw per evitare conflitto
                    context.read<bw.AuthProvider>().logout();
                    Navigator.of(context)
                        .pushReplacementNamed('/register');
                  },
                  child: Text(
                    s.verifyDifferentEmail,
                    style: TextStyle(
                      color: p.textMut,
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                      decorationColor: p.textMut,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
