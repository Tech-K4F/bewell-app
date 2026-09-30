import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

/// Identificatori canale notifiche
class _Channel {
  static const String habits = 'bewell_habits';
  static const String unlocks = 'bewell_unlocks';
  static const String water = 'bewell_water';
}

/// ID notifiche (univoci)
class NotificationIds {
  static const int habitChoice = 99998;
  // Fine sessione Focus (una sola alla volta).
  static const int focusEnd = 99997;
  static int forHabit(String id) => id.hashCode.abs() % 90000 + 10000;
  // Reminder periodici — fascia riservata 100-119 (max 12: oggi e domani).
  static const int reminderBase = 100;
  static const int reminderSlots = 20;
  // ID del VECCHIO sistema di reminder (un solo promemoria acqua + un solo
  // check-in serale, id fissi 1/2) da prima che diventasse multi-slot con
  // frequenza configurabile. flutter_local_notifications schedula allarmi
  // a livello OS che sopravvivono agli aggiornamenti dell'app: chi aveva
  // già l'app installata continuava a ricevere QUESTI oltre ai nuovi
  // (stessa ora, testo nella lingua in cui erano stati schedulati l'ultima
  // volta — da cui il doppio avviso, a volte in due lingue diverse).
  static const int legacyWater = 1;
  static const int legacyEvening = 2;
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
      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('NotificationService requestPermission error: $e');
    }
  }

  /// Su Android 12+ gli allarmi precisi (fine timer Focus) richiedono un
  /// permesso che l'utente concede dalle impostazioni di sistema. Lo chiede
  /// UNA SOLA VOLTA, quando ha senso (apertura del Focus); se rifiuta la fine
  /// sessione arriva comunque, con qualche minuto di margine.
  Future<void> ensureExactAlarms() async {
    if (!_initialized) return;
    try {
      final android = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (android == null) return;
      if (await android.canScheduleExactNotifications() ?? true) return;
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('exact_alarm_asked') ?? false) return;
      await prefs.setBool('exact_alarm_asked', true);
      await android.requestExactAlarmsPermission();
    } catch (e) {
      debugPrint('NotificationService ensureExactAlarms error: $e');
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
      await _plugin.show(
          id, title, body, NotificationDetails(android: androidDetails));
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
      id: NotificationIds.forHabit(habitId),
      title: '🌱 $habitName',
      body: message,
      channel: _Channel.unlocks,
    );
  }

  // ── Promemoria programmati (one-shot) ────────────────────────────────────────
  // Il piano (quanti, quando, con che testo) lo decide SmartReminders: qui c'è
  // solo la programmazione a livello OS di un singolo avviso a una data ora.
  // [exact] chiede un allarme preciso (fine timer Focus), con ripiego su
  // quello inesatto se il permesso non è concesso.
  Future<void> scheduleAt({
    required int id,
    required String title,
    required String body,
    required DateTime at,
    bool exact = false,
    String channel = _Channel.habits,
  }) async {
    if (!_initialized) return;
    final when = tz.TZDateTime.from(at, tz.local);
    if (!when.isAfter(tz.TZDateTime.now(tz.local))) return;
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        channel,
        _channelName(channel),
        channelDescription: _channelDesc(channel),
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        styleInformation: BigTextStyleInformation(body),
      ),
    );
    Future<void> schedule(AndroidScheduleMode mode) => _plugin.zonedSchedule(
          id,
          title,
          body,
          when,
          details,
          androidScheduleMode: mode,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
        );
    try {
      try {
        await schedule(exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle);
      } catch (_) {
        if (!exact) rethrow;
        await schedule(AndroidScheduleMode.inexactAllowWhileIdle);
      }
    } catch (e) {
      debugPrint('NotificationService scheduleAt error: $e');
    }
  }

  Future<void> cancelReminders() async {
    if (!_initialized) return;
    for (var i = 0; i < NotificationIds.reminderSlots; i++) {
      await _plugin.cancel(NotificationIds.reminderBase + i);
    }
    // Migrazione: elimina eventuali allarmi del vecchio sistema (id 1/2)
    // ancora registrati presso l'OS da un'installazione precedente.
    await _plugin.cancel(NotificationIds.legacyWater);
    await _plugin.cancel(NotificationIds.legacyEvening);
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
      case _Channel.unlocks:
        return 'Nuove abitudini';
      case _Channel.water:
        return 'Promemoria acqua';
      default:
        return 'Be Well';
    }
  }

  String _channelDesc(String id) {
    switch (id) {
      case _Channel.unlocks:
        return 'Avvisi quando si sblocca una nuova abitudine';
      case _Channel.water:
        return 'Promemoria per bere acqua durante la giornata';
      default:
        return 'Promemoria abitudini Be Well';
    }
  }
}
