import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../l10n/app_localizations.dart';
import '../providers/theme_provider.dart';
import '../services/notification_service.dart';

/// Invito a riattivare i promemoria quando il sistema li ha disattivati.
/// Compare in Abitudini (e solo lì) ogni tanto: se l'utente sceglie "Non ora"
/// resta nascosto per 3 giorni. Non compare se ha scelto lui "Off" nelle
/// impostazioni: in quel caso la scelta è già fatta.
class NotificationInviteCard extends StatefulWidget {
  final BwPaletteData p;
  const NotificationInviteCard({super.key, required this.p});

  @override
  State<NotificationInviteCard> createState() => _NotificationInviteCardState();
}

class _NotificationInviteCardState extends State<NotificationInviteCard>
    with WidgetsBindingObserver {
  static const _dismissKey = 'notif_invite_dismissed_at';
  static const _pauseDays = 3;
  bool _show = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _check();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Tornando dalle impostazioni di sistema ricontrolla subito.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _check();
  }

  Future<void> _check() async {
    final enabled = await NotificationService.instance.areEnabled();
    final prefs = await SharedPreferences.getInstance();
    final off = (prefs.getString('notif_frequency') ?? 'normal') == 'off';
    final dismissedMs = prefs.getInt(_dismissKey);
    final snoozed = dismissedMs != null &&
        DateTime.now()
                .difference(DateTime.fromMillisecondsSinceEpoch(dismissedMs))
                .inDays <
            _pauseDays;
    final show = !enabled && !off && !snoozed;
    if (mounted && show != _show) setState(() => _show = show);
  }

  Future<void> _turnOn() async {
    final ok = await NotificationService.instance.enableOrOpenSettings();
    if (ok) await _check();
  }

  Future<void> _later() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_dismissKey, DateTime.now().millisecondsSinceEpoch);
    if (mounted) setState(() => _show = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!_show) return const SizedBox.shrink();
    final p = widget.p;
    final s = context.sL;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Semantics(
        container: true,
        label: '${s.notifInviteTitle}. ${s.notifInviteBody}',
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: p.primaryLight,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.primary.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  ExcludeSemantics(
                    child: Icon(Icons.notifications_off_outlined,
                        color: p.primary, size: 20),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      s.notifInviteTitle,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: p.text),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                s.notifInviteBody,
                style:
                    TextStyle(fontSize: 12.5, height: 1.45, color: p.textSec),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _later,
                    child: Text(s.notifInviteLater,
                        style: TextStyle(color: p.textSec)),
                  ),
                  const SizedBox(width: 6),
                  FilledButton(
                    onPressed: _turnOn,
                    style: FilledButton.styleFrom(backgroundColor: p.primary),
                    child: Text(s.notifInviteAction),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
