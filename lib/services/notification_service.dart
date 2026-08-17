import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Identificatori canale notifiche
class _Channel {
  static const String habits  = 'bewell_habits';
  static const String unlocks = 'bewell_unlocks';
  static const String water   = 'bewell_water';
}

/// ID notifiche (univoci)
class _NId {
  static const int habitChoice    = 99998;
  static int forHabit(String id)  => id.hashCode.abs() % 90000 + 10000;
  // Reminder periodici — fascia riservata 100-119 (max ~7 al giorno).
  static const int reminderBase   = 100;
  static const int reminderSlots  = 20;
  // ID del VECCHIO sistema di reminder (un solo promemoria acqua + un solo
  // check-in serale, id fissi 1/2) da prima che diventasse multi-slot con
  // frequenza configurabile. flutter_local_notifications schedula allarmi
  // a livello OS che sopravvivono agli aggiornamenti dell'app: chi aveva
  // già l'app installata continuava a ricevere QUESTI oltre ai nuovi
  // (stessa ora, testo nella lingua in cui erano stati schedulati l'ultima
  // volta — da cui il doppio avviso, a volte in due lingue diverse).
  static const int legacyWater    = 1;
  static const int legacyEvening  = 2;
}

/// Servizio notifiche locale.
/// Le notifiche IMMEDIATE vengono soppresse se l'app è in foreground
/// (l'UI interna già informa l'utente).
/// Le notifiche SCHEDULATE (acqua, check-in serale) vengono sempre mostrate
/// dall'OS indipendentemente dallo stato dell'app.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;
  bool _inForeground = true; // true = app visibile all'utente

  // ── Lifecycle foreground tracking ────────────────────────────────────────────

  void setForeground(bool value) => _inForeground = value;

  // ── Init ────────────────────────────────────────────────────────────────────

  Future<void> init() async {
    if (_initialized) return;
    try {
      tz_data.initializeTimeZones();

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const settings = InitializationSettings(android: android);
      await _plugin.initialize(settings);

      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService init error: $e');
    }
  }

  // ── Richiesta esplicita permesso (chiamata dall'onboarding, non all'avvio) ──

  Future<void> requestPermission() async {
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('NotificationService requestPermission error: $e');
    }
  }

  // ── Notifica immediata (solo se in background) ───────────────────────────────

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
    String channel = _Channel.habits,
  }) async {
    if (!_initialized || _inForeground) return; // silenzio se app aperta
    try {
      final androidDetails = AndroidNotificationDetails(
        channel,
        _channelName(channel),
        channelDescription: _channelDesc(channel),
        importance: Importance.high,
        priority: Priority.high,
        styleInformation: BigTextStyleInformation(body),
      );
      await _plugin.show(id, title, body,
          NotificationDetails(android: androidDetails));
    } catch (e) {
      debugPrint('NotificationService show error: $e');
    }
  }

  // ── Notifica sblocco abitudine (solo background) ──────────────────────────────

  Future<void> showHabitUnlocked({
    required String habitId,
    required String habitName,
    required String message,
  }) async {
    await showNotification(
      id: _NId.forHabit(habitId),
      title: '🌱 $habitName',
      body: message,
      channel: _Channel.unlocks,
    );
  }

  // ── Reminder giornalieri scheduelati (localizzati) ───────────────────────────
  // Chiamata su cambio lingua, cambio frequenza/pausa nelle impostazioni, o
  // primo avvio. Le notifiche schedulate vengono mostrate dall'OS sempre,
  // indipendentemente dal foreground dell'app.
  //
  // [hours] è la lista di ore (0-23) a cui inviare un reminder — vuota se
  // l'utente ha disattivato le notifiche o è in pausa. Il primo orario usa
  // sempre il messaggio "acqua" (naturalmente mattutino), l'ultimo il
  // messaggio "check-in serale", quelli intermedi il messaggio generico
  // sulle abitudini — così non è più sempre lo stesso testo ripetuto.
  Future<void> scheduleReminders({
    required List<int> hours,
    required String waterTitle,
    required String waterBody,
    required String habitTitle,
    required String habitBody,
    required String eveningTitle,
    required String eveningBody,
  }) async {
    if (!_initialized) return;
    try {
      await cancelReminders();
      if (hours.isEmpty) return;

      for (var i = 0; i < hours.length && i < _NId.reminderSlots; i++) {
        final isFirst = i == 0;
        final isLast = i == hours.length - 1;
        final title = isFirst ? waterTitle : (isLast ? eveningTitle : habitTitle);
        final body = isFirst ? waterBody : (isLast ? eveningBody : habitBody);
        await _scheduleDaily(
          id: _NId.reminderBase + i,
          title: title,
          body: body,
          hour: hours[i],
          minute: 0,
          channel: isFirst ? _Channel.water : _Channel.habits,
        );
      }
    } catch (e) {
      debugPrint('NotificationService scheduleReminders error: $e');
    }
  }

  Future<void> cancelReminders() async {
    if (!_initialized) return;
    for (var i = 0; i < _NId.reminderSlots; i++) {
      await _plugin.cancel(_NId.reminderBase + i);
    }
    // Migrazione: elimina eventuali allarmi del vecchio sistema (id 1/2)
    // ancora registrati presso l'OS da un'installazione precedente.
    await _plugin.cancel(_NId.legacyWater);
    await _plugin.cancel(_NId.legacyEvening);
  }

  Future<void> _scheduleDaily({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channel,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(
        tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    final androidDetails = AndroidNotificationDetails(
      channel,
      _channelName(channel),
      channelDescription: _channelDesc(channel),
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      NotificationDetails(android: androidDetails),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  // ── Cancellazione ────────────────────────────────────────────────────────────

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }

  Future<void> cancel(int id) async {
    if (!_initialized) return;
    await _plugin.cancel(id);
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  String _channelName(String id) {
    switch (id) {
      case _Channel.unlocks: return 'Nuove abitudini';
      case _Channel.water:   return 'Promemoria acqua';
      default:               return 'Be Well';
    }
  }

  String _channelDesc(String id) {
    switch (id) {
      case _Channel.unlocks: return 'Avvisi quando si sblocca una nuova abitudine';
      case _Channel.water:   return 'Promemoria per bere acqua durante la giornata';
      default:               return 'Promemoria abitudini Be Well';
    }
  }
}
