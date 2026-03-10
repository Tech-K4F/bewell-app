import 'package:flutter/material.dart';
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
            // Avatar + Name
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
                          color: BwColors.teal.withOpacity(.35),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(user.initials,
                          style: const TextStyle(
                              fontSize: 34,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(user.name,
                      style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  if (user.email.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(user.email,
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(.4))),
                  ],
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: BwColors.amberLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: BwColors.amber.withOpacity(.3)),
                    ),
                    child: Text('${user.levelEmoji} ${user.levelName}',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: BwColors.amber)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Stats grid
            Row(children: [
              _statBox('${user.streak}', '🔥', 'Streak'),
              const SizedBox(width: 8),
              _statBox('${user.points}', '⭐', 'Punti'),
              const SizedBox(width: 8),
              _statBox('${user.earnedBadgeIds.length}', '🏅', 'Badge'),
              const SizedBox(width: 8),
              _statBox('${user.totalSessions}', '🎯', 'Sessioni'),
            ]),
            const SizedBox(height: 16),

            // Level progress
            _LevelProgress(user: user),
            const SizedBox(height: 24),

            // Weekly activity chart
            _WeeklyChart(provider: p),
            const SizedBox(height: 24),

            // Account info section
            _sectionLabel('Account'),
            const SizedBox(height: 8),
            _infoRow('👤', 'Nome', user.name),
            if (user.email.isNotEmpty)
              _infoRow('📧', 'Email', user.email),
            _infoRow('💼',
                'Tipo utente',
                user.userType == 'worker'
                    ? 'Lavoratore'
                    : user.userType == 'student'
                        ? 'Studente'
                        : 'Entrambi'),
            const SizedBox(height: 20),

            // Settings section
            _sectionLabel('Impostazioni'),
            const SizedBox(height: 8),
            _settingTile(
              context,
              '⚙️',
              'Impostazioni App',
              'Notifiche, accessibilità, tema',
              () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen())),
            ),
            _settingTile(context, '📊', 'Statistiche',
                'Progressi dettagliati e report', () {}),
            _settingTile(context, '📚', 'Libreria Attività',
                'Sfoglia tutte le attività', () {
              p.setNavIndex(1); // Go to planner
            }),
            const SizedBox(height: 20),

            // Privacy section
            _sectionLabel('Privacy & Dati'),
            const SizedBox(height: 8),
            _settingTile(context, '🔒', 'Privacy & GDPR',
                'Gestisci i tuoi dati', () => _showPrivacySheet(context)),
            _settingTile(context, '📤', 'Esporta dati',
                'Scarica un backup dei tuoi dati', () {}),
            _settingTile(context, '🗑', 'Elimina account',
                'Rimuovi tutti i dati permanentemente',
                () => _showDeleteDialog(context, p),
                danger: true),
            const SizedBox(height: 24),

            // Reset / Logout
            OutlinedButton.icon(
              onPressed: () => _showLogoutDialog(context, p),
              icon: const Icon(Icons.logout, color: BwColors.coral, size: 18),
              label: const Text('Esci dall\'account'),
              style: OutlinedButton.styleFrom(
                foregroundColor: BwColors.coral,
                side: const BorderSide(color: BwColors.coral),
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: Text('Be Well v1.0.0 · Made with 🌿',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(.2))),
            ),
          ],
        );
      }),
    );
  }

  Widget _statBox(String value, String emoji, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: BwColors.panel,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BwColors.panelBorder),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 4),
            Text(value,
                style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            Text(label,
                style: TextStyle(
                    fontSize: 9,
                    color: Colors.white.withOpacity(.35))),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String t) => Text(t.toUpperCase(),
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(.3),
          letterSpacing: .5));

  Widget _infoRow(String emoji, String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: BwColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BwColors.panelBorder),
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Text(label,
              style: TextStyle(
                  color: Colors.white.withOpacity(.5), fontSize: 13)),
          const Spacer(),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 13)),
        ],
      ),
    );
  }

  Widget _settingTile(BuildContext ctx, String emoji, String title, String sub,
      VoidCallback onTap,
      {bool danger = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: BwColors.panel,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: BwColors.panelBorder),
      ),
      child: ListTile(
        leading: Text(emoji, style: const TextStyle(fontSize: 20)),
        title: Text(title,
            style: TextStyle(
                color: danger ? BwColors.coral : Colors.white,
                fontWeight: FontWeight.w500,
                fontSize: 14)),
        subtitle: Text(sub,
            style: TextStyle(
                color: Colors.white.withOpacity(.3), fontSize: 11)),
        trailing: Icon(Icons.chevron_right,
            color: Colors.white.withOpacity(.2), size: 18),
        onTap: onTap,
      ),
    );
  }

  void _showPrivacySheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BwColors.panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('🔒 Privacy & GDPR',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const SizedBox(height: 16),
            _privacyItem('Dati memorizzati',
                'Solo sul tuo dispositivo. Nessun dato inviato a server esterni.'),
            _privacyItem('Notifiche',
                'Gestite localmente. Puoi disabilitarle in qualsiasi momento.'),
            _privacyItem('Analytics',
                'Be Well non raccoglie dati di utilizzo senza consenso.'),
            _privacyItem('GDPR',
                'In conformità con il Reg. UE 2016/679. Hai diritto all\'accesso, rettifica ed eliminazione.'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('Chiudi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _privacyItem(String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle, color: BwColors.teal, size: 16),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
                Text(desc,
                    style: TextStyle(
                        color: Colors.white.withOpacity(.5),
                        fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, AppProvider p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BwColors.panel,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Esci dall\'account',
            style: TextStyle(color: Colors.white)),
        content: Text('I tuoi progressi sono al sicuro.',
            style: TextStyle(color: Colors.white.withOpacity(.5))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Annulla',
                  style: TextStyle(color: Colors.white.withOpacity(.4)))),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                p.resetAll();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: BwColors.coral),
              child: const Text('Esci')),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, AppProvider p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BwColors.panel,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('⚠️ Elimina account',
            style:
                TextStyle(color: BwColors.coral, fontWeight: FontWeight.w700)),
        content: const Text(
          'Questa azione è irreversibile. Tutti i tuoi dati, progressi e badge verranno eliminati permanentemente.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annulla',
                  style: TextStyle(color: BwColors.teal))),
          ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                p.resetAll();
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: BwColors.coral),
              child: const Text('Elimina tutto')),
        ],
      ),
    );
  }
}

class _LevelProgress extends StatelessWidget {
  final dynamic user;
  const _LevelProgress({required this.user});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BwColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BwColors.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prossimo livello: ${user.levelName}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
              Text('${user.points} / ${user.nextLevelThreshold} pt',
                  style: const TextStyle(
                      color: BwColors.teal,
                      fontWeight: FontWeight.w600,
                      fontSize: 11)),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: user.levelProgress,
              backgroundColor: Colors.white.withOpacity(.07),
              valueColor:
                  const AlwaysStoppedAnimation(BwColors.teal),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyChart extends StatelessWidget {
  final AppProvider provider;
  const _WeeklyChart({required this.provider});

  @override
  Widget build(BuildContext context) {
    const days = ['L', 'M', 'M', 'G', 'V', 'S', 'D'];
    // Mock data — in production use weeklyCompletions from user
    final data = [3, 5, 2, 6, 4, 1, 3];
    final maxVal = data.reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BwColors.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: BwColors.panelBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Attività questa settimana',
              style: TextStyle(
                  color: Colors.white.withOpacity(.6),
                  fontSize: 12,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(7, (i) {
              final h = maxVal > 0 ? (data[i] / maxVal) : 0.0;
              final isToday = i == DateTime.now().weekday - 1;
              return Expanded(
                child: Column(
                  children: [
                    Text('${data[i]}',
                        style: TextStyle(
                            color: isToday
                                ? BwColors.teal
                                : Colors.white.withOpacity(.3),
                            fontSize: 9,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Container(
                      height: 60 * h + 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        color: isToday
                            ? BwColors.teal
                            : Colors.white.withOpacity(.12),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(days[i],
                        style: TextStyle(
                            color: isToday
                                ? BwColors.teal
                                : Colors.white.withOpacity(.3),
                            fontSize: 10,
                            fontWeight: isToday
                                ? FontWeight.w700
                                : FontWeight.normal)),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
