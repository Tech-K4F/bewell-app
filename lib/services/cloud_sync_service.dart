import 'dart:async';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Salva e ripristina il progresso dell'utente (giorni, streak, punti,
/// abitudini sbloccate, orari, preferenze) su Firestore, così non si perde con
/// un telefono nuovo, una reinstallazione o dati cancellati.
///
/// Il progresso vive in SharedPreferences; qui se ne fa una copia in un unico
/// documento `users/{uid}/private/progress` (testo JSON: ogni chiave con il
/// suo tipo). Si scrive solo se qualcosa è cambiato, all'uscita dall'app e a
/// intervalli. Si ripristina solo su un'installazione "vuota" (mai completato
/// l'ingresso di Welly), mai sopra progressi locali esistenti.
class CloudSyncService {
  CloudSyncService._();
  static final instance = CloudSyncService._();

  /// Chiavi che NON seguono l'utente: dipendono dal dispositivo o sono
  /// transitorie. Tutto il resto viene sincronizzato.
  static const _deviceOnly = <String>{
    'schema_version',
    'exact_alarm_asked',
    'smart_reminder_input',
    'auth_failed_attempts',
    'auth_lock_until_ms',
    'debug_enabled',
    'debug_day_offset',
    'notif_snooze_until',
    'last_open_at',
    'notif_invite_dismissed_at',
    'focus_pending_end',
    'focus_pending_habit',
    'cloud_sync_hash',
  };

  /// Chiavi che restano sul dispositivo anche dopo logout o reset totale.
  static const _keepOnWipe = <String>{
    'schema_version',
    'app_locale',
    'bw_style',
    'bw_palette',
    'setting_large_text',
    'setting_high_contrast',
    'setting_reduce_motion',
  };

  static const _version = 1;
  String? _lastHash;
  Timer? _timer;

  DocumentReference<Map<String, dynamic>>? _doc() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return null;
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('private')
        .doc('progress');
  }

  // ── Istantanea locale ──────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _snapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final out = <String, dynamic>{};
    for (final k in prefs.getKeys()) {
      if (_deviceOnly.contains(k)) continue;
      final v = prefs.get(k);
      if (v is bool) {
        out[k] = {'t': 'b', 'v': v};
      } else if (v is int) {
        out[k] = {'t': 'i', 'v': v};
      } else if (v is double) {
        out[k] = {'t': 'd', 'v': v};
      } else if (v is String) {
        out[k] = {'t': 's', 'v': v};
      } else if (v is List<String>) {
        out[k] = {'t': 'l', 'v': v};
      }
    }
    return out;
  }

  // ── Scrittura ──────────────────────────────────────────────────────────────

  /// Scrive su Firestore se il contenuto è cambiato dall'ultima volta.
  /// Non solleva mai: un errore di rete non deve disturbare l'utente.
  Future<void> pushIfChanged() async {
    try {
      final doc = _doc();
      if (doc == null) return;
      final prefs = await SharedPreferences.getInstance();
      // Non salvare mai uno stato vuoto sopra uno vero: un'installazione
      // appena fatta non deve cancellare il cloud prima del ripristino.
      if (!(prefs.getBool('welly_welcomed') ?? false)) return;
      final snap = await _snapshot();
      final encoded = jsonEncode(snap);
      final hash = encoded.hashCode.toString();
      _lastHash ??= prefs.getString('cloud_sync_hash');
      if (hash == _lastHash) return;
      await doc.set({
        'v': _version,
        'data': encoded,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      _lastHash = hash;
      await prefs.setString('cloud_sync_hash', hash);
    } catch (e) {
      debugPrint('CloudSync push error: $e');
    }
  }

  /// Salvataggio periodico mentre l'app è aperta.
  void startAutoSync({Duration every = const Duration(minutes: 2)}) {
    _timer?.cancel();
    _timer = Timer.periodic(every, (_) => pushIfChanged());
  }

  void stopAutoSync() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Ripristino ─────────────────────────────────────────────────────────────

  /// Se questa installazione è vuota e nel cloud c'è un progresso, lo
  /// riporta sul dispositivo. Ritorna true se ha ripristinato qualcosa (il
  /// chiamante deve allora ricaricare lo stato dell'app).
  Future<bool> restoreIfFresh() async {
    try {
      final doc = _doc();
      if (doc == null) return false;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('welly_welcomed') ?? false) return false;
      final snap = await doc.get(const GetOptions(source: Source.server));
      final raw = snap.data()?['data'];
      if (raw is! String || raw.isEmpty) return false;
      final map = jsonDecode(raw) as Map<String, dynamic>;
      for (final e in map.entries) {
        if (_deviceOnly.contains(e.key) || _keepOnWipe.contains(e.key)) {
          continue;
        }
        final t = (e.value as Map)['t'];
        final v = (e.value as Map)['v'];
        switch (t) {
          case 'b':
            await prefs.setBool(e.key, v as bool);
          case 'i':
            await prefs.setInt(e.key, (v as num).toInt());
          case 'd':
            await prefs.setDouble(e.key, (v as num).toDouble());
          case 's':
            await prefs.setString(e.key, v as String);
          case 'l':
            await prefs.setStringList(e.key, (v as List).cast<String>());
        }
      }
      return true;
    } catch (e) {
      debugPrint('CloudSync restore error: $e');
      return false;
    }
  }

  // ── Cancellazione ──────────────────────────────────────────────────────────

  /// Elimina la copia nel cloud (reset totale, cancellazione account).
  Future<void> deleteRemote() async {
    try {
      await _doc()?.delete();
    } catch (e) {
      debugPrint('CloudSync delete error: $e');
    }
    _lastHash = null;
  }

  /// Svuota i dati locali dell'utente; restano lingua e aspetto.
  Future<void> wipeLocal() async {
    final prefs = await SharedPreferences.getInstance();
    for (final k in prefs.getKeys().toList()) {
      if (_keepOnWipe.contains(k)) continue;
      await prefs.remove(k);
    }
    _lastHash = null;
  }

  /// Logout: l'ultima copia al sicuro nel cloud, poi dispositivo pulito
  /// (così un altro account non eredita i progressi di questo).
  Future<void> onLogout() async {
    stopAutoSync();
    await pushIfChanged();
    await wipeLocal();
  }

  /// Reset totale richiesto dall'utente: cloud + dispositivo, come primo uso.
  Future<void> resetEverything() async {
    stopAutoSync();
    await deleteRemote();
    await wipeLocal();
  }
}
