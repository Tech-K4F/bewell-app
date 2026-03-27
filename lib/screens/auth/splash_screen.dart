import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

/// S-01 · Splash / Entry Screen
/// Prima schermata ad ogni cold start. Controlla la sessione esistente.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _sessionChecked = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    _ctrl.forward();

    // Avvia il check sessione dopo 400ms (attesa animazione iniziale)
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        context.read<AuthProvider>().init();
      }
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        // Naviga quando il provider ha determinato lo stato
        if (!_sessionChecked && auth.pendingNavigation != null) {
          _sessionChecked = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _navigate(context, auth);
          });
        }

        return Scaffold(
          backgroundColor: const Color(0xFF0B1929),
          body: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                FadeTransition(
                  opacity: _fade,
                  child: SlideTransition(
                    position: _slide,
                    child: Column(
                      children: [
                        // Logo
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF1E9E87), Color(0xFF3A7BD5)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(26),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF1E9E87).withOpacity(0.4),
                                blurRadius: 40,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text('🌿', style: TextStyle(fontSize: 42)),
                          ),
                        ),
                        const SizedBox(height: 22),
                        const Text(
                          'Be Well',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Mostra il nome utente se sessione valida
                        if (auth.state == AuthState.authenticated &&
                            auth.pendingNavigation == AuthNavigation.toHome)
                          Text(
                            'Bentornato 👋',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 14,
                            ),
                          )
                        else
                          Text(
                            'Il tuo percorso di benessere',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.4),
                              fontSize: 14,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                const Spacer(flex: 2),
                // Indicatore di caricamento
                FadeTransition(
                  opacity: _fade,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 48),
                    child: auth.state == AuthState.checkingSession
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Color(0xFF1E9E87),
                              strokeWidth: 2,
                            ),
                          )
                        : const SizedBox(height: 20),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _navigate(BuildContext context, AuthProvider auth) {
    auth.consumeNavigation();
    switch (auth.pendingNavigation ?? _resolveNav(auth)) {
      case AuthNavigation.toHome:
        Navigator.of(context).pushReplacementNamed('/home');
      case AuthNavigation.toOnboarding:
        Navigator.of(context).pushReplacementNamed('/onboarding');
      case AuthNavigation.toLogin:
        Navigator.of(context).pushReplacementNamed('/login');
      case AuthNavigation.toRegister:
        Navigator.of(context).pushReplacementNamed('/register');
    }
  }

  AuthNavigation _resolveNav(AuthProvider auth) {
    if (auth.isAuthenticated) {
      return auth.isFirstLogin
          ? AuthNavigation.toOnboarding
          : AuthNavigation.toHome;
    }
    return AuthNavigation.toLogin;
  }
}
