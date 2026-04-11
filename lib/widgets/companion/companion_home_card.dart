import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';
import '../../models/habit_library.dart';
import '../companion/companion_widget.dart';

/// Card compatta per la home che mostra il companion + stato abitudini attive.
/// Cliccando apre GrowthScreen.
class CompanionHomeCard extends StatelessWidget {
  const CompanionHomeCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeProvider, ProgressionProvider>(
      builder: (context, theme, progression, _) {
        final p = theme.paletteData;
        final isAmb = theme.isAmbient;
        final active = progression.activeHabits;
        final message = progression.todayMessage?.text ?? '';
        final phase = progression.currentPhase;

        return GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/growth'),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.cardBorder, width: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Companion animato piccolo
                CompanionWidget(size: 56, mood: CompanionMood.idle),
                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Messaggio coach breve
                      if (message.isNotEmpty)
                        Text(
                          message.length > 60
                              ? '${message.substring(0, 60)}…'
                              : message,
                          style: TextStyle(
                            fontSize: isAmb ? 13 : 12,
                            fontStyle: isAmb
                                ? FontStyle.italic
                                : FontStyle.normal,
                            color: p.text,
                            height: 1.4,
                          ),
                        ),

                      const SizedBox(height: 8),

                      // Abitudini attive — riga di icone con stato
                      if (active.isNotEmpty)
                        Row(
                          children: [
                            ...active.take(5).map((h) {
                              final state = progression.stateOf(h.id);
                              final isToday = state?.lastCompletedAt != null &&
                                  _isToday(state!.lastCompletedAt!);
                              return Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Tooltip(
                                  message: h.name,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isToday
                                          ? p.primary
                                          : p.primaryLight,
                                      border: Border.all(
                                        color: isToday
                                            ? p.primary
                                            : p.cardBorder,
                                        width: 0.5,
                                      ),
                                    ),
                                    child: ClipOval(
                                      child: isToday
                                          ? const Icon(Icons.check,
                                              color: Colors.white, size: 14)
                                          : Image.asset(
                                              h.imageAsset,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  Icon(Icons.spa_outlined,
                                                      color: p.primary,
                                                      size: 14),
                                            ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                            // Fase
                            const Spacer(),
                            Text(
                              'Fase $phase',
                              style: TextStyle(
                                fontSize: 10,
                                color: p.textSec,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                Icon(Icons.chevron_right, color: p.textMut, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}

