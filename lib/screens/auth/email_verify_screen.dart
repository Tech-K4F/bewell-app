import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// FIX: import esplicito per evitare conflitto con firebase_auth AuthProvider
import 'package:bewell/providers/auth_provider.dart' as bw;

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
    try {
      await FirebaseAuth.instance.currentUser?.sendEmailVerification();
    } catch (_) {}

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
    final canResend =
        _resendCooldown == 0 && _resendCount < _maxResends;

    return Scaffold(
      backgroundColor: const Color(0xFF0B1929),
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
                  color: const Color(0xFF1E9E87).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: const Color(0xFF1E9E87).withValues(alpha: 0.25),
                  ),
                ),
                child: const Center(
                    child: Text('📧', style: TextStyle(fontSize: 28))),
              ),
              const SizedBox(height: 24),
              const Text(
                'Controlla\nla tua email',
                style: TextStyle(
                  color: Colors.white,
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
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 15,
                    height: 1.5,
                  ),
                  children: [
                    const TextSpan(
                        text: 'Ti abbiamo inviato un link di verifica a '),
                    TextSpan(
                      text: widget.email,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                    const TextSpan(
                        text:
                            '.\n\nClicca il link per attivare il tuo account.'),
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
                    backgroundColor: const Color(0xFF1E9E87),
                    disabledBackgroundColor:
                        const Color(0xFF1E9E87).withValues(alpha: 0.3),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    _resendCount >= _maxResends
                        ? 'Limite reinvii raggiunto'
                        : _resendCooldown > 0
                            ? 'Reinvia tra ${_resendCooldown}s'
                            : 'Reinvia email di verifica',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white),
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
                    side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.15)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ho verificato l\'email',
                      style: TextStyle(color: Colors.white, fontSize: 15)),
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
                    'Usare un\'email diversa?',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.3),
                      fontSize: 13,
                      decoration: TextDecoration.underline,
                      decorationColor:
                          Colors.white.withValues(alpha: 0.3),
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
