// ─────────────────────────────────────────────────────────────────────────────
//  BeWell — TutorialProvider
//  Gestisce i dialoghi contestuali di Welly (streak, sblocchi, milestone…):
//  • quale evento è già stato visto (persistito in SharedPreferences)
//  • coda di eventi da mostrare (uno alla volta)
//  • API trigger() da chiamare nei postFrameCallback di ogni schermata
//
//  Il rendering passa dallo stesso SpotlightController usato dai tour
//  guidati — un solo motore, per evitare due overlay che possano
//  sovrapporsi o competere per lo schermo.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/welly_dialog.dart';
import '../data/tutorial_scripts.dart';
import '../l10n/app_localizations.dart';
import '../widgets/spotlight_overlay.dart';

class TutorialProvider extends ChangeNotifier {
  // ── Stato ─────────────────────────────────────────────────────────────────

  final Set<String> _seen = {};
  final List<String> _queue = [];
  bool _initialized = false;
  bool _isShowing = false;

  /// True se l'onboarding è stato completato — i tutorial sono bloccati prima.
  bool _onboardingDone = false;

  // ── Getters ───────────────────────────────────────────────────────────────

  bool get initialized => _initialized;
  bool get isShowing => _isShowing;

  /// True se il dialog [id] è già stato visto dall'utente.
  bool hasSeen(String id) => _seen.contains(id);

  // ── Init ──────────────────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final seenList = prefs.getStringList('tutorial_seen') ?? [];
    _seen.addAll(seenList);
    // Default false, NON true: su un'installazione pulita 'is_onboarded'
    // non esiste ancora — un default true disattivava il cancello "nessun
    // tutorial prima dell'onboarding" fin dal primissimo istante, lasciando
    // passare dialoghi contestuali (es. focus_unlocked) prima che l'utente
    // avesse anche solo iniziato il carosello di benvenuto.
    _onboardingDone = prefs.getBool('is_onboarded') ?? false;
    _initialized = true;
    notifyListeners();
  }

  /// Chiamato da OnboardingProvider.confirmPlan() al termine dell'onboarding.
  /// Abilita i trigger tutorial per questa sessione senza attendere il prossimo init().
  void markOnboardingDone() {
    _onboardingDone = true;
  }

  // ── Trigger pubblico ──────────────────────────────────────────────────────

  /// Mostra il dialog [eventId] se non già visto.
  /// Sicuro da chiamare da postFrameCallback o initState.
  /// Se un dialog è già visibile — o se è attivo un tour guidato sulla stessa
  /// SpotlightOverlay — accoda il nuovo evento invece di sovrapporlo.
  void trigger(String eventId, BuildContext context) {
    if (!_initialized) return;
    if (!_onboardingDone) return; // Nessun tutorial prima del completamento onboarding
    if (_seen.contains(eventId)) return;
    if (TutorialScripts.get(eventId) == null) return;

    final ctrl = context.read<SpotlightController>();
    if (_isShowing || ctrl.isActive) {
      if (!_queue.contains(eventId)) _queue.add(eventId);
      return;
    }

    _showNow(eventId, context);
  }

  /// Variante sicura da usare inside build() — schedula il trigger dopo il frame.
  /// Se il provider non è ancora inizializzato (SharedPreferences in caricamento),
  /// riprova al frame successivo finché l'init non è completo.
  void scheduleTrigger(String eventId, BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!context.mounted) return;
      if (!_initialized) {
        // Riprova al prossimo frame
        scheduleTrigger(eventId, context);
        return;
      }
      trigger(eventId, context);
    });
  }

  // ── Implementazione interna ───────────────────────────────────────────────

  void _showNow(String eventId, BuildContext context) {
    final dialog = TutorialScripts.get(eventId);
    if (dialog == null) {
      _markSeen(eventId);
      return;
    }
    _isShowing = true;
    final ctrl = context.read<SpotlightController>();
    final s = context.sL;
    ctrl.startTutorial(
      eventId,
      [_stepFromDialog(dialog, s, context)],
      persist: false, // la persistenza "già visto" è gestita qui sotto
    );
  }

  SpotlightStep _stepFromDialog(WellyDialog dialog, BwStrings s, BuildContext context) {
    final localizedText = s.tutorialText(dialog.id);
    final displayText = localizedText.isNotEmpty ? localizedText : dialog.text;
    final localizedFact = s.tutorialFact(dialog.id);

    return SpotlightStep(
      text: displayText,
      fact: (localizedFact != null && localizedFact.isNotEmpty) ? localizedFact : null,
      moodEmoji: dialog.moodEmoji,
      celebrating: dialog.mood == TutorialMood.celebrating,
      actions: [
        for (int i = 0; i < dialog.actions.length; i++)
          SpotlightAction(
            label: _resolveActionLabel(dialog.actions[i].label, s),
            isPrimary: i == 0,
            onTap: () => _handleAction(dialog, dialog.actions[i], context),
          ),
      ],
      onClose: () => _handleDismiss(dialog, context),
    );
  }

  void _handleDismiss(WellyDialog dialog, BuildContext context) {
    _markSeen(dialog.id);
    _closeAndAdvanceQueue(context);
  }

  void _handleAction(WellyDialog dialog, TutorialAction action, BuildContext context) {
    _markSeen(dialog.id);

    if (!action.isDismiss && action.advance && dialog.nextDialogId != null) {
      // Avanza nella catena — sostituisce lo step corrente mantenendo
      // l'overlay attivo, senza fade-out/fade-in intermedio.
      Future.delayed(const Duration(milliseconds: 320), () {
        if (context.mounted) _showNow(dialog.nextDialogId!, context);
      });
      return;
    }

    _closeAndAdvanceQueue(context);
  }

  void _closeAndAdvanceQueue(BuildContext context) {
    if (context.mounted) context.read<SpotlightController>().skip();
    _finishDialog(context);
  }

  /// Risolve il tasto di azione dalla chiave ('ok'/'more'/'skip') alla stringa localizzata.
  static String _resolveActionLabel(String key, BwStrings s) {
    switch (key) {
      case 'ok':   return s.tutorialOk;
      case 'more': return s.tutorialMore;
      case 'skip': return s.tutorialSkip;
      default:     return key;
    }
  }

  void _finishDialog(BuildContext context) {
    _isShowing = false;
    // Processa il prossimo nella coda, se presente
    if (_queue.isNotEmpty && context.mounted) {
      final nextId = _queue.removeAt(0);
      Future.delayed(const Duration(milliseconds: 400), () {
        if (context.mounted) _showNow(nextId, context);
      });
    }
  }

  Future<void> _markSeen(String id) async {
    _seen.add(id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('tutorial_seen', _seen.toList());
  }

  /// Marca [eventId] come già visto senza mostrarlo — usato quando un tour
  /// guidato (SpotlightController) copre lo stesso contenuto di un dialogo
  /// Welly "vecchio stile", per evitare che quest'ultimo si presenti comunque
  /// alla visita successiva. Le schermate scrivevano prima direttamente una
  /// chiave SharedPreferences (`tutorial_seen_ID`) che questo provider non
  /// ha mai letto — il dialogo tornava comunque a comparire.
  Future<void> markSeenExternally(String eventId) => _markSeen(eventId);

  // ── Reset (debug / settings) ──────────────────────────────────────────────

  Future<void> resetAll() async {
    _seen.clear();
    _queue.clear();
    _isShowing = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('tutorial_seen');
    notifyListeners();
  }

  /// Segna un singolo step come già visto (per skip selettivo).
  Future<void> skip(String eventId) async {
    await _markSeen(eventId);
  }
}
