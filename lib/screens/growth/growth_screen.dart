import 'package:flutter/material.dart' hide Badge;
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';
import '../../models/habit_library.dart';
import '../../widgets/companion/companion_widget.dart';
import '../../widgets/bw_scaffold.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations.dart';
import '../../l10n/app_localizations.dart';

class GrowthScreen extends StatelessWidget {
  const GrowthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, ProgressionProvider>(
      builder: (context, theme, progression, _) {
        final p = theme.paletteData;
        final isAmb = theme.isAmbient;
        final s = context.sL;

        return BwScaffold(
          appBar: AppBar(
            backgroundColor: p.bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: p.text, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              isAmb ? context.sL.yourJourney : context.sL.yourJourney,
              style: TextStyle(
                color: p.text,
                fontSize: isAmb ? 22 : 17,
                fontWeight: isAmb ? FontWeight.w300 : FontWeight.w600,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [

              // ── Companion + fase ────────────────────────────────────────
              _CompanionHero(p: p, isAmb: isAmb, progression: progression),

              const SizedBox(height: 28),

              // ── Messaggio coach ─────────────────────────────────────────
              if (progression.todayMessage != null)
                _CoachCard(
                  message: progression.todayMessage!.text,
                  p: p,
                  isAmb: isAmb,
                ),

              const SizedBox(height: 24),

              // ── Abitudini attive ────────────────────────────────────────
              _SectionLabel(label: context.sL.activeHabits, p: p),
              const SizedBox(height: 12),
              ...progression.activeHabits.map((h) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _HabitRow(
                    habit: h,
                    state: progression.stateOf(h.id)!,
                    p: p,
                    isAmb: isAmb,
                    onComplete: () => progression.markCompleted(h.id),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ── Prossimo sblocco ────────────────────────────────────────
              _NextUnlock(p: p, isAmb: isAmb, progression: progression),

              const SizedBox(height: 24),

              // ── Badge ───────────────────────────────────────────────────
              _SectionLabel(label: context.sL.badges, p: p),
              const SizedBox(height: 12),
              _BadgeGrid(p: p, progression: progression),
            ],
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
        CompanionWidget(size: 160, showPhase: true),
        const SizedBox(height: 16),
        // Fase
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
          decoration: BoxDecoration(
            color: p.primaryLight,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Fase $phase — $phaseLabel',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: p.primaryText,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$totalDays giorni di abitudini',
          style: TextStyle(fontSize: 12, color: p.textSec),
        ),
        const SizedBox(height: 16),
        // Barra progressione verso prossima fase
        _PhaseProgressBar(p: p, progression: progression),
      ],
    );
  }
}

class _PhaseProgressBar extends StatelessWidget {
  final BwPaletteData p;
  final ProgressionProvider progression;
  const _PhaseProgressBar({required this.p, required this.progression});

  @override
  Widget build(BuildContext context) {
    final progress = progression.phaseProgress; // 0.0 - 1.0
    final phase = progression.currentPhase;
    if (phase >= 5) return const SizedBox();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Fase $phase', style: TextStyle(fontSize: 10, color: p.textSec)),
            Text('Fase ${phase + 1}', style: TextStyle(fontSize: 10, color: p.textSec)),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: p.bg2,
            color: p.primary,
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ── Coach Card ────────────────────────────────────────────────────────────────
class _CoachCard extends StatelessWidget {
  final String message;
  final BwPaletteData p;
  final bool isAmb;
  const _CoachCard({required this.message, required this.p, required this.isAmb});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: p.primaryLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.primary.withValues(alpha: 0.2), width: 0.5),
      ),
      child: Row(
        children: [
          // Mini companion
          CompanionWidget(size: 40, mood: CompanionMood.idle),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: isAmb ? 15 : 13,
                fontWeight: isAmb ? FontWeight.w300 : FontWeight.w400,
                color: p.text,
                height: 1.5,
                fontStyle: isAmb ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Habit Row ─────────────────────────────────────────────────────────────────
class _HabitRow extends StatelessWidget {
  final HabitDefinition habit;
  final HabitState state;
  final BwPaletteData p;
  final bool isAmb;
  final VoidCallback onComplete;

  const _HabitRow({
    required this.habit,
    required this.state,
    required this.p,
    required this.isAmb,
    required this.onComplete,
  });

  @override
  Widget build(BuildContext context) {
    final isCompletedToday = state.lastCompletedAt != null &&
        _isToday(state.lastCompletedAt!);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isCompletedToday ? p.primaryLight : p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isCompletedToday ? p.primary : p.cardBorder,
          width: isCompletedToday ? 1 : 0.5,
        ),
      ),
      child: Row(
        children: [
          // Immagine habit
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.asset(
              habit.imageAsset,
              width: 44,
              height: 44,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: p.primaryLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.spa_outlined, color: p.primary, size: 20),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isAmb ? FontWeight.w300 : FontWeight.w600,
                    color: p.text,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      state.statusEmoji,
                      style: const TextStyle(fontSize: 12),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${state.daysCompleted} giorni',
                      style: TextStyle(fontSize: 11, color: p.textSec),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Check button
          GestureDetector(
            onTap: isCompletedToday ? null : onComplete,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompletedToday ? p.primary : Colors.transparent,
                border: Border.all(
                  color: isCompletedToday ? p.primary : p.textMut,
                  width: 1.5,
                ),
              ),
              child: isCompletedToday
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

// ── Next Unlock ───────────────────────────────────────────────────────────────
class _NextUnlock extends StatelessWidget {
  final BwPaletteData p;
  final bool isAmb;
  final ProgressionProvider progression;

  const _NextUnlock({
    required this.p,
    required this.isAmb,
    required this.progression,
  });

  @override
  Widget build(BuildContext context) {
    final next = progression.nextHabitToUnlock;
    final s = context.sL;
    if (next == null) return const SizedBox();

    final daysLeft = progression.daysUntilUnlock(next.id);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel(label: context.sL.nextUnlock, p: p),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.cardBorder, width: 0.5),
          ),
          child: Row(
            children: [
              // Immagine sfocata/bloccata
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: ColorFiltered(
                      colorFilter: const ColorFilter.mode(
                        Colors.grey,
                        BlendMode.saturation,
                      ),
                      child: Image.asset(
                        next.imageAsset,
                        width: 52,
                        height: 52,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: p.bg2,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: p.bg.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.lock_outline,
                          color: p.textMut, size: 18),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      next.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: p.textSec,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      daysLeft > 0
                          ? 'Tra $daysLeft giorni'
                          : s.almostReady,
                      style: TextStyle(fontSize: 11, color: p.textMut),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
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
    final badges = progression.earnedBadges;
    if (badges.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          context.sL.noBadgesYet,
          style: TextStyle(fontSize: 13, color: p.textMut),
        ),
      );
    }

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
  final BwBadge badge;
  final BwPaletteData p;
  const _BadgeTile({required this.badge, required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.cardBorder, width: 0.5),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(badge.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 6),
          Text(
            badge.name,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: p.text,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            badge.description,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: p.textSec),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
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









