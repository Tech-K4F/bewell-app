import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import 'welcome_carousel.dart';
import 'questionnaire_screens.dart';
import 'plan_generation_screen.dart';
import 'plan_preview_screen.dart';

/// Shell dell'onboarding — mostra lo step corretto in base all'OnboardingProvider.
/// Non conosce il contenuto di ogni step — delega alle schermate figlie.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OnboardingProvider>().init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(
      builder: (context, onb, _) {
        // Onboarding completato → naviga a Home
        if (onb.step == OnboardingStep.done) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          });
        }

        // Resume parziale: mostra dialog solo una volta
        if (onb.wasPartiallyCompleted) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _showResumeDialog(context, onb);
          });
        }

        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0.05, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ));
            return SlideTransition(
              position: offset,
              child: FadeTransition(opacity: animation, child: child),
            );
          },
          child: _buildStep(onb),
        );
      },
    );
  }

  Widget _buildStep(OnboardingProvider onb) {
    switch (onb.step) {
      case OnboardingStep.welcome:
        return const WelcomeCarousel(key: ValueKey('welcome'));
      case OnboardingStep.profileQ:
        return const ProfileQuestionnaireScreen(key: ValueKey('profile'));
      case OnboardingStep.goalsQ:
        return const GoalsQuestionnaireScreen(key: ValueKey('goals'));
      case OnboardingStep.healthQ:
        return const HealthQuestionnaireScreen(key: ValueKey('health'));
      case OnboardingStep.scheduleQ:
        return const ScheduleQuestionnaireScreen(key: ValueKey('schedule'));
      case OnboardingStep.environmentQ:
        return const EnvironmentQuestionnaireScreen(key: ValueKey('env'));
      case OnboardingStep.generating:
        return const PlanGenerationScreen(key: ValueKey('generating'));
      case OnboardingStep.planPreview:
        return const PlanPreviewScreen(key: ValueKey('preview'));
      default:
        return const SizedBox();
    }
  }

  void _showResumeDialog(BuildContext context, OnboardingProvider onb) {
    onb.clearPartial(); // Non mostrarlo di nuovo
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0F1F33),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Riprendi configurazione',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Hai lasciato la configurazione a metà. Vuoi riprendere da dove eri rimasto?',
          style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              onb.skipAll();
            },
            child: Text(
              'Ricomincia',
              style: TextStyle(color: Colors.white.withOpacity(0.4)),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1E9E87),
            ),
            child: const Text('Riprendi'),
          ),
        ],
      ),
    );
  }
}
