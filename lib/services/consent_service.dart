import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:app_tracking_transparency/app_tracking_transparency.dart';

/// Consenso pubblicitario (UMP/GDPR per l'UE, ATT per iOS) — richiesto
/// PRIMA di inizializzare AdMob, non dopo. Prima gli ad si caricavano
/// incondizionatamente: rischio concreto di violazione delle policy Play
/// Store per il traffico UE, dato che l'app è italiana.
class ConsentService {
  ConsentService._();
  static final ConsentService instance = ConsentService._();

  /// Richiede il consenso UMP (mostra il form solo se l'utente si trova
  /// in una regione che lo richiede, es. SEE/UK — la logica geografica è
  /// gestita interamente da Google, non replicata qui) e, su iOS, il
  /// permesso di tracciamento ATT. Va chiamata prima di
  /// [MobileAds.instance.initialize].
  Future<void> requestConsent() async {
    await _requestUmpConsent();
    if (Platform.isIOS) {
      await _requestAtt();
    }
  }

  Future<void> _requestUmpConsent() async {
    final params = ConsentRequestParameters();
    final completer = Completer<void>();

    ConsentInformation.instance.requestConsentInfoUpdate(
      params,
      () async {
        try {
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            await _loadAndShowForm();
          }
        } catch (e) {
          debugPrint('ConsentService UMP form error: $e');
        } finally {
          if (!completer.isCompleted) completer.complete();
        }
      },
      (FormError error) {
        debugPrint('ConsentService UMP update error: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );

    // Non blocca l'avvio dell'app oltre un tempo ragionevole se Google non
    // risponde (rete lenta/assente) — meglio inizializzare gli ad in modalità
    // non personalizzata di default che bloccare l'avvio a tempo indefinito.
    await completer.future.timeout(
      const Duration(seconds: 5),
      onTimeout: () {},
    );
  }

  Future<void> _loadAndShowForm() {
    final completer = Completer<void>();
    ConsentForm.loadConsentForm(
      (ConsentForm form) async {
        final status = await ConsentInformation.instance.getConsentStatus();
        if (status == ConsentStatus.required) {
          form.show((FormError? error) {
            if (!completer.isCompleted) completer.complete();
          });
        } else {
          if (!completer.isCompleted) completer.complete();
        }
      },
      (FormError error) {
        debugPrint('ConsentService loadConsentForm error: ${error.message}');
        if (!completer.isCompleted) completer.complete();
      },
    );
    return completer.future;
  }

  Future<void> _requestAtt() async {
    try {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        // Piccolo delay: Apple raccomanda di non mostrare il prompt ATT
        // nell'istante esatto di avvio dell'app, quando l'utente non ha
        // ancora contesto su cosa sta guardando.
        await Future.delayed(const Duration(milliseconds: 400));
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    } catch (e) {
      debugPrint('ConsentService ATT error: $e');
    }
  }
}
