import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/onboarding/onboarding_widgets.dart';
import '../../widgets/bw_scaffold.dart';
import '../../l10n/app_localizations.dart';

// Wrapper di layout comune per tutte le schermate questionario
class _QuestionnaireShell extends StatelessWidget {
  final int screenNumber;
  final String title;
  final String subtitle;
  final Widget body;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback onSkipAll;
  final String nextLabel;

  const _QuestionnaireShell({
    required this.screenNumber,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.onNext,
    this.onBack,
    required this.onSkipAll,
    required this.nextLabel,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().paletteData;
    return BwScaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: QuestionnaireProgressBar(
                current: screenNumber,
                total: 5,
                timeRemaining:
                    context.read<OnboardingProvider>().estimatedTimeRemaining,
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: p.text,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: p.textMut,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 28),
                    body,
                    const SizedBox(height: 28),
                    QuestionnaireNavRow(
                      onNext: onNext,
                      onBack: onBack,
                      onSkipAll: onSkipAll,
                      nextLabel: nextLabel,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// S-08A — PROFILO (Q2 Work Location — Occupation rimossa: mai usata da
// nessuna ifThenRule e non collegabile a nessuna abitudine del catalogo)
// ═══════════════════════════════════════════════════════════════════════════

class ProfileQuestionnaireScreen extends StatelessWidget {
  const ProfileQuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(builder: (context, onb, _) {
      final a = onb.answers;
      final s = context.sL;
      return _QuestionnaireShell(
        screenNumber: 1,
        title: s.qProfileTitle,
        subtitle: s.qProfileSub,
        onNext: onb.nextFromProfile,
        onBack: () => onb.goToStep(OnboardingStep.welcome),
        onSkipAll: onb.skipAll,
        nextLabel: s.welcomeNext,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Q2 — Work Location
            QuestionLabel(label: s.q2Label),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.2,
              children: [
                OptionCard(
                  emoji: '🏠',
                  label: s.q2Home,
                  selected: a.workLocation == 'home',
                  onTap: () =>
                      onb.updateAnswers(a.copyWith(workLocation: 'home')),
                ),
                OptionCard(
                  emoji: '🏢',
                  label: s.q2Office,
                  selected: a.workLocation == 'office',
                  onTap: () =>
                      onb.updateAnswers(a.copyWith(workLocation: 'office')),
                ),
                OptionCard(
                  emoji: '🔀',
                  label: s.q2Hybrid,
                  selected: a.workLocation == 'hybrid',
                  onTap: () =>
                      onb.updateAnswers(a.copyWith(workLocation: 'hybrid')),
                ),
                OptionCard(
                  emoji: '🌍',
                  label: s.q2Varies,
                  selected: a.workLocation == 'varies',
                  onTap: () =>
                      onb.updateAnswers(a.copyWith(workLocation: 'varies')),
                ),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// S-08B — OBIETTIVI & STRESS (Q3 Goals + Q4 Stress — Prior apps rimossa:
// mai usata da nessuna ifThenRule)
// ═══════════════════════════════════════════════════════════════════════════

class GoalsQuestionnaireScreen extends StatelessWidget {
  const GoalsQuestionnaireScreen({super.key});

  static const _stressEmojis = ['😌', '😊', '😐', '😓', '😰'];

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(builder: (context, onb, _) {
      final a = onb.answers;
      final s = context.sL;
      final p = context.watch<ThemeProvider>().paletteData;
      final showCrisisSupport = a.stressLevel == 5;

      final goalOptions = [
        ('stress', '🧘', s.goalStress),
        ('focus', '⏱️', s.goalFocus),
        ('health', '💧', s.goalHealth),
        ('sleep', '😴', s.goalSleep),
        ('energy', '⚡', s.goalEnergy),
        ('weight', '🏃', s.goalWeight),
      ];
      final stressLabels = [s.stress1, s.stress2, s.stress3, s.stress4, s.stress5];

      return _QuestionnaireShell(
        screenNumber: 2,
        title: s.qGoalsTitle,
        subtitle: s.qGoalsSub,
        onNext: onb.nextFromGoals,
        onBack: onb.back,
        onSkipAll: onb.skipAll,
        nextLabel: s.welcomeNext,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Q3 — Goals (multi-select)
            QuestionLabel(label: s.q3Label),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.1,
              children: goalOptions.map((opt) {
                final selected = a.goals.contains(opt.$1);
                return OptionCard(
                  emoji: opt.$2,
                  label: opt.$3,
                  selected: selected,
                  onTap: () {
                    final goals = List<String>.from(a.goals);
                    if (selected) {
                      goals.remove(opt.$1);
                    } else {
                      goals.add(opt.$1);
                    }
                    onb.updateAnswers(a.copyWith(goals: goals.isEmpty ? ['stress'] : goals));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 28),

            // Q4 — Stress Level (Likert 1-5)
            QuestionLabel(label: s.q4Label),
            Center(
              child: Text(
                _stressEmojis[a.stressLevel - 1],
                style: const TextStyle(fontSize: 56),
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: Text(
                stressLabels[a.stressLevel - 1],
                style: TextStyle(
                  color: p.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Slider(
              value: a.stressLevel.toDouble(),
              min: 1,
              max: 5,
              divisions: 4,
              onChanged: (v) =>
                  onb.updateAnswers(a.copyWith(stressLevel: v.round())),
              activeColor: p.primary,
              inactiveColor: p.cardBorder,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(s.stressCalmEnd,
                    style: TextStyle(fontSize: 11, color: p.textMut)),
                Text(s.stressStressedEnd,
                    style: TextStyle(fontSize: 11, color: p.textMut)),
              ],
            ),

            // Crisis support (solo Q4=5)
            if (showCrisisSupport) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF3A7BD5).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF3A7BD5).withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Text('💙', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.crisisTitle,
                            style: TextStyle(
                                color: p.text,
                                fontWeight: FontWeight.w600,
                                fontSize: 13),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            s.crisisBody,
                            style: TextStyle(
                                color: p.textSec,
                                fontSize: 11,
                                height: 1.4),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// S-08C — SALUTE (Q6 Sleep + Q7 Hydration + Q8 Screen time + Q9 Exercise)
// ═══════════════════════════════════════════════════════════════════════════

class HealthQuestionnaireScreen extends StatelessWidget {
  const HealthQuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(builder: (context, onb, _) {
      final a = onb.answers;
      final s = context.sL;
      return _QuestionnaireShell(
        screenNumber: 3,
        title: s.qHealthTitle,
        subtitle: s.qHealthSub,
        onNext: onb.nextFromHealth,
        onBack: onb.back,
        onSkipAll: onb.skipAll,
        nextLabel: s.welcomeNext,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Q6 — Sleep
            QuestionLabel(label: s.q15Label),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.4,
              children: [
                for (final sl in ['<5h', '5-6h', '6-7h', '7-8h', '8h+'])
                  OptionCard(
                    emoji: sl == '7-8h' || sl == '8h+' ? '😴' : '😪',
                    label: sl,
                    selected: a.sleepHours == sl,
                    onTap: () =>
                        onb.updateAnswers(a.copyWith(sleepHours: sl)),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Q7 — Hydration
            QuestionLabel(label: s.q16Label),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.3,
              children: [
                for (final h in ['<1L', '1-1.5L', '1.5-2L', '2L+'])
                  OptionCard(
                    emoji: '💧',
                    label: h,
                    sublabel: h == '<1L' ? s.hydroLow : h == '2L+' ? s.hydroGreat : null,
                    selected: a.hydrationLiters == h,
                    onTap: () =>
                        onb.updateAnswers(a.copyWith(hydrationLiters: h)),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Q8 — Screen time slider
            LabeledSlider(
              label: s.q17Label,
              value: a.screenTimeHours.toDouble(),
              min: 0,
              max: 8,
              divisions: 8,
              valueLabel: (v) => '${v.round()}h',
              onChanged: (v) =>
                  onb.updateAnswers(a.copyWith(screenTimeHours: v.round())),
            ),
            if (a.screenTimeHours >= 5)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFFD99820), size: 14),
                    const SizedBox(width: 6),
                    Text(
                      s.screenTimeWarning,
                      style: TextStyle(
                          color: const Color(0xFFD99820).withValues(alpha: 0.8),
                          fontSize: 11),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 20),

            // Q9 — Exercise
            QuestionLabel(label: s.q18Label),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.2,
              children: [
                OptionCard(emoji: '🛋️', label: s.exNever, selected: a.exerciseFreq == 'never',
                    onTap: () => onb.updateAnswers(a.copyWith(exerciseFreq: 'never'))),
                OptionCard(emoji: '🚶', label: s.ex12x, selected: a.exerciseFreq == '1-2x',
                    onTap: () => onb.updateAnswers(a.copyWith(exerciseFreq: '1-2x'))),
                OptionCard(emoji: '🏃', label: s.ex34x, selected: a.exerciseFreq == '3-4x',
                    onTap: () => onb.updateAnswers(a.copyWith(exerciseFreq: '3-4x'))),
                OptionCard(emoji: '🏋️', label: s.exDaily, selected: a.exerciseFreq == 'daily',
                    onTap: () => onb.updateAnswers(a.copyWith(exerciseFreq: 'daily'))),
              ],
            ),
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// S-08D — ORARIO (Q10 Schedule type + Q11 Durata pranzo — sync calendario,
// frequenza reminder, durata pausa lavoro e orario pranzo rimossi)
// ═══════════════════════════════════════════════════════════════════════════

class ScheduleQuestionnaireScreen extends StatelessWidget {
  const ScheduleQuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(builder: (context, onb, _) {
      final a = onb.answers;
      final s = context.sL;

      return _QuestionnaireShell(
        screenNumber: 4,
        title: s.qScheduleTitle,
        subtitle: s.qScheduleSub,
        onNext: onb.nextFromSchedule,
        onBack: onb.back,
        onSkipAll: onb.skipAll,
        nextLabel: s.welcomeNext,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Q10 — Schedule type
            QuestionLabel(label: s.q5Label),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.3,
              children: [
                OptionCard(emoji: '📅', label: s.schedFixed, selected: a.scheduleType == 'fixed',
                    onTap: () => onb.updateAnswers(a.copyWith(scheduleType: 'fixed'))),
                OptionCard(emoji: '🔄', label: s.schedFlexible, selected: a.scheduleType == 'flexible',
                    onTap: () => onb.updateAnswers(a.copyWith(scheduleType: 'flexible'))),
                OptionCard(emoji: '🌙', label: s.schedShift, selected: a.scheduleType == 'shift',
                    onTap: () => onb.updateAnswers(a.copyWith(scheduleType: 'shift'))),
                OptionCard(emoji: '⚡', label: s.schedIrregular, selected: a.scheduleType == 'irregular',
                    onTap: () => onb.updateAnswers(a.copyWith(scheduleType: 'irregular'))),
              ],
            ),
            const SizedBox(height: 20),

            // Q11 — Durata pausa pranzo (orario pranzo e le altre domande
            // di questa schermata — sync calendario, frequenza reminder,
            // durata pausa lavoro — rimosse: raccolte ma mai collegate a
            // nessuna abitudine del catalogo). CompactTimePicker mostra già
            // la sua label, non serve un QuestionLabel duplicato sopra.
            CompactTimePicker(
              label: s.lunchDurationLabel,
              value: a.lunchDuration,
              onChanged: (v) =>
                  onb.updateAnswers(a.copyWith(lunchDuration: v)),
              options: const ['15m', '30m', '45m', '60m+'],
            ),
          ],
        ),
      );
    });
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// S-08E — AMBIENTE & PRODUTTIVITÀ (Q16-Q17 risorse, Q18 distrazioni,
// Q19 focus di picco, Q20 durata focus, Q21 carico riunioni)
// ═══════════════════════════════════════════════════════════════════════════

class EnvironmentQuestionnaireScreen extends StatelessWidget {
  const EnvironmentQuestionnaireScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<OnboardingProvider>(builder: (context, onb, _) {
      final a = onb.answers;
      final s = context.sL;
      return _QuestionnaireShell(
        screenNumber: 5,
        title: s.qEnvTitle,
        subtitle: s.qEnvSub,
        onNext: onb.submitEnvironment,
        onBack: onb.back,
        onSkipAll: onb.skipAll,
        nextLabel: s.qBuildPlan,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Q16-Q17 — Physical resources (accesso palestra e vista dalla
            // finestra rimossi: nessuna abitudine del catalogo li usa)
            QuestionLabel(label: s.q11q14Label),
            ResourceToggle(
              emoji: '🌳',
              label: s.resParkLabel,
              sublabel: s.resParkSub,
              value: a.hasParkAccess,
              onChanged: (v) =>
                  onb.updateAnswers(a.copyWith(hasParkAccess: v)),
            ),
            const SizedBox(height: 8),
            ResourceToggle(
              emoji: '🔇',
              label: s.resQuietLabel,
              sublabel: s.resQuietSub,
              value: a.hasQuietSpace,
              onChanged: (v) =>
                  onb.updateAnswers(a.copyWith(hasQuietSpace: v)),
            ),
            const SizedBox(height: 24),

            // Q20 — Distraction level
            QuestionLabel(label: s.q19Label),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.3,
              children: [
                OptionCard(emoji: '🤫', label: s.distLow,
                    selected: a.distractionLevel == 'low',
                    onTap: () => onb.updateAnswers(a.copyWith(distractionLevel: 'low'))),
                OptionCard(emoji: '🔈', label: s.distMedium,
                    selected: a.distractionLevel == 'medium',
                    onTap: () => onb.updateAnswers(a.copyWith(distractionLevel: 'medium'))),
                OptionCard(emoji: '🔊', label: s.distHigh,
                    selected: a.distractionLevel == 'high',
                    onTap: () => onb.updateAnswers(a.copyWith(distractionLevel: 'high'))),
                OptionCard(emoji: '📣', label: s.distVeryHigh,
                    selected: a.distractionLevel == 'very_high',
                    onTap: () => onb.updateAnswers(a.copyWith(distractionLevel: 'very_high'))),
              ],
            ),
            const SizedBox(height: 20),

            // Q21 — Peak focus time
            QuestionLabel(label: s.q20Label),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.3,
              children: [
                OptionCard(emoji: '🌅', label: s.focusMorning,
                    selected: a.peakFocusTime == 'morning',
                    onTap: () => onb.updateAnswers(a.copyWith(peakFocusTime: 'morning'))),
                OptionCard(emoji: '☀️', label: s.focusMidday,
                    selected: a.peakFocusTime == 'midday',
                    onTap: () => onb.updateAnswers(a.copyWith(peakFocusTime: 'midday'))),
                OptionCard(emoji: '🌤️', label: s.focusAfternoon,
                    selected: a.peakFocusTime == 'afternoon',
                    onTap: () => onb.updateAnswers(a.copyWith(peakFocusTime: 'afternoon'))),
                OptionCard(emoji: '🌙', label: s.focusEvening,
                    selected: a.peakFocusTime == 'evening',
                    onTap: () => onb.updateAnswers(a.copyWith(peakFocusTime: 'evening'))),
              ],
            ),
            const SizedBox(height: 20),

            // Q22 — Focus duration
            QuestionLabel(label: s.q21Label),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 4,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.0,
              children: [
                for (final d in ['<15m', '15-25m', '25-45m', '45m+'])
                  OptionCard(
                    emoji: d == '<15m' ? '⚡' : d == '45m+' ? '🏆' : '⏱️',
                    label: d,
                    selected: a.focusDuration == d,
                    onTap: () =>
                        onb.updateAnswers(a.copyWith(focusDuration: d)),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Q23 — Meeting load
            QuestionLabel(label: s.q22Label),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 1.3,
              children: [
                OptionCard(emoji: '📵', label: s.meeting02,
                    selected: a.meetingLoad == '0-2/day',
                    onTap: () => onb.updateAnswers(a.copyWith(meetingLoad: '0-2/day'))),
                OptionCard(emoji: '📅', label: s.meeting24,
                    selected: a.meetingLoad == '2-4/day',
                    onTap: () => onb.updateAnswers(a.copyWith(meetingLoad: '2-4/day'))),
                OptionCard(emoji: '😓', label: s.meeting46,
                    selected: a.meetingLoad == '4-6/day',
                    onTap: () => onb.updateAnswers(a.copyWith(meetingLoad: '4-6/day'))),
                OptionCard(emoji: '😰', label: s.meeting6plus,
                    selected: a.meetingLoad == '6+/day',
                    onTap: () => onb.updateAnswers(a.copyWith(meetingLoad: '6+/day'))),
              ],
            ),
          ],
        ),
      );
    });
  }
}
