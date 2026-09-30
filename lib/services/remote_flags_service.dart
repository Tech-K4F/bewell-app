import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Interruttori remoti per funzioni non ancora pronte per la produzione
/// (Premium senza un IAP reale collegato, ad rewarded con ID ancora
/// segnaposto) o che potrebbero dover essere spente in fretta senza
/// aspettare il rilascio di una nuova build.
///
/// Letti da `app_config/features` su Firestore, con default SICURI (fuori
/// = false) se il documento manca o la lettura fallisce — un flag remoto
/// assente non deve mai accendere una funzione non pronta.
class RemoteFlagsService {
  RemoteFlagsService._();
  static final RemoteFlagsService instance = RemoteFlagsService._();

  bool _premiumEnabled = false;
  bool _rewardedAdEnabled = false;
  bool _loaded = false;

  bool get premiumEnabled => _premiumEnabled;
  bool get rewardedAdEnabled => _rewardedAdEnabled;

  Future<void> load() async {
    if (_loaded) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('app_config')
          .doc('features')
          .get()
          .timeout(const Duration(seconds: 4));
      final data = doc.data();
      if (data != null) {
        _premiumEnabled = data['premiumEnabled'] == true;
        _rewardedAdEnabled = data['rewardedAdEnabled'] == true;
      }
    } catch (e) {
      debugPrint('RemoteFlagsService load error (uso i default sicuri): $e');
    } finally {
      _loaded = true;
    }
  }
}
