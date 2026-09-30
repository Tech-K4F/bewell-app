import 'package:flutter/material.dart';
import '../models/habit_library.dart';

/// Immagine base di un'attività come banda in cima alla sua schermata
/// dedicata (respirazione, Focus, sequenze guidate): la stessa immagine
/// che l'utente ha visto nella scheda dell'attività, così passare dalla
/// lista alla schermata dà continuità. Il ritaglio tiene in vista la testa
/// (vedi [HabitDefinition.imageAlignment]).
class HabitHeroBand extends StatelessWidget {
  final String habitId;
  final double aspectRatio;

  const HabitHeroBand({
    super.key,
    required this.habitId,
    this.aspectRatio = 2.3,
  });

  @override
  Widget build(BuildContext context) {
    final habit = HabitLibrary.findById(habitId);
    if (habit == null) return const SizedBox.shrink();
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: aspectRatio,
        child: Image.asset(
          habit.imageAsset,
          fit: BoxFit.cover,
          alignment: habit.imageAlignment,
          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
        ),
      ),
    );
  }
}
