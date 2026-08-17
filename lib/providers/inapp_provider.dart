// ─────────────────────────────────────────────────────────────────────────────
//  BeWell — InAppProvider
//  Gestisce gli item in-app sbloccati dall'utente.
//  Persiste in SharedPreferences: 'unlocked_inapp_items' (List<String>).
//  I punti vengono scalati tramite AppProvider.spendPoints().
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/analytics_service.dart';
import 'app_provider.dart';

const _prefsKey = 'unlocked_inapp_items';

class InAppProvider extends ChangeNotifier {
  Set<String> _unlockedIds = {};

  /// IDs degli item sbloccati.
  Set<String> get unlockedIds => Set.unmodifiable(_unlockedIds);

  /// Restituisce true se l'item con [itemId] è già sbloccato.
  bool isUnlocked(String itemId) => _unlockedIds.contains(itemId);

  // ── Inizializzazione ───────────────────────────────────────────────────────

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getStringList(_prefsKey) ?? [];
    _unlockedIds = stored.toSet();
    notifyListeners();
  }

  // ── Sblocco item ───────────────────────────────────────────────────────────

  /// Sblocca un item in-app scalando i punti tramite [appProvider].
  ///
  /// Restituisce:
  ///   true  → sblocco completato
  ///   false → punti insufficienti oppure item già sbloccato
  Future<bool> unlockItem(
    String itemId,
    int pointsCost,
    AppProvider appProvider,
  ) async {
    // Già sbloccato: niente da fare
    if (_unlockedIds.contains(itemId)) return false;

    // Scala i punti — restituisce false se insufficienti
    final success = await appProvider.spendPoints(pointsCost);
    if (!success) return false;

    // Salva il nuovo item sbloccato
    _unlockedIds = {..._unlockedIds, itemId};
    await _persist();

    AnalyticsService.instance.logInAppPurchase(itemId, pointsCost);
    notifyListeners();
    return true;
  }

  // ── Debug helpers ──────────────────────────────────────────────────────────

  /// Resetta tutti gli sblocchi (solo debug/test).
  Future<void> debugReset() async {
    _unlockedIds = {};
    await _persist();
    notifyListeners();
  }

  // ── Persistenza ───────────────────────────────────────────────────────────

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, _unlockedIds.toList());
  }
}
