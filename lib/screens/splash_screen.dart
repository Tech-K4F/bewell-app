import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade, _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut)
        .drive(Tween(begin: 0.0, end: 1.0));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut)
        .drive(Tween(begin: 0.7, end: 1.0));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BwColors.darkPanel,
      body: Center(
        child: FadeTransition(
          opacity: _fade,
          child: ScaleTransition(
            scale: _scale,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [BwColors.teal, BwColors.blue],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: BwColors.teal.withOpacity(.5),
                        blurRadius: 48,
                        spreadRadius: 8,
                      ),
                    ],
                  ),
                  child: const Center(
                      child: Text('🌿', style: TextStyle(fontSize: 44))),
                ),
                const SizedBox(height: 24),
                const Text('Be Well',
                    style: TextStyle(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -1)),
                const SizedBox(height: 6),
                Text('Il tuo percorso di benessere',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(.4))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
