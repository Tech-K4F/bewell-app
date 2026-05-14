// ─────────────────────────────────────────────────────────────────────────────
//  BeWell — WellyDialog
//  Modello dati per i dialog tutorial di Welly.
// ─────────────────────────────────────────────────────────────────────────────

/// Umore di Welly nel dialog: determina emoji avatar e colore del ring.
enum TutorialMood { gentle, happy, excited, celebrating, thinking, welcoming }

/// Azione disponibile nel dialog (un pulsante).
class TutorialAction {
  /// Testo del pulsante.
  final String label;

  /// Se true, il pulsante chiude il dialog e passa al nextDialogId (se presente).
  final bool advance;

  /// Se true, chiude il dialog senza catena (bypass del nextDialogId).
  final bool isDismiss;

  const TutorialAction({
    required this.label,
    this.advance = false,
    this.isDismiss = false,
  });

  /// Azione primaria "Capito!" — avanza nella catena o chiude.
  static const ok = TutorialAction(label: 'ok', advance: true);

  /// Azione secondaria "Di più →" — sempre avanza.
  static const more = TutorialAction(label: 'more', advance: true);

  /// Azione dismiss pura (es. "Salta").
  static const skip = TutorialAction(label: 'skip', isDismiss: true);
}

/// Unità minima del tutorial: testo + fact + azioni + catena.
class WellyDialog {
  /// ID univoco — usato per la persistenza "già visto".
  final String id;

  /// Testo principale mostrato nel bubble.
  final String text;

  /// Fatto scientifico opzionale (riga "🔬 ...").
  final String? scienceFact;

  /// Azioni disponibili (ordine = sinistra → destra; il primo è il "primario").
  final List<TutorialAction> actions;

  /// ID del prossimo dialog nella catena (null = fine).
  final String? nextDialogId;

  /// Umore di Welly — determina emoji e accent color.
  final TutorialMood mood;

  /// Auto-dismiss: Duration.zero = mai (richiede tap).
  final Duration autoDismiss;

  const WellyDialog({
    required this.id,
    required this.text,
    this.scienceFact,
    required this.actions,
    this.nextDialogId,
    this.mood = TutorialMood.gentle,
    this.autoDismiss = Duration.zero,
  });

  /// Emoji avatar in base al mood.
  String get moodEmoji {
    switch (mood) {
      case TutorialMood.gentle:      return '🌿';
      case TutorialMood.happy:       return '😊';
      case TutorialMood.excited:     return '✨';
      case TutorialMood.celebrating: return '🎉';
      case TutorialMood.thinking:    return '💭';
      case TutorialMood.welcoming:   return '🤗';
    }
  }
}
