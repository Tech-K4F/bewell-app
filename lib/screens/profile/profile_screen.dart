import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart' as bw;
import '../../providers/theme_provider.dart';
import '../../widgets/bw_scaffold.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer2<AppProvider, ThemeProvider>(
      builder: (context, app, theme, _) {
        final p = theme.paletteData;
        final isAmb = theme.isAmbient;
        final user = app.user;
        if (user == null) return BwScaffold(body: const SizedBox());

        return BwScaffold(
          appBar: AppBar(
            backgroundColor: p.bg,
            elevation: 0,
            title: Text('Profilo',
                style: TextStyle(
                    color: p.text,
                    fontSize: 17,
                    fontWeight: FontWeight.w600)),
            actions: [
              IconButton(
                icon: Icon(Icons.settings_outlined, color: p.text),
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
                          fontWeight:
                              isAmb ? FontWeight.w300 : FontWeight.w700,
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
                      child: Text(user.levelName,
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
                _StatBox(label: 'Punti', value: '${user.points}', p: p),
                const SizedBox(width: 10),
                _StatBox(
                    label: 'Streak', value: '${user.streak} gg', p: p),
                const SizedBox(width: 10),
                _StatBox(
                    label: 'Sessioni',
                    value: '${user.totalSessions}',
                    p: p),
              ]),

              const SizedBox(height: 28),

              // ── Account ───────────────────────────────────────────────
              _SectionLabel(label: 'Account', p: p),
              const SizedBox(height: 10),
              _Card(p: p, children: [
                _Tile(
                  icon: Icons.person_outline,
                  label: 'Modifica nome',
                  p: p,
                  onTap: () => _showEditName(context, app, p),
                ),
                _Tile(
                  icon: Icons.lock_outline,
                  label: 'Cambia password',
                  p: p,
                  onTap: () => _showChangePassword(context, p),
                ),
                _Tile(
                  icon: Icons.email_outlined,
                  label: user.email.isNotEmpty ? user.email : 'Email account',
                  subtitle: 'Email account',
                  p: p,
                  onTap: null,
                ),
              ]),

              const SizedBox(height: 20),

              // ── Preferenze ────────────────────────────────────────────
              _SectionLabel(label: 'Preferenze', p: p),
              const SizedBox(height: 10),
              _Card(p: p, children: [
                _Tile(
                  icon: Icons.palette_outlined,
                  label: 'Aspetto e tema',
                  p: p,
                  onTap: () => Navigator.push(context,
                      MaterialPageRoute(
                          builder: (_) => const SettingsScreen())),
                ),
                _Tile(
                  icon: Icons.notifications_outlined,
                  label: 'Notifiche',
                  p: p,
                  onTap: () {},
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
                  label: const Text('Esci dall\'account',
                      style: TextStyle(color: Colors.redAccent)),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(
                        color: Colors.redAccent.withValues(alpha: 0.4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showEditName(
      BuildContext context, AppProvider app, BwPaletteData p) {
    final ctrl = TextEditingController(text: app.user?.name ?? '');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: p.card,
        title: Text('Modifica nome',
            style: TextStyle(color: p.text, fontSize: 16)),
        content: TextField(
          controller: ctrl,
          style: TextStyle(color: p.text),
          decoration: InputDecoration(
            hintText: 'Il tuo nome',
            hintStyle: TextStyle(color: p.textMut),
            enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: p.cardBorder)),
            focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: p.primary)),
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Annulla',
                  style: TextStyle(color: p.textSec))),
          TextButton(
            onPressed: () async {
              final name = ctrl.text.trim();
              if (name.isNotEmpty) await app.updateDisplayName(name);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Salva',
                style: TextStyle(color: p.primary)),
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Accedi con Google — password gestita da Google')));
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
        title: Text('Esci dall\'account',
            style: TextStyle(color: p.text)),
        content: Text('Sei sicuro?',
            style: TextStyle(color: p.textSec)),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child:
                  Text('Annulla', style: TextStyle(color: p.textSec))),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AppProvider>().resetOnLogout();
              await context.read<bw.AuthProvider>().logout();
            },
            child: const Text('Esci',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String label, value;
  final BwPaletteData p;
  const _StatBox(
      {required this.label, required this.value, required this.p});

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
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: p.text)),
            const SizedBox(height: 3),
            Text(label,
                style: TextStyle(fontSize: 10, color: p.textSec)),
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
    return Text(label.toUpperCase(),
        style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.2,
            color: p.textSec));
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
              Divider(height: 0.5, thickness: 0.5, color: p.cardBorder,
                  indent: 52),
          ]);
        }).toList(),
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final BwPaletteData p;
  final VoidCallback? onTap;
  const _Tile(
      {required this.icon,
      required this.label,
      this.subtitle,
      required this.p,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
            color: p.primaryLight,
            borderRadius: BorderRadius.circular(8)),
        child: Icon(icon, color: p.primary, size: 17),
      ),
      title: Text(label,
          style: TextStyle(
              color: p.text, fontSize: 14, fontWeight: FontWeight.w500)),
      subtitle: subtitle != null
          ? Text(subtitle!,
              style: TextStyle(color: p.textSec, fontSize: 11))
          : null,
      trailing: onTap != null
          ? Icon(Icons.chevron_right, color: p.textMut, size: 18)
          : null,
      onTap: onTap,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final BwPaletteData p;
  const _ChangePasswordDialog({required this.p});

  @override
  State<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
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
    if (_new.text != _conf.text) {
      setState(() => _error = 'Le password non coincidono');
      return;
    }
    if (_new.text.length < 8) {
      setState(() => _error = 'Minimo 8 caratteri');
      return;
    }
    setState(() { _loading = true; _error = null; });
    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
          email: user.email!, password: _cur.text);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(_new.text);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Password aggiornata')));
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.code == 'wrong-password'
            ? 'Password attuale errata'
            : 'Errore: ${e.message}';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    return AlertDialog(
      backgroundColor: p.card,
      title: Text('Cambia password',
          style: TextStyle(color: p.text, fontSize: 16)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PwdField(ctrl: _cur, label: 'Password attuale', p: p),
          const SizedBox(height: 10),
          _PwdField(ctrl: _new, label: 'Nuova password', p: p),
          const SizedBox(height: 10),
          _PwdField(ctrl: _conf, label: 'Conferma', p: p),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!,
                style: const TextStyle(
                    color: Colors.redAccent, fontSize: 12)),
          ],
        ],
      ),
      actions: [
        TextButton(
            onPressed: _loading ? null : () => Navigator.pop(context),
            child: Text('Annulla',
                style: TextStyle(color: p.textSec))),
        TextButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : Text('Salva', style: TextStyle(color: p.primary)),
        ),
      ],
    );
  }
}

class _PwdField extends StatefulWidget {
  final TextEditingController ctrl;
  final String label;
  final BwPaletteData p;
  const _PwdField(
      {required this.ctrl, required this.label, required this.p});

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
          icon: Icon(_obs ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
              color: widget.p.textMut, size: 18),
          onPressed: () => setState(() => _obs = !_obs),
        ),
      ),
    );
  }
}
