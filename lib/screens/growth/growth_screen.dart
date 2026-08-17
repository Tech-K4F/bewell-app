import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/tutorial_provider.dart';
import '../../widgets/companion/companion_widget.dart';
import '../../widgets/bw_scaffold.dart';
import '../../widgets/spotlight_overlay.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/banner_ad_widget.dart';
import '../marketplace/marketplace_screen.dart';

class GrowthScreen extends StatefulWidget {
  const GrowthScreen({super.key});

  @override
  State<GrowthScreen> createState() => _GrowthScreenState();
}

class _GrowthScreenState extends State<GrowthScreen> {
  static const List<SpotlightStep> _growthSteps = [
    SpotlightStep(textId: 'growth_welcome'),
    SpotlightStep(textId: 'growth_phase',   targetId: 'spot_companion_hero'),
    SpotlightStep(textId: 'growth_heatmap', targetId: 'spot_heatmap'),
    SpotlightStep(textId: 'growth_badges',  targetId: 'spot_badges'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _checkGrowthSpotlight();
    });
  }

  Future<void> _checkGrowthSpotlight() async {
    if (!mounted) return;
    final ctrl = context.read<SpotlightController>();
    final seen = await ctrl.hasSeenTutorial('growth_tour');
    if (!mounted) return;
    if (!seen) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) ctrl.startTutorial('growth_tour', _growthSteps);
      if (mounted) {
        await context.read<TutorialProvider>().markSeenExternally('growth_first_visit');
      }
    } else {
      if (mounted) {
        context.read<TutorialProvider>()
            .scheduleTrigger('growth_first_visit', context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, ProgressionProvider>(
      builder: (context, theme, progression, _) {
        final p = theme.paletteData;
        final isAmb = theme.isAmbient;
        final s = context.sL;

        return BwScaffold(
          bottomNavigationBar: const BannerAdWidget(),
          body: SafeArea(
            child: ListView(
            padding: EdgeInsets.fromLTRB(20, isAmb ? 72 : 24, 20, 40),
            children: [

              // ── Header inline ───────────────────────────────────────
              Text(
                isAmb ? s.yourJourney.toLowerCase() : s.yourJourney,
                style: TextStyle(
                  fontSize: isAmb ? 28 : 22,
                  fontWeight: isAmb ? FontWeight.w300 : FontWeight.w700,
                  fontFamily: isAmb ? 'CormorantGaramond' : null,
                  color: p.text,
                  letterSpacing: isAmb ? 1 : 0,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${progression.totalDaysCompleted} ${s.days}',
                style: TextStyle(fontSize: 13, color: p.textSec),
              ),
              const SizedBox(height: 20),

              // ── Companion + fase + messaggio narrativo ──────────────────
              SpotlightTarget(
                id: 'spot_companion_hero',
                child: _CompanionHero(p: p, isAmb: isAmb, progression: progression),
              ),

              const SizedBox(height: 24),

              // ── Timeline fasi orizzontale ───────────────────────────────
              _PhaseTimeline(p: p, isAmb: isAmb, progression: progression),

              const SizedBox(height: 24),

              // ── Card Reward (amber-light) ────────────────────────────────
              _SectionLabel(label: s.rewardsHeader, p: p),
              const SizedBox(height: 8),
              Text(
                s.rewardsHeaderSub,
                style: TextStyle(fontSize: 13, color: p.textSec),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.card,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: p.accent.withValues(alpha: 0.35), width: 1),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: p.accent.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.card_giftcard_rounded, color: p.accent, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.rewards, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text)),
                            const SizedBox(height: 2),
                            Text(s.rewardsLockedDesc, style: TextStyle(fontSize: 12, color: p.textSec)),
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right_rounded, color: p.accent, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 28),

              // ── Heatmap consistenza ──────────────────────────────────────
              SpotlightTarget(
                id: 'spot_heatmap',
                child: _HeatmapSection(p: p, progression: progression),
              ),

              const SizedBox(height: 28),

              // ── Momenti memorabili ───────────────────────────────────────
              _MilestonesSection(p: p, progression: progression),

              const SizedBox(height: 28),

              // ── Percorso Welly ───────────────────────────────────────────
              _WellyJourneySection(p: p, isAmb: isAmb, progression: progression),

              const SizedBox(height: 28),

              // ── Badge ───────────────────────────────────────────────────
              _SectionLabel(label: context.sL.badges, p: p),
              const SizedBox(height: 12),
              SpotlightTarget(
                id: 'spot_badges',
                child: _BadgeGrid(p: p, progression: progression),
              ),
            ],
          ),
          ),
        );
      },
    );
  }
}

// ── Companion Hero ────────────────────────────────────────────────────────────
class _CompanionHero extends StatelessWidget {
  final BwPaletteData p;
  final bool isAmb;
  final ProgressionProvider progression;

  const _CompanionHero({
    required this.p,
    required this.isAmb,
    required this.progression,
  });

  @override
  Widget build(BuildContext context) {
    final phase = progression.currentPhase;
    final s = context.sL;
    final phaseLabel = [
      s.phase1, s.phase2, s.phase3, s.phase4, s.phase5
    ][phase - 1];
    final totalDays = progression.totalDaysCompleted;

    return Column(
      children: [
        const SizedBox(height: 16),
        // Companion grande
        const CompanionWidget(size: 160, showPhase: true),
        const SizedBox(height: 16),
        // Fase
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: p.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${s.phase} $phase — $phaseLabel',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.primaryText,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$totalDays ${s.days}',
          style: TextStyle(fontSize: 12, color: p.textSec),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}


// ── Phase Timeline ────────────────────────────────────────────────────────────
/// Riga orizzontale con 5 fasi collegate da una linea sottile.
class _PhaseTimeline extends StatelessWidget {
  final BwPaletteData p;
  final bool isAmb;
  final ProgressionProvider progression;

  const _PhaseTimeline({
    required this.p,
    required this.isAmb,
    required this.progression,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.sL;
    final currentPhase = progression.currentPhase;
    final phaseNames = [s.phase1, s.phase2, s.phase3, s.phase4, s.phase5];

    // 9 items: phase dot (even indices 0,2,4,6,8) + connecting line (odd 1,3,5,7)
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: List.generate(9, (i) {
        if (i.isOdd) {
          // Linea di connessione tra fasi
          final leftPhase = (i + 1) ~/ 2;
          final isConnected = leftPhase < currentPhase;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 8.5),
              child: Container(
                height: 1.5,
                color: isConnected
                    ? p.primary.withValues(alpha: 0.4)
                    : p.textMut.withValues(alpha: 0.2),
              ),
            ),
          );
        }
        // Dot + etichetta fase
        final phase = (i ~/ 2) + 1;
        final isCurrent = phase == currentPhase;
        final isReached = phase <= currentPhase;
        final isFuture = phase > currentPhase;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 18, height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCurrent
                    ? p.primary
                    : isReached
                        ? p.primary.withValues(alpha: 0.5)
                        : Colors.transparent,
                border: Border.all(
                  color: isFuture
                      ? p.textMut.withValues(alpha: 0.3)
                      : p.primary,
                  width: 1.5,
                ),
              ),
              child: isReached && !isCurrent
                  ? const Center(child: Icon(Icons.check, size: 10, color: Colors.white))
                  : null,
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 44,
              child: Text(
                phaseNames[phase - 1],
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: isFuture
                      ? p.textMut.withValues(alpha: 0.4)
                      : isCurrent
                          ? p.primary
                          : p.textSec,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      }),
    );
  }
}

// ── Badge Grid ────────────────────────────────────────────────────────────────
class _BadgeGrid extends StatelessWidget {
  final BwPaletteData p;
  final ProgressionProvider progression;
  const _BadgeGrid({required this.p, required this.progression});

  @override
  Widget build(BuildContext context) {
    final badges = progression.allBadges(context.sL);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: badges.length,
      itemBuilder: (_, i) => _BadgeTile(badge: badges[i], p: p),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  final BadgeInfo badge;
  final BwPaletteData p;
  const _BadgeTile({required this.badge, required this.p});

  @override
  Widget build(BuildContext context) {
    final s = context.sL;
    // Livello massimo di questa famiglia già raggiunto → tile piena e a colori.
    // Altrimenti è il prossimo obiettivo: emoji smorzata + progresso reale,
    // così l'utente vede sempre cosa manca per sbloccarlo.
    final isMaxed = badge.progress >= badge.target;
    final complete = badge.earned && isMaxed;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: complete ? p.primary.withValues(alpha: 0.4) : p.cardBorder,
          width: complete ? 1 : 0.5,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Opacity(
            opacity: complete ? 1.0 : 0.4,
            child: Text(badge.emoji, style: const TextStyle(fontSize: 28)),
          ),
          const SizedBox(height: 6),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: complete ? p.text : p.textSec,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          if (complete)
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: p.textSec),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            )
          else
            Text(
              '${s.growthNextGoal}: ${badge.progress}/${badge.target}',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 9, color: p.textMut, fontWeight: FontWeight.w600),
            ),
        ],
      ),
    );
  }
}

// ── Heatmap consistenza (TASK 7) ─────────────────────────────────────────────
class _HeatmapSection extends StatefulWidget {
  final BwPaletteData p;
  final ProgressionProvider progression;
  const _HeatmapSection({required this.p, required this.progression});

  @override
  State<_HeatmapSection> createState() => _HeatmapSectionState();
}

class _HeatmapSectionState extends State<_HeatmapSection> {
  // null = tutte; altrimenti ID abitudine
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final s = context.sL;
    final p = widget.p;
    final progression = widget.progression;

    // Filtri disponibili: water, focus_25, null (tutte)
    final tabs = <(String?, String)>[
      (null, s.activeHabits),
      ('water', '💧'),
      ('focus_25', '🎯'),
    ];

    final data = progression.heatmapData(filterHabitId: _filter);
    final maxVal = data.fold<int>(0, (m, v) => v > m ? v : m).clamp(1, 99);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                s.growthConsistency.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                  color: p.textSec,
                ),
              ),
            ),
            // Tab selettore
            ...tabs.map((tab) {
              final selected = _filter == tab.$1;
              return GestureDetector(
                onTap: () => setState(() => _filter = tab.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(left: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: selected ? p.primary : p.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? p.primary : p.cardBorder,
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    tab.$2,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : p.textSec,
                    ),
                  ),
                ),
              );
            }),
          ],
        ),
        const SizedBox(height: 12),
        // Griglia 7×5
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.cardBorder, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Griglia celle
              Row(
                children: List.generate(7, (col) {
                  return Expanded(
                    child: Column(
                      children: List.generate(5, (row) {
                        final idx = row * 7 + col;
                        final val = idx < data.length ? data[idx] : 0;
                        final isToday = idx == data.length - 1;
                        final alpha = val == 0
                            ? 0.08
                            : (val / maxVal).clamp(0.2, 1.0);
                        return Container(
                          margin: const EdgeInsets.all(1.5),
                          width: 14, height: 14,
                          decoration: BoxDecoration(
                            color: p.primary.withValues(alpha: alpha),
                            borderRadius: BorderRadius.circular(2),
                            border: isToday
                                ? Border.all(color: p.primary, width: 0.5)
                                : null,
                          ),
                        );
                      }),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 8),
              // Labels
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(s.heatmapDaysAgo(5),
                      style: TextStyle(fontSize: 9, color: p.textMut)),
                  Text(s.heatmapToday,
                      style: TextStyle(fontSize: 9, color: p.textMut)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Momenti memorabili (TASK 8) ───────────────────────────────────────────────
class _MilestonesSection extends StatelessWidget {
  final BwPaletteData p;
  final ProgressionProvider progression;
  const _MilestonesSection({required this.p, required this.progression});

  @override
  Widget build(BuildContext context) {
    final s = context.sL;
    final total = progression.totalDaysCompleted;

    // Milestone predefinite: (giorni, chiave label, emoji)
    final milestones = <(int, String, String)>[
      (7,   s.milestone7days,   '🌱'),
      (14,  s.milestone14days,  '🌿'),
      (21,  s.milestone21days,  '⭐'),
      (42,  s.milestone42days,  '🌳'),
      (66,  s.milestone66days,  '💎'),
      (100, s.milestone100days, '✨'),
    ];

    // Filtra: mostra solo raggiunte + la prossima non raggiunta
    final visible = <(int, String, String)>[];
    bool nextShown = false;
    for (final m in milestones) {
      if (total >= m.$1) {
        visible.add(m);
      } else if (!nextShown) {
        visible.add(m);
        nextShown = true;
      }
    }

    if (visible.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.growthMoments.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: p.textSec,
          ),
        ),
        const SizedBox(height: 12),
        ...visible.map((m) {
          final reached = total >= m.$1;
          final isNext = !reached;
          final daysLeft = m.$1 - total;
          final install = progression.installDate;
          final reachedDate = install != null && reached
              ? install.add(Duration(days: m.$1))
              : null;

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: reached ? p.primaryLight : p.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: reached ? p.primary.withValues(alpha: 0.3) : p.cardBorder,
                  width: reached ? 1 : 0.5,
                ),
              ),
              child: Row(
                children: [
                  // Dot indicatore
                  Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: reached ? p.primary : Colors.transparent,
                      border: Border.all(
                        color: reached ? p.primary : p.textMut,
                        width: 1.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Emoji
                  Text(m.$3, style: const TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  // Testo
                  Expanded(
                    child: Text(
                      m.$2,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: reached ? FontWeight.w600 : FontWeight.w400,
                        color: reached ? p.text : p.textMut,
                      ),
                    ),
                  ),
                  // Data / giorni mancanti
                  if (reachedDate != null)
                    Text(
                      '${reachedDate.day} ${_monthName(reachedDate.month)}',
                      style: TextStyle(fontSize: 11, color: p.textSec),
                    )
                  else if (isNext)
                    Text(
                      '${s.unlocksIn} ${daysLeft}g',
                      style: TextStyle(fontSize: 11, color: p.textMut),
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  String _monthName(int month) {
    const names = ['', 'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
                       'lug', 'ago', 'set', 'ott', 'nov', 'dic'];
    return names[month.clamp(1, 12)];
  }
}

// ── Percorso Welly (TASK 9) ───────────────────────────────────────────────────
class _WellyJourneySection extends StatelessWidget {
  final BwPaletteData p;
  final bool isAmb;
  final ProgressionProvider progression;
  const _WellyJourneySection({
    required this.p,
    required this.isAmb,
    required this.progression,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.sL;
    final currentPhase = progression.currentPhase;

    const phaseEmojis  = ['🌱', '🌿', '🌾', '🌳', '✨'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.growthWellyJourney.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.5,
            color: p.textSec,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.growthOurJourney,
          style: TextStyle(
            fontSize: isAmb ? 14 : 12,
            fontStyle: isAmb ? FontStyle.italic : FontStyle.normal,
            color: p.textSec,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.cardBorder, width: 0.5),
          ),
          child: Column(
            children: List.generate(5, (i) {
              final phase = i + 1;
              final isCurrent = phase == currentPhase;
              final isReached = phase <= currentPhase;
              final isFuture = phase > currentPhase;
              final phaseDate = isReached ? progression.phaseReachedDate(phase) : null;
              final habitsLeft = isFuture ? progression.habitsUntilPhase(phase) : 0;

              final phaseLabels = [
                s.phase1, s.phase2, s.phase3, s.phase4, s.phase5
              ];

              return Padding(
                padding: EdgeInsets.only(bottom: i < 4 ? 16 : 0),
                child: Row(
                  children: [
                    // Indicatore verticale
                    SizedBox(
                      width: 36,
                      child: Column(
                        children: [
                          // Dot
                          Container(
                            width: 20, height: 20,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isCurrent
                                  ? p.primary
                                  : isReached
                                      ? p.primary.withValues(alpha: 0.4)
                                      : Colors.transparent,
                              border: Border.all(
                                color: isFuture ? p.textMut.withValues(alpha: 0.3) : p.primary,
                                width: 1.5,
                              ),
                            ),
                            child: isReached
                                ? Icon(
                                    isCurrent ? Icons.radio_button_checked : Icons.check,
                                    size: 11,
                                    color: Colors.white,
                                  )
                                : null,
                          ),
                          // Linea verso prossima fase
                          if (i < 4)
                            Container(
                              width: 1.5,
                              height: 20,
                              color: isReached
                                  ? p.primary.withValues(alpha: 0.3)
                                  : p.cardBorder,
                            ),
                        ],
                      ),
                    ),
                    // Emoji fase
                    Text(phaseEmojis[i], style: TextStyle(
                      fontSize: 20,
                      color: isFuture ? p.textMut.withValues(alpha: 0.4) : null,
                    )),
                    const SizedBox(width: 10),
                    // Info fase
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${s.phase} $phase — ${phaseLabels[i]}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                              color: isFuture ? p.textMut.withValues(alpha: 0.4) : p.text,
                            ),
                          ),
                          if (phaseDate != null)
                            Text(
                              phase == 1
                                  ? s.phaseStarted('${phaseDate.day}/${phaseDate.month}')
                                  : s.phaseReached('${phaseDate.day}/${phaseDate.month}'),
                              style: TextStyle(fontSize: 10, color: p.textSec),
                            )
                          else if (isFuture)
                            Text(
                              s.growthHabitsToRoot(habitsLeft),
                              style: TextStyle(fontSize: 10, color: p.textMut.withValues(alpha: 0.4)),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  final BwPaletteData p;
  const _SectionLabel({required this.label, required this.p});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
        color: p.textSec,
      ),
    );
  }
}









