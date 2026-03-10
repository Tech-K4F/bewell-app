import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/badge_model.dart' as bw;
import '../../theme/app_theme.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});
  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BwColors.darkPanel,
      appBar: AppBar(
        title: const Text('Premi & Sfide'),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: BwColors.amber,
          labelColor: BwColors.amber,
          unselectedLabelColor: BwColors.textSecondary,
          tabs: const [
            Tab(text: 'Badge'),
            Tab(text: 'Sfide'),
            Tab(text: 'Classifica'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _BadgesTab(),
          _ChallengesTab(),
          _LeaderboardTab(),
        ],
      ),
    );
  }
}

class _BadgesTab extends StatelessWidget {
  const _BadgesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, p, _) {
      final earned = p.user?.earnedBadgeIds ?? [];

      final groups = <String, List<bw.BwBadge>>{};
      for (final b in bw.allBadges) {
        groups.putIfAbsent(b.category, () => []).add(b);
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Header summary
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BwColors.amber.withOpacity(.15),
                  BwColors.amber.withOpacity(.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: BwColors.amber.withOpacity(.25)),
            ),
            child: Row(
              children: [
                const Text('🏅', style: TextStyle(fontSize: 40)),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${earned.length} / ${bw.allBadges.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700),
                    ),
                    Text('badge sbloccati',
                        style: TextStyle(
                            color: Colors.white.withOpacity(.5),
                            fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          ...groups.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key.toUpperCase(),
                  style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(.3),
                      letterSpacing: .5),
                ),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: .85,
                  children: entry.value.map((badge) {
                    final isEarned = earned.contains(badge.id);
                    return GestureDetector(
                      onTap: () => _showBadgeDetail(context, badge, isEarned),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isEarned
                              ? BwColors.amberLight
                              : Colors.white.withOpacity(.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isEarned
                                ? BwColors.amber.withOpacity(.4)
                                : Colors.white.withOpacity(.08),
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              badge.emoji,
                              style: TextStyle(
                                fontSize: 32,
                                color: isEarned
                                    ? null
                                    : Colors.white.withOpacity(.15),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                badge.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isEarned
                                      ? BwColors.amber
                                      : Colors.white.withOpacity(.25),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            );
          }),
        ],
      );
    });
  }

  void _showBadgeDetail(
      BuildContext context, bw.BwBadge badge, bool isEarned) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BwColors.panel,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji,
                style: TextStyle(
                    fontSize: 56,
                    color: isEarned ? null : Colors.white.withOpacity(.2))),
            const SizedBox(height: 12),
            Text(badge.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isEarned
                        ? BwColors.amber
                        : Colors.white.withOpacity(.5),
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            const SizedBox(height: 8),
            Text(badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(.5), fontSize: 13)),
            if (!isEarned) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.05),
                    borderRadius: BorderRadius.circular(8)),
                child: Text('🔒 Non ancora sbloccato',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(.4))),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi',
                style: TextStyle(color: BwColors.teal)),
          ),
        ],
      ),
    );
  }
}

class _ChallengesTab extends StatelessWidget {
  const _ChallengesTab();

  static const _challenges = [
    ('🔥', '7 giorni di streak',
        'Completa almeno un\'attività per 7 giorni consecutivi',
        7, BwColors.coral, 100),
    ('💧', 'Settimana idratata',
        'Bevi acqua ogni giorno per 7 giorni', 7, BwColors.teal, 70),
    ('🧘', 'Respira ogni giorno',
        '5 sessioni di respirazione questa settimana', 5, BwColors.blue, 75),
    ('⏱', 'Focus Master',
        '10 sessioni focus questa settimana', 10, BwColors.purple, 150),
    ('🌿', 'Piano perfetto',
        'Completa il piano giornaliero 3 volte', 3, BwColors.green, 90),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: _challenges.length,
      itemBuilder: (_, i) {
        final c = _challenges[i];
        final progress = (i * 0.3 + 0.1).clamp(0.0, 1.0);
        final current = (progress * c.$4).round();

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: BwColors.panel,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BwColors.panelBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.$5.withOpacity(.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(c.$1,
                        style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.$2,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        Text(c.$3,
                            style: TextStyle(
                                color: Colors.white.withOpacity(.4),
                                fontSize: 11),
                            maxLines: 2),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: BwColors.amberLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('+${c.$6} pt',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: BwColors.amber)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.white.withOpacity(.07),
                        valueColor: AlwaysStoppedAnimation(c.$5),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text('$current/${c.$4}',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: c.$5)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab();

  static const _entries = [
    ('Sara M.', 2840, '🌲', 12),
    ('Marco R.', 2310, '🌳', 7),
    ('Tu', 0, '🌿', 0),
    ('Elena B.', 1180, '🌿', 4),
    ('Luca P.', 980, '🌿', 3),
    ('Anna F.', 760, '🌱', 2),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, p, _) {
      final userPoints = p.user?.points ?? 0;
      final userName = p.user?.name ?? 'Tu';

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  BwColors.amber.withOpacity(.1),
                  BwColors.purple.withOpacity(.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: BwColors.amber.withOpacity(.2)),
            ),
            child: Column(
              children: [
                const Text('🏆 Classifica',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                const SizedBox(height: 8),
                Text('Questa settimana',
                    style: TextStyle(
                        color: Colors.white.withOpacity(.4), fontSize: 12)),
              ],
            ),
          ),
          const SizedBox(height: 12),

          ..._entries.asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final isMe = e.$1 == 'Tu';
            final name = isMe ? userName : e.$1;
            final points = isMe ? userPoints : e.$2;
            final emoji = isMe ? (p.user?.levelEmoji ?? '🌿') : e.$3;
            final rankEmoji =
                i == 0 ? '🥇' : i == 1 ? '🥈' : i == 2 ? '🥉' : '${i + 1}.';

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isMe ? BwColors.tealLight : BwColors.panel,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isMe
                      ? BwColors.teal.withOpacity(.4)
                      : BwColors.panelBorder,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(rankEmoji,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18)),
                  ),
                  const SizedBox(width: 10),
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(name,
                        style: TextStyle(
                            color: isMe ? BwColors.teal : Colors.white,
                            fontWeight: isMe
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14)),
                  ),
                  Text('$points pt',
                      style: TextStyle(
                          color: isMe
                              ? BwColors.teal
                              : Colors.white.withOpacity(.5),
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: BwColors.panelBorder),
            ),
            child: Text(
              '💡 La classifica si aggiorna ogni settimana. Completa le attività per scalare la classifica!',
              style: TextStyle(
                  color: Colors.white.withOpacity(.4), fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    });
  }
}
