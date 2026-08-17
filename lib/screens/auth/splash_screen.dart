import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/auth_service.dart';

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
    // Aspetta che Firebase Auth ripristini la sessione persistita.
    // currentUser può restare null per una frazione di secondo dopo l'avvio
    // anche quando l'utente HA una sessione valida — controllarlo subito
    // dopo un delay fisso (come prima) fa credere all'app che l'utente non
    // sia loggato, chiedendo il login a ogni riapertura. authStateChanges()
    // invece emette il valore vero solo quando Firebase ha davvero finito.
    final user = await AuthService.instance.authStateChanges.first
        .timeout(const Duration(seconds: 5), onTimeout: () => null);
    // Breve pausa per non far lampeggiare lo splash troppo velocemente.
    await Future.delayed(const Duration(milliseconds: 400));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();

    if (user == null) {
      Navigator.pushReplacementNamed(context, '/login');
      return;
    }

    // Il configuratore a 5 fasi (questionario) NON è più un passaggio
    // obbligato: è facoltativo, raggiungibile dalla sezione Abitudini dopo
    // il primo sblocco. L'unico prerequisito per Home è aver visto il
    // carosello di benvenuto "Be Well".
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


