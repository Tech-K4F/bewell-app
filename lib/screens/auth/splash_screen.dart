import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();
    _checkAndNavigate();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _checkAndNavigate() async {
    // Attendi animazione minima
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Non loggato → Login
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    // Utente loggato — verifica se ha completato l'onboarding
    final prefs = await SharedPreferences.getInstance();
    final isOnboarded = prefs.getBool('is_onboarded') ?? false;

    // Popola UserProfile da Firebase se non già caricato
    await _syncUserProfile(user, prefs);

    if (!mounted) return;

    if (!isOnboarded) {
      Navigator.of(context).pushReplacementNamed('/onboarding');
    } else {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  }

  Future<void> _syncUserProfile(User firebaseUser, SharedPreferences prefs) async {
    final appProvider = context.read<AppProvider>();

    // Se non c'è profilo salvato, crealo dai dati Firebase
    if (appProvider.user == null) {
      final savedJson = prefs.getString('user_profile');
      if (savedJson == null) {
        // Prima volta: crea profilo dai dati Firebase
        final profile = UserProfile(
          id: firebaseUser.uid,
          name: firebaseUser.displayName ?? firebaseUser.email?.split('@').first ?? 'Utente',
          email: firebaseUser.email ?? '',
          userType: 'worker',
        );
        await appProvider.completeOnboarding(profile);
      }
    } else {
      // Profilo esiste: aggiorna nome/email se Firebase li ha aggiornati
      final current = appProvider.user!;
      final firebaseName = firebaseUser.displayName ?? '';
      final firebaseEmail = firebaseUser.email ?? '';

      if ((firebaseName.isNotEmpty && current.name != firebaseName) ||
          (firebaseEmail.isNotEmpty && current.email != firebaseEmail)) {
        final updated = UserProfile(
          id: firebaseUser.uid,
          name: firebaseName.isNotEmpty ? firebaseName : current.name,
          email: firebaseEmail.isNotEmpty ? firebaseEmail : current.email,
          userType: current.userType,
          points: current.points,
          streak: current.streak,
          graceSkipsUsed: current.graceSkipsUsed,
          lastActivityDate: current.lastActivityDate,
          earnedBadgeIds: current.earnedBadgeIds,
          settings: current.settings,
          stressLevel: current.stressLevel,
          primaryGoal: current.primaryGoal,
          totalSessions: current.totalSessions,
          totalMinutes: current.totalMinutes,
          weeklyCompletions: current.weeklyCompletions,
        );
        await appProvider.completeOnboarding(updated);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BwColors.darkPanel,
      body: FadeTransition(
        opacity: _fade,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [BwColors.teal, BwColors.blue],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: BwColors.teal.withValues(alpha: 0.4),
                      blurRadius: 32,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Center(
                  child: Text('🌿', style: TextStyle(fontSize: 44)),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Be Well',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Il tuo piano di benessere',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 60),
              SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: BwColors.teal.withValues(alpha: 0.6),
                  strokeWidth: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
