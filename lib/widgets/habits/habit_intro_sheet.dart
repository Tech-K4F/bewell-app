import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';
import '../../models/habit_library.dart';

/// Popup di introduzione nuova abitudine.
/// Mostra due opzioni illustrate affiancate — l'utente sceglie una.
class HabitIntroSheet extends StatelessWidget {
  final HabitDefinition habitA;
  final HabitDefinition habitB;

  const HabitIntroSheet({
    super.key,
    required this.habitA,
    required this.habitB,
  });

  static Future<void> show(
    BuildContext context, {
    required HabitDefinition habitA,
    required HabitDefinition habitB,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => HabitIntroSheet(habitA: habitA, habitB: habitB),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    final isAmb = context.read<ThemeProvider>().isAmbient;

    return Container(
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 24),
            decoration: BoxDecoration(
              color: p.textMut.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Titolo
          Text(
            'È il momento di aggiungere\nqualcosa di nuovo.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: isAmb ? 22 : 18,
              fontWeight: isAmb ? FontWeight.w300 : FontWeight.w600,
              fontFamily: isAmb ? 'CormorantGaramond' : null,
              color: p.text,
              height: 1.3,
            ),
          ),

          const SizedBox(height: 8),

          Text(
            'Scegli dove concentrarti adesso.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: p.textSec),
          ),

          const SizedBox(height: 24),

          // Le due opzioni affiancate
          Row(
            children: [
              Expanded(
                child: _HabitOption(
                  habit: habitA,
                  p: p,
                  isAmb: isAmb,
                  onTap: () => _choose(context, habitA.id),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HabitOption(
                  habit: habitB,
                  p: p,
                  isAmb: isAmb,
                  onTap: () => _choose(context, habitB.id),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // "Altre opzioni" sottotitolo
          GestureDetector(
            onTap: () => _showOthers(context),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'mostrami altre opzioni ›',
                style: TextStyle(
                  fontSize: 12,
                  color: p.textSec,
                  decoration: TextDecoration.underline,
                  decorationColor: p.textSec,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _choose(BuildContext context, String habitId) {
    context.read<ProgressionProvider>().acceptHabit(habitId);
    Navigator.pop(context);
    // Mostra conferma
    final habit = HabitLibrary.findById(habitId);
    if (habit != null) {
      final p = context.read<ThemeProvider>().paletteData;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(habit.coachIntro),
          backgroundColor: p.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showOthers(BuildContext context) {
    context.read<ProgressionProvider>().dismissChoice(habitA.id);
    Navigator.pop(context);
    // TODO: mostra la prossima coppia disponibile
  }
}

class _HabitOption extends StatelessWidget {
  final HabitDefinition habit;
  final BwPaletteData p;
  final bool isAmb;
  final VoidCallback onTap;

  const _HabitOption({
    required this.habit,
    required this.p,
    required this.isAmb,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.cardBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Immagine illustrata
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: Image.asset(
                  habit.imageAsset,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: p.primaryLight,
                    child: Center(
                      child: Icon(Icons.image_outlined,
                          color: p.primary, size: 32),
                    ),
                  ),
                ),
              ),
            ),

            // Nome e descrizione
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    habit.name,
                    style: TextStyle(
                      fontSize: isAmb ? 16 : 14,
                      fontWeight: isAmb ? FontWeight.w300 : FontWeight.w600,
                      fontFamily: isAmb ? 'CormorantGaramond' : null,
                      color: p.text,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    habit.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: p.textSec,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Effort indicator
                  Row(
                    children: [
                      ...List.generate(3, (i) => Padding(
                        padding: const EdgeInsets.only(right: 3),
                        child: Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i < habit.effort.index + 1
                                ? p.primary
                                : p.bg2,
                          ),
                        ),
                      )),
                      const SizedBox(width: 4),
                      Text(
                        _effortLabel(habit.effort),
                        style: TextStyle(fontSize: 9, color: p.textSec),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _effortLabel(HabitEffort e) {
    switch (e) {
      case HabitEffort.low:    return 'facile';
      case HabitEffort.medium: return 'moderato';
      case HabitEffort.high:   return 'impegnativo';
    }
  }
}
