import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart' as bw;
import '../../models/auth_result.dart';
import '../../providers/progression_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../widgets/bw_scaffold.dart';
import '../settings/settings_screen.dart';
import '../settings/accessibility_screen.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../widgets/feedback_sheet.dart';
import '../../l10n/app_localizations.dart';
import '../../services/cloud_sync_service.dart';
import '../../services/notification_service.dart';
import '../../widgets/restart_widget.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, ThemeProvider>(
      builder: (context, app, theme, _) {
        final p = theme.paletteData;
        final isAmb = theme.isAmbient;
        final user = app.user;
        // Rete di sicurezza: se per qualunque motivo AppProvider.user non è
        // ancora pronto, meglio uno spinner che uno schermo bianco muto —
        // la causa nota (utente nuovo senza sync da Firebase) è già risolta
        // a monte in login/register, ma questa schermata non deve più
        // sparire silenziosamente se succede di nuovo per un altro motivo.
        if (user == null) {
          return BwScaffold(
            body: Center(child: CircularProgressIndicator(color: p.primary)),
          );
        }

        return BwScaffold(
          bottomNavigationBar: const BannerAdWidget(screenKey: 'profile'),
          appBar: AppBar(
            backgroundColor: p.bg,
            elevation: 0,
            title: Text(context.sL.profileTitle,
                style: TextStyle(
                    color: p.text, fontSize: 17, fontWeight: FontWeight.w600)),
            actions: [
              IconButton(
                icon: Icon(Icons.settings_outlined, color: p.text),
                tooltip: context.sL.settings,
                onPressed: () => Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen())),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              SizedBox(height: isAmb ? 60 : 0),

              // ── Avatar ─────────────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: p.primaryLight,
                        shape: BoxShape.circle,
                        border: Border.all(color: p.primary, width: 1.5),
                      ),
                      child: Center(
                        child: Text(user.initials,
                            style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w600,
                                color: p.primaryText)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(user.name,
                        style: TextStyle(
                          fontSize: isAmb ? 26 : 20,
                          fontWeight: isAmb ? FontWeight.w300 : FontWeight.w700,
                          fontFamily: isAmb ? 'CormorantGaramond' : null,
                          color: p.text,
                        )),
                    const SizedBox(height: 4),
                    Text(
                      user.email.isNotEmpty
                          ? user.email
                          : FirebaseAuth.instance.currentUser?.email ?? '',
                      style: TextStyle(fontSize: 13, color: p.textSec),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_profilePhaseLabel(context),
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: p.primaryText)),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Stats ──────────────────────────────────────────────────
              Row(children: [
                _StatBox(
                    label: context.sL.points, value: '${user.points}', p: p),
                const SizedBox(width: 10),
                _StatBox(
                    label: context.sL.daysStreak,
                    value: '${app.liveStreak}',
                    p: p),
                const SizedBox(width: 10),
                _StatBox(
                    label: context.sL.focusSessions,
                    value: '${user.totalSessions}',
                    p: p),
              ]),

              const SizedBox(height: 28),

              // ── Account ───────────────────────────────────────────────
              _SectionLabel(label: context.sL.accountSection, p: p),
              const SizedBox(height: 10),
              _Card(p: p, children: [
                _Tile(
                  icon: Icons.person_outline,
                  label: context.sL.editName,
                  p: p,
                  onTap: () => _showEditName(context, app, p),
                ),
                _Tile(
                  icon: Icons.lock_outline,
                  label: context.sL.changePassword,
                  p: p,
                  onTap: () => _showChangePassword(context, p),
                ),
                _Tile(
                  icon: Icons.restart_alt_rounded,
                  label: context.sL.resetAllTitle,
                  p: p,
                  onTap: () => _confirmResetAll(context, p),
                ),
              ]),

              const SizedBox(height: 20),

              // ── Preferenze ────────────────────────────────────────────
              _SectionLabel(label: context.sL.settings, p: p),
              const SizedBox(height: 10),
              _Card(p: p, children: [
                _Tile(
                  icon: Icons.palette_outlined,
                  label: context.sL.appearance,
                  p: p,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen())),
                ),
                _Tile(
                  icon: Icons.accessibility_new_rounded,
                  label: context.sL.accessibility,
                  p: p,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AccessibilityScreen())),
                ),
                _Tile(
                  icon: Icons.notifications_outlined,
                  label: context.sL.notifications,
                  p: p,
                  onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen())),
                ),
                _LocaleTile(p: p),
              ]),

              const SizedBox(height: 20),

              // ── Supporto ──────────────────────────────────────────────
              _SectionLabel(label: context.sL.supportSection, p: p),
              const SizedBox(height: 10),
              _Card(p: p, children: [
                _Tile(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: context.sL.feedbackTitle,
                  p: p,
                  onTap: () => FeedbackSheet.show(context),
                ),
              ]),

              const SizedBox(height: 28),

              // ── Logout ────────────────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _confirmLogout(context, p),
                  icon: const Icon(Icons.logout,
                      color: Colors.redAccent, size: 18),
                  label: Text(context.sL.logout,
                      style: const TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ── Elimina account ───────────────────────────────────────
              // Richiesta obbligatoria da Google Play e App Store per ogni
              // app con creazione account — prima esisteva solo il logout.
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => _confirmDeleteAccount(context, p),
                  child: Text(context.sL.deleteAccount,
                      style: TextStyle(
                          color: p.textMut,
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                          decorationColor: p.textMut)),
                ),
              ),

              // ── Debug (solo in modalità debug) ────────────────────────
              if (kDebugMode) ...[
                const SizedBox(height: 32),
                _SectionLabel(label: '🛠 Debug', p: p),
                const SizedBox(height: 10),
                _Card(p: p, children: [
                  _Tile(
                    icon: Icons.smart_toy_outlined,
                    label: context.sL.resetTutorialTitle,
                    p: p,
                    onTap: () => _resetTutorial(context, p),
                  ),
                ]),
              ],
            ],
          ),
        );
      },
    );
  }

  void _showEditName(BuildContext context, AppProvider app, BwPaletteData p) {
    final ctrl = TextEditingController(text: app.user?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.card,
        title: Text(context.sL.editNameTitle,
            style: TextStyle(color: p.text, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: p.text),
          decoration: InputDecoration(
            hintText: context.sL.yourNameHint,
            hintStyle: TextStyle(color: p.textMut),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: p.cardBorder)),
            focusedBorder:
                UnderlineInputBorder(borderSide: BorderSide(color: p.primary)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child:
                  Text(context.sL.cancel, style: TextStyle(color: p.textSec))),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) await app.updateDisplayName(name);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(context.sL.save, style: TextStyle(color: p.primary)),
          ),
        ],
      ),
    );
  }

  void _showChangePassword(BuildContext context, BwPaletteData p) {
    final user = FirebaseAuth.instance.currentUser;
    final isPassword =
        user?.providerData.any((d) => d.providerId == 'password') ?? false;
    if (!isPassword) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(context.sL.loginWithGoogle)));
      return;
    }
    showDialog(
      context: context,
      builder: (_) => _ChangePasswordDialog(p: p),
    );
  }

  void _confirmLogout(BuildContext context, BwPaletteData p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.card,
        title: Text(context.sL.logoutConfirm, style: TextStyle(color: p.text)),
        content: Text(context.sL.logoutConfirmSub,
            style: TextStyle(color: p.textSec)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text(context.sL.cancel, style: TextStyle(color: p.textSec))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final app = context.read<AppProvider>();
              final auth = context.read<bw.AuthProvider>();
              // Prima l'ultima copia nel cloud (serve ancora la sessione),
              // poi dispositivo pulito: un altro account non eredita nulla.
              await CloudSyncService.instance.onLogout();
              await app.resetOnLogout();
              await auth.logout();
              await NotificationService.instance.cancelAll();
              if (context.mounted) RestartWidget.restart(context);
            },
            child: Text(context.sL.logout,
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  /// Reset totale: cancella progressi e impostazioni sul telefono E nel
  /// cloud, poi riparte dall'accoglienza come un primo utilizzo.
  void _confirmResetAll(BuildContext context, BwPaletteData p) {
    final s = context.sL;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.card,
        title: Text(s.resetAllConfirmTitle, style: TextStyle(color: p.text)),
        content:
            Text(s.resetAllConfirmBody, style: TextStyle(color: p.textSec)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.cancel, style: TextStyle(color: p.textSec))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await NotificationService.instance.cancelAll();
              await CloudSyncService.instance.resetEverything();
              if (context.mounted) RestartWidget.restart(context);
            },
            child: Text(s.resetAllConfirmButton,
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, BwPaletteData p) {
    final s = context.sL;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.card,
        title:
            Text(s.deleteAccountConfirmTitle, style: TextStyle(color: p.text)),
        content: Text(s.deleteAccountConfirmBody,
            style: TextStyle(color: p.textSec)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(s.cancel, style: TextStyle(color: p.textSec))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final auth = context.read<bw.AuthProvider>();
              final messenger = ScaffoldMessenger.of(context);
              final navigator = Navigator.of(context);
              final ok = await auth.deleteAccount();
              if (!context.mounted) return;
              if (ok) {
                await CloudSyncService.instance.wipeLocal();
                await NotificationService.instance.cancelAll();
                if (context.mounted) RestartWidget.restart(context);
                messenger
                    .showSnackBar(SnackBar(content: Text(s.deleteAccountDone)));
              } else {
                messenger.showSnackBar(SnackBar(
                    content: Text(auth.lastError?.localizedMessage(s) ??
                        s.errorGeneral)));
              }
            },
            child: Text(s.deleteAccountCta,
                style: const TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  // ── Debug: reset tutorial ─────────────────────────────────────────────────

  void _resetTutorial(BuildContext context, BwPaletteData p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.card,
        title: Text(context.sL.resetTutorialTitle,
            style: TextStyle(color: p.text)),
        content: Text(
          context.sL.resetTutorialBody,
          style: TextStyle(color: p.textSec, fontSize: 13, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.sL.cancel, style: TextStyle(color: p.textSec)),
          ),
          TextButton(
            onPressed: () async {
              final tutorial = context.read<TutorialProvider>();
              final s = context.sL;
              await tutorial.resetAll();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(s.resetTutorialSnackbar),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    margin: const EdgeInsets.all(16),
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
            },
            child: Text(context.sL.resetTutorialCta,
                style:
                    TextStyle(color: p.primary, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final BwPaletteData p;
  const _StatBox({required this.label, required this.value, required this.p});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: p.cardBorder, width: 0.5),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700, color: p.text)),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(fontSize: 10, color: p.textSec)),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final BwPaletteData p;
  const _SectionLabel({required this.label, required this.p});

  @override
  Widget build(BuildContext context) {
    return Semantics(
        header: true,
        child: Text(label.toUpperCase(),
            style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
                color: p.textSec)));
  }
}

class _Card extends StatelessWidget {
  final List<Widget> children;
  final BwPaletteData p;
  const _Card({required this.children, required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: p.cardBorder, width: 0.5),
      ),
      child: Column(
        children: children.asMap().entries.map((e) {
          return Column(children: [
            e.value,
            if (e.key < children.length - 1)
              Divider(
                  height: 0.5, thickness: 0.5, color: p.cardBorder, indent: 52),
          ]);
        }).toList(),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final BwPaletteData p;
  final VoidCallback? onTap;
  const _Tile(
      {required this.icon, required this.label, required this.p, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: p.primaryLight, borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: p.primary, size: 17),
      ),
      title: Text(label,
          style: TextStyle(
              color: p.text, fontSize: 14, fontWeight: FontWeight.w500)),
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: p.textMut, size: 18)
          : null,
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final BwPaletteData p;
  const _ChangePasswordDialog({required this.p});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _cur = TextEditingController();
  final _new = TextEditingController();
  final _conf = TextEditingController();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _cur.dispose();
    _new.dispose();
    _conf.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final s = context.sL;
    if (_new.text != _conf.text) {
      setState(() => _error = s.passwordMismatch);
      return;
    }
    if (_new.text.length < 8) {
      setState(() => _error = s.validationPasswordTooShort);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred =
          EmailAuthProvider.credential(email: user.email!, password: _cur.text);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_new.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(context.sL.passwordUpdated)));
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.code == 'wrong-password'
            ? s.wrongPassword
            : s.genericError(e.message ?? '');
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return AlertDialog(
      backgroundColor: p.card,
      title: Text(context.sL.changePassword,
          style: TextStyle(color: p.text, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PwdField(ctrl: _cur, label: context.sL.currentPassword, p: p),
          const SizedBox(height: 10),
          _PwdField(ctrl: _new, label: context.sL.newPassword, p: p),
          const SizedBox(height: 10),
          _PwdField(ctrl: _conf, label: context.sL.confirm, p: p),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: Text(context.sL.cancel, style: TextStyle(color: p.textSec))),
        TextButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text(context.sL.save, style: TextStyle(color: p.primary)),
        ),
      ],
    );
  }
}

class _PwdField extends StatefulWidget {
  final TextEditingController ctrl;
  final String label;
  final BwPaletteData p;
  const _PwdField({required this.ctrl, required this.label, required this.p});

  @override
  State<_PwdField> createState() => _PwdFieldState();
}

class _PwdFieldState extends State<_PwdField> {
  bool _obs = true;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.ctrl,
      obscureText: _obs,
      style: TextStyle(color: widget.p.text, fontSize: 14),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: TextStyle(color: widget.p.textSec, fontSize: 13),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: widget.p.cardBorder)),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: widget.p.primary)),
        suffixIcon: IconButton(
          icon: Icon(
              _obs ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: widget.p.textMut,
              size: 18),
          onPressed: () => setState(() => _obs = !_obs),
          tooltip: _obs ? context.sL.passwordShow : context.sL.passwordHide,
        ),
      ),
    );
  }
}

// ── Voce lingua ───────────────────────────────────────────────────────────────
class _LocaleTile extends StatelessWidget {
  final BwPaletteData p;
  const _LocaleTile({required this.p});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        final sorted = [...BwLocale.values]
          ..sort((a, b) => a.label.compareTo(b.label));
        return ListTile(
          onTap: () => _showPicker(context, localeProvider, sorted, p),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          leading: Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
                color: p.primaryLight, borderRadius: BorderRadius.circular(8)),
            child: Icon(Icons.language_outlined, color: p.primary, size: 17),
          ),
          title: Text('Lingua / Language',
              style: TextStyle(
                  color: p.text, fontSize: 14, fontWeight: FontWeight.w500)),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(localeProvider.locale.flag,
                  style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 4),
              if (MediaQuery.textScalerOf(context).scale(1) <= 1.3) ...[
                Text(localeProvider.locale.label,
                    style: TextStyle(fontSize: 13, color: p.textSec)),
                const SizedBox(width: 4),
              ],
              Icon(Icons.expand_more, color: p.textMut, size: 16),
            ],
          ),
        );
      },
    );
  }

  void _showPicker(BuildContext context, LocaleProvider localeProvider,
      List<BwLocale> sorted, BwPaletteData p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: p.card,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
          child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
                color: p.cardBorder, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 16),
          ...sorted.map((locale) {
            final isSelected = localeProvider.locale == locale;
            return ListTile(
              leading: Text(locale.flag, style: const TextStyle(fontSize: 22)),
              title: Text(locale.label,
                  style: TextStyle(
                    fontSize: 15,
                    color: isSelected ? p.primary : p.text,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  )),
              trailing: isSelected
                  ? Icon(Icons.check_circle_rounded, color: p.primary, size: 18)
                  : null,
              onTap: () {
                localeProvider.setLocale(locale);
                Navigator.pop(context);
              },
            );
          }),
          const SizedBox(height: 16),
        ],
      )),
    );
  }
}

/// "Fase 1 · Seme": lo stesso livello mostrato in Home, nella lingua scelta.
String _profilePhaseLabel(BuildContext context) {
  final s = context.sL;
  final phase = context.watch<ProgressionProvider>().currentPhase;
  final name = switch (phase) {
    1 => s.phase1,
    2 => s.phase2,
    3 => s.phase3,
    4 => s.phase4,
    _ => s.phase5,
  };
  return '${s.phase} $phase · $name';
}
