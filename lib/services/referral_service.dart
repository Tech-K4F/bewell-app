import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Gestisce il sistema di inviti: codice personale, redenzione del codice
/// di un amico, e riscossione del bonus punti maturato lato server.
///
/// Schema Firestore:
///   users/{uid}            → { referralCode, referredBy, pendingReferralBonus }
///   referralCodes/{code}   → { uid }   (indice inverso codice → proprietario)
class ReferralService {
  ReferralService._();
  static final instance = ReferralService._();

  // Se cambi questo valore, aggiorna anche il +50 hardcoded nella regola
  // Firestore per users/{uid} (allow update) — non può leggere questa
  // costante Dart, deve restare sincronizzata a mano.
  static const int referralBonusPoints = 50;

  final _db = FirebaseFirestore.instance;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  DocumentReference<Map<String, dynamic>> _userDoc(String uid) =>
      _db.collection('users').doc(uid);

  /// Restituisce il codice invito dell'utente corrente, generandolo
  /// e salvandolo su Firestore alla prima chiamata.
  /// Ritorna null se l'operazione fallisce (rete, permessi) — il chiamante
  /// deve gestire questo caso invece di restare in caricamento per sempre.
  Future<String?> getOrCreateMyCode() async {
    final uid = _uid;
    if (uid == null) return null;

    try {
      final snap = await _userDoc(uid).get();
      final existing = snap.data()?['referralCode'] as String?;
      if (existing != null) return existing;

      final code = _generateCode();
      await _db.collection('referralCodes').doc(code).set({'uid': uid});
      await _userDoc(uid).set({'referralCode': code}, SetOptions(merge: true));
      return code;
    } catch (_) {
      return null;
    }
  }

  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rand = Random();
    return List.generate(6, (_) => chars[rand.nextInt(chars.length)]).join();
  }

  /// Riscatta il codice invito di un amico per l'utente corrente.
  /// Ritorna un messaggio d'errore localizzabile via chiave, o null se ok.
  /// Idempotente: un utente può riscattare un codice una sola volta
  /// (bloccato dal campo `referredBy`, scritto in transazione).
  Future<String?> redeemCode(String rawCode) async {
    final uid = _uid;
    if (uid == null) return 'not_signed_in';
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return 'empty_code';

    final codeDoc = await _db.collection('referralCodes').doc(code).get();
    if (!codeDoc.exists) return 'invalid_code';
    final referrerUid = codeDoc.data()!['uid'] as String;
    if (referrerUid == uid) return 'own_code';

    try {
      await _db.runTransaction((tx) async {
        final myDoc = await tx.get(_userDoc(uid));
        if (myDoc.data()?['referredBy'] != null) {
          throw StateError('already_redeemed');
        }
        tx.set(_userDoc(uid), {'referredBy': referrerUid},
            SetOptions(merge: true));
        tx.set(
          _userDoc(referrerUid),
          {'pendingReferralBonus': FieldValue.increment(referralBonusPoints)},
          SetOptions(merge: true),
        );
      });
      return null;
    } on StateError {
      return 'already_redeemed';
    } catch (_) {
      return 'error';
    }
  }

  /// Da chiamare all'avvio app: se il bonus è maturato (referral accettati
  /// da altri con il mio codice), lo azzera su Firestore e lo ritorna
  /// così il chiamante può accreditarlo localmente con addPoints().
  Future<int> claimPendingBonus() async {
    final uid = _uid;
    if (uid == null) return 0;

    return _db.runTransaction<int>((tx) async {
      final doc = await tx.get(_userDoc(uid));
      final pending = (doc.data()?['pendingReferralBonus'] as num?)?.toInt() ?? 0;
      if (pending <= 0) return 0;
      tx.set(_userDoc(uid), {'pendingReferralBonus': 0}, SetOptions(merge: true));
      return pending;
    });
  }
}
