import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/tutorial_provider.dart';
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<TutorialProvider>().trigger('rewards_first_visit', context);
      }
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().paletteData;
    return BwScaffold(
      appBar: AppBar(
        title: Text(context.sL.rewards),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: p.accent,
          labelColor: p.accent,
          unselectedLabelColor: p.textSec,
          tabs: [
            Tab(text: context.sL.badges),
            Tab(text: context.sL.navRewards),
            Tab(text: 'Top'),
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

// ── Badges ────────────────────────────────────────────────────────────────────

class _BadgesTab extends StatelessWidget {
  const _BadgesTab();

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().paletteData;
    return Consumer<AppProvider>(builder: (_, app, __) {
      final earned = app.user?.earnedBadgeIds ?? [];

      final groups = <String, List<bw.BwBadge>>{};
      for (final b in bw.allBadges) {
        groups.putIfAbsent(b.category, () => []).add(b);
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Header summary card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                  color: p.accent.withValues(alpha: 0.3), width: 1),
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
                      style: TextStyle(
                          color: p.text,
                          fontSize: 28,
                          fontWeight: FontWeight.w700),
                    ),
                    Text(context.sL.badges,
                        style: TextStyle(color: p.textSec, fontSize: 13)),
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
                      color: p.textMut,
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
                      onTap: () =>
                          _showBadgeDetail(context, badge, isEarned, p),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        decoration: BoxDecoration(
                          color: isEarned
                              ? p.accent.withValues(alpha: 0.10)
                              : p.card,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isEarned
                                ? p.accent.withValues(alpha: 0.40)
                                : p.cardBorder,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Opacity(
                              opacity: isEarned ? 1.0 : 0.25,
                              child: Text(
                                badge.emoji,
                                style: const TextStyle(fontSize: 32),
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
                                  color: isEarned ? p.text : p.textMut,
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

  static void _showBadgeDetail(
    BuildContext context,
    bw.BwBadge badge,
    bool isEarned,
    BwPaletteData p,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Opacity(
              opacity: isEarned ? 1.0 : 0.3,
              child: Text(badge.emoji,
                  style: const TextStyle(fontSize: 56)),
            ),
            const SizedBox(height: 12),
            Text(
              badge.name,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: isEarned ? p.text : p.textSec,
                  fontWeight: FontWeight.w700,
                  fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              badge.description,
              textAlign: TextAlign.center,
              style: TextStyle(color: p.textSec, fontSize: 13),
            ),
            if (!isEarned) ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                    color: p.cardBorder,
                    borderRadius: BorderRadius.circular(8)),
                child: Text(
                  '🔒 Non ancora sbloccato',
                  style: TextStyle(fontSize: 12, color: p.textSec),
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Chiudi', style: TextStyle(color: p.accent)),
          ),
        ],
      ),
    );
  }
}

// ── Challenges ────────────────────────────────────────────────────────────────

class _ChallengesTab extends StatelessWidget {
  const _ChallengesTab();

  // (emoji, title, description, targetCount, points)
  static const _challenges = [
    ('🔥', '7 giorni di streak',
        'Completa almeno un\'attività per 7 giorni consecutivi', 7, 100),
    ('💧', 'Settimana idratata',
        'Bevi acqua ogni giorno per 7 giorni', 7, 70),
    ('🧘', 'Respira ogni giorno',
        '5 sessioni di respirazione questa settimana', 5, 75),
    ('⏱', 'Focus Master',
        '10 sessioni focus questa settimana', 10, 150),
    ('🌿', 'Piano perfetto',
        'Completa il piano giornaliero 3 volte', 3, 90),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().paletteData;
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
            color: p.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: p.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: p.accent.withValues(alpha: 0.10),
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
                        Text(
                          c.$2,
                          style: TextStyle(
                              color: p.text,
                              fontWeight: FontWeight.w700,
                              fontSize: 14),
                        ),
                        Text(
                          c.$3,
                          style: TextStyle(
                              color: p.textSec, fontSize: 11),
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: p.accent.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '+${c.$5} pt',
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: p.accent),
                    ),
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
                        backgroundColor: p.cardBorder,
                        valueColor: AlwaysStoppedAnimation(p.accent),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '$current/${c.$4}',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: p.accent),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Leaderboard ───────────────────────────────────────────────────────────────

class _LeaderboardTab extends StatelessWidget {
  const _LeaderboardTab();

  static const _entries = [
    ('Sara M.', 2840, '🌲'),
    ('Marco R.', 2310, '🌳'),
    ('Tu', 0, '🌿'),
    ('Elena B.', 1180, '🌿'),
    ('Luca P.', 980, '🌿'),
    ('Anna F.', 760, '🌱'),
  ];

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().paletteData;
    final s = context.sL;
    return Consumer<AppProvider>(builder: (_, app, __) {
      final userPoints = app.user?.points ?? 0;
      final userName = app.user?.name ?? 'Tu';

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.cardBorder),
            ),
            child: Column(
              children: [
                Text(
                  '🏆 Classifica',
                  style: TextStyle(
                      color: p.text,
                      fontWeight: FontWeight.w700,
                      fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text(
                  s.planToday,
                  style: TextStyle(color: p.textSec, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          ..._entries.asMap().entries.map((mapEntry) {
            final i = mapEntry.key;
            final e = mapEntry.value;
            final isMe = e.$1 == 'Tu';
            final name = isMe ? userName : e.$1;
            final points = isMe ? userPoints : e.$2;
            final emoji =
                isMe ? (app.user?.levelEmoji ?? '🌿') : e.$3;
            final rankEmoji = i == 0
                ? '🥇'
                : i == 1
                    ? '🥈'
                    : i == 2
                        ? '🥉'
                        : '${i + 1}.';

            return AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isMe
                    ? p.accent.withValues(alpha: 0.10)
                    : p.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isMe
                      ? p.accent.withValues(alpha: 0.40)
                      : p.cardBorder,
                ),
              ),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      rankEmoji,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(emoji, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      style: TextStyle(
                          color: isMe ? p.accent : p.text,
                          fontWeight: isMe
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 14),
                    ),
                  ),
                  Text(
                    '$points pt',
                    style: TextStyle(
                        color: isMe ? p.accent : p.textSec,
                        fontWeight: FontWeight.w700,
                        fontSize: 13),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: p.cardBorder),
            ),
            child: Text(
              '💡 La classifica si aggiorna ogni settimana. Completa le attività per scalare la classifica!',
              style: TextStyle(color: p.textSec, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      );
    });
  }
}
