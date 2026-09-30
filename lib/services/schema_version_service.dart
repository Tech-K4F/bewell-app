import 'package:shared_preferences/shared_preferences.dart';

/// Versione dello schema dei dati salvati in locale (SharedPreferences).
/// Oggi non fa nulla di attivo — serve a poter distinguere, in una futura
/// migrazione, un'installazione con dati "vecchia forma" da una pulita,
/// invece di scoprirlo a tentoni con controlli `?? default` sparsi nei
/// provider. Incrementare [current] quando cambia la forma di una chiave
/// esistente, e leggere [installedVersion] per decidere se migrare.
class SchemaVersionService {
  SchemaVersionService._();

  static const int current = 1;
  static const _key = 'schema_version';

  /// Versione con cui i dati locali sono stati scritti l'ultima volta.
  /// 0 = installazione precedente a questo meccanismo (nessuna chiave
  /// ancora scritta) — trattata come "versione 1 implicita", non come
  /// dato mancante, per non triggerare migrazioni fasulle sugli utenti
  /// già installati al momento in cui questo campo è stato introdotto.
  static Future<int> installedVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_key) ?? current;
  }

  static Future<void> markCurrent() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_key, current);
  }
}
