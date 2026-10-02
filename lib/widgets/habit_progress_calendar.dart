import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/habit_library.dart';
import '../providers/progression_provider.dart';
import '../providers/theme_provider.dart';
import '../screens/habits/habits_screen.dart' show habitGoalLabel;

/// Asset "standard" per i riquadri dei singoli giorni — sempre lo stesso,
/// indipendentemente dall'abitudine (come il forziere per il traguardo):
/// ripetere la foto dell'attività 7 volte era ridondante, l'immagine
/// dell'attività la mostra già l'hero band in alto una volta sola.
const String _dayCellAsset = 'assets/images/badges/badge_sprout.jpg';

/// Vista "calendario" del percorso di UNA abitudine verso l'assimilazione
/// (7 giorni) e poi l'automatismo (66 giorni) — prima l'unico modo di
/// vedere questo percorso era il piccolo anello sulla card "Adesso" o un
/// popup di solo testo: qui il traguardo si vede come un oggetto fisico,
/// coerente con i popup di missione/celebrazione già usati altrove.
class HabitProgressCalendar extends StatelessWidget {
  final HabitDefinition habit;
  final int daysCompleted;
  final int? todayCount;
  final int? todayTarget;

  /// Se false, mostra solo il corpo (griglia/arco/stato) senza la banda
  /// hero in alto — usata nel popup di missione, dove l'immagine
  /// dell'attività e il nome sono già mostrati sopra in altra forma.
  final bool showHero;

  /// Versione compatta della banda hero (popup di missione, che deve stare
  /// in una schermata senza scroll): rapporto più largo e, sopra la foto,
  /// un'etichetta in alto a sinistra e un eventuale compagno (Welly) in
  /// basso a destra, al posto di righe separate sopra la banda.
  final double heroAspectRatio;
  final Widget? heroBadge;
  final Widget? heroCompanion;

  const HabitProgressCalendar({
    super.key,
    required this.habit,
    required this.daysCompleted,
    this.todayCount,
    this.todayTarget,
    this.showHero = true,
    this.heroAspectRatio = 5 / 3,
    this.heroBadge,
    this.heroCompanion,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().paletteData;
    final s = context.sL;

    final Widget body;
    if (daysCompleted >= 66) {
      body = _AutomaticState(habit: habit, p: p, s: s);
    } else if (daysCompleted >= 7) {
      body = _LongArcProgress(
          habit: habit, daysCompleted: daysCompleted, p: p, s: s);
    } else {
      body = _WeekGrid(daysCompleted: daysCompleted, p: p, s: s);
    }

    if (!showHero) return body;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroBand(
          habit: habit,
          habitName: s.habitName(habit.id),
          goalLabel: habitGoalLabel(s, daysCompleted,
              todayCount: todayCount, todayTarget: todayTarget),
          p: p,
          aspectRatio: heroAspectRatio,
          badge: heroBadge,
          companion: heroCompanion,
        ),
        SizedBox(height: heroCompanion != null ? 14 : 18),
        body,
      ],
    );
  }
}

// ── Banda hero: unica immagine dell'attività, in alto ──────────────────────────
class _HeroBand extends StatelessWidget {
  final HabitDefinition habit;
  final String habitName;
  final String goalLabel;
  final BwPaletteData p;
  final double aspectRatio;
  final Widget? badge;
  final Widget? companion;
  const _HeroBand({
    required this.habit,
    required this.habitName,
    required this.goalLabel,
    required this.p,
    required this.aspectRatio,
    this.badge,
    this.companion,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(habit.imageAsset,
                fit: BoxFit.cover,
                alignment: habit.imageAlignment,
                errorBuilder: (_, __, ___) => Container(color: p.bg2)),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.68),
                  ],
                  stops: const [0.35, 1.0],
                ),
              ),
            ),
            if (badge != null) Positioned(top: 10, left: 10, child: badge!),
            if (companion != null)
              Positioned(right: 10, bottom: 8, child: companion!),
            Positioned(
              left: 14,
              right: companion != null ? 86 : 14,
              bottom: 12,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    habitName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    goalLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Settimana 1-7: griglia giornaliera ────────────────────────────────────────
class _WeekGrid extends StatelessWidget {
  final int daysCompleted;
  final BwPaletteData p;
  final BwStrings s;
  const _WeekGrid(
      {required this.daysCompleted, required this.p, required this.s});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(s.calendarTowardAssimilated,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: p.text)),
            Text('$daysCompleted / 7',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: p.textSec)),
          ],
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          children: List.generate(7, (i) {
            final day = i + 1;
            final done = day <= daysCompleted;
            final isToday = day == daysCompleted + 1;
            return _DayCell(
              day: day,
              state: done
                  ? _DayState.done
                  : isToday
                      ? _DayState.today
                      : _DayState.locked,
              p: p,
            );
          }),
        ),
        const SizedBox(height: 14),
        _MilestoneCard(
          icon: 'assets/images/badges/badge_treasure_chest.jpg',
          tag: daysCompleted >= 6
              ? s.calendarMilestoneSoon
              : s.calendarMilestoneInDays(7 - daysCompleted),
          title: s.calendarAssimilatedTitle,
          subtitle: s.calendarAssimilatedSub,
          points: pointsForConsolidation,
          p: p,
          s: s,
        ),
      ],
    );
  }
}

// ── Fase 7-66: arco lungo, condensato ──────────────────────────────────────────
class _LongArcProgress extends StatelessWidget {
  final HabitDefinition habit;
  final int daysCompleted;
  final BwPaletteData p;
  final BwStrings s;
  const _LongArcProgress(
      {required this.habit,
      required this.daysCompleted,
      required this.p,
      required this.s});

  @override
  Widget build(BuildContext context) {
    final ratio = ((daysCompleted - 7) / (66 - 7)).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(s.calendarTowardAutomatic,
                style: TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w700, color: p.text)),
            Text('$daysCompleted / 66',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: p.textSec)),
          ],
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 14,
            backgroundColor: p.bg2,
            color: p.primary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          s.calendarLongArcNote,
          style: TextStyle(fontSize: 11.5, color: p.textMut, height: 1.4),
        ),
        const SizedBox(height: 14),
        _MilestoneCard(
          icon: 'assets/images/badges/badge_trophy.jpg',
          tag: s.calendarMilestoneInDays(66 - daysCompleted),
          title: s.calendarAutomaticTitle,
          subtitle: s.calendarAutomaticSub,
          points: pointsForAutomatic,
          p: p,
          s: s,
        ),
      ],
    );
  }
}

// ── Automatica: traguardo raggiunto ────────────────────────────────────────────
class _AutomaticState extends StatelessWidget {
  final HabitDefinition habit;
  final BwPaletteData p;
  final BwStrings s;
  const _AutomaticState(
      {required this.habit, required this.p, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: p.primaryLight,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text('💚', style: TextStyle(fontSize: 32)),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.calendarDoneTitle,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: p.primaryText)),
                const SizedBox(height: 3),
                Text(s.calendarDoneSub(habit.points),
                    style: TextStyle(fontSize: 12, color: p.textSec)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Componenti condivisi ───────────────────────────────────────────────────────
enum _DayState { done, today, locked }

class _DayCell extends StatelessWidget {
  final int day;
  final _DayState state;
  final BwPaletteData p;
  const _DayCell({
    required this.day,
    required this.state,
    required this.p,
  });

  @override
  Widget build(BuildContext context) {
    final done = state == _DayState.done;
    final today = state == _DayState.today;
    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: done ? p.primaryLight : p.bg2,
              border: today
                  ? Border.all(color: p.accent, width: 2.5)
                  : Border.all(color: Colors.transparent, width: 2.5),
              boxShadow: today
                  ? [
                      BoxShadow(
                          color: p.accent.withValues(alpha: 0.35),
                          blurRadius: 10,
                          spreadRadius: 1),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Opacity(
                opacity: state == _DayState.locked ? 0.35 : 1.0,
                child: ColorFiltered(
                  colorFilter: state == _DayState.locked
                      ? const ColorFilter.mode(
                          Colors.grey, BlendMode.saturation)
                      : const ColorFilter.mode(
                          Colors.transparent, BlendMode.multiply),
                  child: Image.asset(_dayCellAsset,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(color: p.bg2)),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          left: 6,
          child: Text(
            '$day',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: today ? p.accent : (done ? p.primary : p.textMut),
              shadows: const [Shadow(color: Colors.black38, blurRadius: 3)],
            ),
          ),
        ),
        if (done)
          Positioned(
            bottom: 4,
            right: 5,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: p.primary,
              ),
              child: const Icon(Icons.check, size: 11, color: Colors.white),
            ),
          ),
      ],
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final String icon;
  final String tag;
  final String title;
  final String subtitle;
  final int points;
  final BwPaletteData p;
  final BwStrings s;
  const _MilestoneCard({
    required this.icon,
    required this.tag,
    required this.title,
    required this.subtitle,
    required this.points,
    required this.p,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [p.accent.withValues(alpha: 0.15), p.card],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.accent.withValues(alpha: 0.6), width: 1.5),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.asset(icon,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(width: 52, height: 52, color: p.bg2)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tag,
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: p.accent)),
                const SizedBox(height: 2),
                Text(title,
                    style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: p.text)),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11.5, color: p.textSec, height: 1.3)),
                const SizedBox(height: 5),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('⭐', style: TextStyle(fontSize: 11)),
                    const SizedBox(width: 4),
                    Text('+$points ${s.points}',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: p.pointsText)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
