// ─────────────────────────────────────────────────────────────────────────────
//  BeWell — TutorialProvider
//  Gestisce lo stato del sistema tutorial Welly:
//  • quale step è già stato visto (persistito in SharedPreferences)
//  • coda di dialog da mostrare (un solo dialog alla volta)
//  • API trigger() da chiamare nei postFrameCallback di ogni schermata
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/welly_dialog.dart';
import '../data/tutorial_scripts.dart';
import '../widgets/welly_bubble.dart';

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
    _onboardingDone = prefs.getBool('is_onboarded') ?? true;
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
  /// Se un dialog è già visibile, accoda il nuovo.
  void trigger(String eventId, BuildContext context) {
    if (!_initialized) return;
    if (!_onboardingDone) return; // Nessun tutorial prima del completamento onboarding
    if (_seen.contains(eventId)) return;
    if (TutorialScripts.get(eventId) == null) return;

    if (_isShowing) {
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
    _insertOverlay(context, dialog);
  }

  void _insertOverlay(BuildContext context, WellyDialog dialog) {
    // rootOverlay: true → sopra a tutto, incluse bottom sheet e modal
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (_) => WellyBubbleOverlay(
        dialog: dialog,
        onAction: (action) {
          entry.remove();
          _markSeen(dialog.id);

          if (action.isDismiss) {
            // "Salta" — chiude senza catena
            _finishDialog(context);
            return;
          }

          if (action.advance && dialog.nextDialogId != null) {
            // Avanza nella catena
            Future.delayed(const Duration(milliseconds: 320), () {
              if (context.mounted) _showNow(dialog.nextDialogId!, context);
            });
          } else {
            _finishDialog(context);
          }
        },
        onDismiss: () {
          entry.remove();
          _markSeen(dialog.id);
          _finishDialog(context);
        },
      ),
    );

    overlay.insert(entry);
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
