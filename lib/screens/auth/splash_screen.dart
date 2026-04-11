import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();
    final prefs = await SharedPreferences.getInstance();

    if (!auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final isOnboarded = prefs.getBool('is_onboarded') ?? false;
    if (!isOnboarded) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    final wellyWelcomed = prefs.getBool('welly_welcomed') ?? false;
    if (!wellyWelcomed) {
      Navigator.pushReplacementNamed(context, '/welly-welcome');
      return;
    }

    Navigator.pushReplacementNamed(context, '/home');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1929),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/companion/companion_base.png',
              width: 100,
              errorBuilder: (_, __, ___) => const SizedBox(
                width: 100,
                height: 100,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Be Well',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.w300,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


