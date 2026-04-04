import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../settings/settings_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BwColors.darkPanel,
      appBar: AppBar(
        title: const Text('Profilo'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: Consumer<AppProvider>(builder: (context, p, _) {
        final user = p.user;
        if (user == null) return const SizedBox();

        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // ── Avatar + Name ───────────────────────────────────────────
            Center(
              child: Column(
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [BwColors.teal, BwColors.blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: BwColors.teal.withValues(alpha: 0.35),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        user.initials,
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    user.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  if (user.email.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.45),
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: BwColors.amberLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${user.levelEmoji} ${user.levelName}',
                      style: const TextStyle(
                        color: BwColors.amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // ── Stats ───────────────────────────────────────────────────
            _SectionTitle(label: 'Le tue statistiche'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _StatCard(
                        label: 'Punti', value: '${user.points}', icon: '⭐')),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Streak', value: '${user.streak}d', icon: '🔥')),
                const SizedBox(width: 12),
                Expanded(
                    child: _StatCard(
                        label: 'Sessioni',
                        value: '${user.totalSessions}',
                        icon: '✅')),
              ],
            ),

            const SizedBox(height: 28),

            // ── Account ─────────────────────────────────────────────────
            _SectionTitle(label: 'Account'),
            const SizedBox(height: 12),
            _AccountTile(
              icon: Icons.person_outline,
              label: 'Nome',
              value: user.name,
              onTap: () => _showEditName(context, user.name),
            ),
            _AccountTile(
              icon: Icons.email_outlined,
              label: 'Email',
              value: user.email,
            ),
            _AccountTile(
              icon: Icons.lock_outline,
              label: 'Cambia password',
              value: '',
              onTap: () => _showChangePassword(context, user.email),
            ),

            const SizedBox(height: 28),

            // ── Logout ──────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout, color: Colors.redAccent),
                label: const Text(
                  'Esci dall\'account',
                  style: TextStyle(color: Colors.redAccent),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                      color: Colors.redAccent.withValues(alpha: 0.4)),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        );
      }),
    );
  }

  // ── Dialogo cambio password ────────────────────────────────────────────
  void _showChangePassword(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (ctx) => _ChangePasswordDialog(email: email),
    );
  }

  // ── Dialogo modifica nome ──────────────────────────────────────────────
  void _showEditName(BuildContext context, String currentName) {
    final ctrl = TextEditingController(text: currentName);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1F33),
        title: const Text('Modifica nome',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: ctrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Il tuo nome',
            hintStyle: TextStyle(color: Colors.white38),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              final newName = ctrl.text.trim();
              if (newName.isNotEmpty) {
                await ctx.read<AppProvider>().updateDisplayName(newName);
                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nome aggiornato')),
                  );
                }
              }
            },
            child: const Text('Salva',
                style: TextStyle(color: BwColors.teal)),
          ),
        ],
      ),
    );
  }

  // ── Conferma logout ────────────────────────────────────────────────────
  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0F1F33),
        title: const Text('Esci dall\'account',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Sei sicuro di voler uscire?',
          style: TextStyle(color: Colors.white60),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annulla',
                style: TextStyle(color: Colors.white54)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil('/login', (_) => false);
              }
            },
            child: const Text('Esci',
                style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

// ── Dialogo cambio password ────────────────────────────────────────────────
class _ChangePasswordDialog extends StatefulWidget {
  final String email;
  const _ChangePasswordDialog({required this.email});

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  bool _sent = false;
  bool _loading = false;

  Future<void> _send() async {
    setState(() => _loading = true);
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: widget.email);
      setState(() {
        _sent = true;
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF0F1F33),
      title: const Text('Cambia password',
          style: TextStyle(color: Colors.white)),
      content: Text(
        _sent
            ? '✅ Email inviata a ${widget.email}\n\nControlla la tua casella e segui le istruzioni.'
            : 'Ti invieremo un link per reimpostare la password all\'indirizzo:\n\n${widget.email}',
        style: const TextStyle(color: Colors.white70, height: 1.5),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            _sent ? 'Chiudi' : 'Annulla',
            style: const TextStyle(color: Colors.white54),
          ),
        ),
        if (!_sent)
          TextButton(
            onPressed: _loading ? null : _send,
            child: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: BwColors.teal))
                : const Text('Invia email',
                    style: TextStyle(color: BwColors.teal)),
          ),
      ],
    );
  }
}

// ── Widgets locali ─────────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final String label;
  const _SectionTitle({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: Colors.white.withValues(alpha: 0.4),
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String icon;
  const _StatCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BwColors.panelBorder),
      ),
      child: Column(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18)),
          const SizedBox(height: 2),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.4), fontSize: 11)),
        ],
      ),
    );
  }
}

class _AccountTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;
  const _AccountTile(
      {required this.icon,
      required this.label,
      required this.value,
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BwColors.panelBorder),
        ),
        child: Row(
          children: [
            Icon(icon,
                color: Colors.white.withValues(alpha: 0.4), size: 20),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.4),
                          fontSize: 11)),
                  if (value.isNotEmpty)
                    Text(value,
                        style: const TextStyle(
                            color: Colors.white, fontSize: 15)),
                ],
              ),
            ),
            if (onTap != null)
              Icon(Icons.chevron_right,
                  color: Colors.white.withValues(alpha: 0.25), size: 20),
          ],
        ),
      ),
    );
  }
}





