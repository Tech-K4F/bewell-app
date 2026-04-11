import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/bw_scaffold.dart';
import '../../providers/app_provider.dart';
import '../../models/badge_model.dart' as bw;

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
    return BwScaffold(
      appBar: AppBar(
        title: Text(context.sL.rewards),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFFF5F1EA),
          labelColor: const Color(0xFFF5F1EA),
          unselectedLabelColor: context.read<ThemeProvider>().paletteData.textSec,
          tabs: [
            Tab(text: context.sL.badges),
            Tab(text: context.sL.navRewards),
            Tab(text: 'Top'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
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
        padding: EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Header summary
          Container(
            padding: EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF5F1EA).withOpacity(.15),
                  const Color(0xFFF5F1EA).withOpacity(.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF5F1EA).withOpacity(.25)),
            ),
            child: Row(
              children: [
                Text('🏅', style: TextStyle(fontSize: 40)),
                SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${earned.length} / ${bw.allBadges.length}',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(context.sL.badges,
                        style: TextStyle(
                            color: Colors.white.withOpacity(.5),
                            fontSize: 13)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 20),

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
                SizedBox(height: 10),
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
                              ? const Color(0xFFF5F1EA)
                              : Colors.white.withOpacity(.04),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isEarned
                                ? const Color(0xFFF5F1EA).withOpacity(.4)
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
                            SizedBox(height: 6),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                badge.name,
                                textAlign: TextAlign.center,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: isEarned
                                      ? const Color(0xFFF5F1EA)
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
                SizedBox(height: 20),
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
        backgroundColor: const Color(0xFFF5F1EA),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(badge.emoji,
                style: TextStyle(
                    fontSize: 56,
                    color: isEarned ? null : Colors.white.withOpacity(.2))),
            SizedBox(height: 12),
            Text(badge.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: isEarned
                        ? const Color(0xFFF5F1EA)
                        : Colors.white.withOpacity(.5),
                    fontWeight: FontWeight.w700,
                    fontSize: 16)),
            SizedBox(height: 8),
            Text(badge.description,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(.5), fontSize: 13)),
            if (!isEarned) ...[
              SizedBox(height: 12),
              Container(
                padding:
                    EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            child: Text('Chiudi',
                style: TextStyle(color: const Color(0xFF4A7C59))),
          ),
        ],
      ),
    );
  }
}

class _ChallengesTab extends StatelessWidget {
  const _ChallengesTab();

  static final _challenges = [
    ('🔥', '7 giorni di streak',
        'Completa almeno un\'attività per 7 giorni consecutivi',
        7, const Color(0xFFF5F1EA), 100),
    ('💧', 'Settimana idratata',
        'Bevi acqua ogni giorno per 7 giorni', 7, const Color(0xFF4A7C59), 70),
    ('🧘', 'Respira ogni giorno',
        '5 sessioni di respirazione questa settimana', 5, const Color(0xFFF5F1EA), 75),
    ('⏱', 'Focus Master',
        '10 sessioni focus questa settimana', 10, const Color(0xFFF5F1EA), 150),
    ('🌿', 'Piano perfetto',
        'Completa il piano giornaliero 3 volte', 3, const Color(0xFFF5F1EA), 90),
  ];

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 40),
      itemCount: _challenges.length,
      itemBuilder: (_, i) {
        final c = _challenges[i];
        final progress = (i * 0.3 + 0.1).clamp(0.0, 1.0);
        final current = (progress * c.$4).round();

        return Container(
          margin: EdgeInsets.only(bottom: 12),
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F1EA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF5F1EA)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: c.$5.withOpacity(.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(c.$1,
                        style: TextStyle(fontSize: 22)),
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.$2,
                            style: TextStyle(
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
                    padding: EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F1EA),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('+${c.$6} pt',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFFF5F1EA))),
                  ),
                ],
              ),
              SizedBox(height: 12),
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
                  SizedBox(width: 10),
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
        padding: EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color(0xFFF5F1EA).withOpacity(.1),
                  const Color(0xFFF5F1EA).withOpacity(.05),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFFF5F1EA).withOpacity(.2)),
            ),
            child: Column(
              children: [
                Text('🏆 Classifica',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 16)),
                SizedBox(height: 8),
                Text(context.sL.planToday,
                    style: TextStyle(
                        color: Colors.white.withOpacity(.4), fontSize: 12)),
              ],
            ),
          ),
          SizedBox(height: 12),

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
              margin: EdgeInsets.only(bottom: 8),
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isMe ? const Color(0xFF4A7C59).withValues(alpha: 0.15) : const Color(0xFFF5F1EA),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isMe
                      ? const Color(0xFF4A7C59).withOpacity(.4)
                      : const Color(0xFFF5F1EA),
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(rankEmoji,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 18)),
                  ),
                  SizedBox(width: 10),
                  Text(emoji, style: TextStyle(fontSize: 20)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(name,
                        style: TextStyle(
                            color: isMe ? const Color(0xFF4A7C59) : Colors.white,
                            fontWeight: isMe
                                ? FontWeight.w700
                                : FontWeight.w500,
                            fontSize: 14)),
                  ),
                  Text('$points pt',
                      style: TextStyle(
                          color: isMe
                              ? const Color(0xFF4A7C59)
                              : Colors.white.withOpacity(.5),
                          fontWeight: FontWeight.w700,
                          fontSize: 13)),
                ],
              ),
            );
          }),

          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFF5F1EA)),
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








