import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../theme/app_theme.dart';
import '../../widgets/activity_card.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/stat_chip.dart';
import '../../widgets/badge_toast.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buongiorno';
    if (h < 17) return 'Buon pomeriggio';
    return 'Buonasera';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BwColors.darkPanel,
      body: Consumer<AppProvider>(
        builder: (context, p, _) {
          // Show badge toast if new badges earned
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (p.newlyEarnedBadges.isNotEmpty && context.mounted) {
              final badgeId = p.newlyEarnedBadges.first;
              BadgeToast.show(context, badgeId);
              p.clearNewBadges();
            }
          });

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                pinned: true,
                expandedHeight: 110,
                backgroundColor: BwColors.darkPanel,
                flexibleSpace: FlexibleSpaceBar(
                  background: Container(
                    padding: const EdgeInsets.fromLTRB(20, 52, 16, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Text('${_greeting()} 👋',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.white.withOpacity(.4))),
                              const SizedBox(height: 2),
                              Text(p.user?.name ?? 'Benvenuto',
                                  style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: -.5)),
                            ],
                          ),
                        ),
                        // Points pill
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: BwColors.amberLight,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: BwColors.amber.withOpacity(.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('⭐',
                                  style: TextStyle(fontSize: 12)),
                              const SizedBox(width: 4),
                              Text('${p.user?.points ?? 0} pt',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: BwColors.amber)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // Progress card
                    _ProgressCard(provider: p),
                    const SizedBox(height: 14),

                    // Stats strip
                    Row(children: [
                      StatChip(
                          emoji: '🔥',
                          value: '${p.user?.streak ?? 0}',
                          label: 'Streak'),
                      const SizedBox(width: 8),
                      StatChip(
                          emoji: '⭐',
                          value: '${p.user?.points ?? 0}',
                          label: 'Punti'),
                      const SizedBox(width: 8),
                      StatChip(
                          emoji: '🏅',
                          value:
                              '${p.user?.earnedBadgeIds.length ?? 0}',
                          label: 'Badge'),
                    ]),
                    const SizedBox(height: 22),

                    // Quick action buttons
                    _QuickActions(provider: p),
                    const SizedBox(height: 22),

                    // Today's plan header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Piano di oggi',
                            style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                                color: Colors.white)),
                        Text('${p.completedCount}/${p.totalCount}',
                            style: const TextStyle(
                                fontSize: 13,
                                color: BwColors.teal,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (p.todayPlan.isEmpty)
                      _emptyState()
                    else
                      ...p.todayPlan.map((a) => ActivityCard(
                            activity: a,
                            isCompleted:
                                p.completedToday.contains(a.id),
                            onComplete: () =>
                                p.completeActivity(a.id),
                          )),
                  ]),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          children: [
            const Text('🌿', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 12),
            Text('Nessuna attività per oggi',
                style: TextStyle(
                    color: Colors.white.withOpacity(.4), fontSize: 14)),
          ],
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  final AppProvider provider;
  const _ProgressCard({required this.provider});

  @override
  Widget build(BuildContext context) {
    final pct = provider.todayCompletionPct;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            BwColors.teal.withOpacity(.14),
            BwColors.blue.withOpacity(.07),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: BwColors.teal.withOpacity(.2)),
      ),
      child: Row(
        children: [
          ProgressRing(progress: pct, size: 78),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${(pct * 100).round()}% completato',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                const SizedBox(height: 4),
                Text(
                    '${provider.completedCount} di ${provider.totalCount} attività',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.white.withOpacity(.5))),
                if (pct == 1) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: BwColors.amberLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text('🏆 Piano completato!',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: BwColors.amber)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  final AppProvider provider;
  const _QuickActions({required this.provider});

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('⏱', 'Focus', BwColors.purple, 2),
      ('🧘', 'Respira', BwColors.blue, 3),
      ('🏃', 'Muoviti', BwColors.amber, 1),
      ('💧', 'Acqua', BwColors.teal, 1),
    ];

    return Row(
      children: actions.map((a) {
        final idx = actions.indexOf(a);
        return Expanded(
          child: GestureDetector(
            onTap: () {
              if (idx == 0) provider.setNavIndex(2); // Focus tab
              if (idx == 1) {
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => const _BreathingShortcut()));
              }
            },
            child: Container(
              margin: EdgeInsets.only(right: idx < 3 ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: a.$3.withOpacity(.1),
                borderRadius: BorderRadius.circular(12),
                border:
                    Border.all(color: a.$3.withOpacity(.2)),
              ),
              child: Column(
                children: [
                  Text(a.$1, style: const TextStyle(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text(a.$2,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: a.$3)),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Quick shortcut that navigates to stress screen
class _BreathingShortcut extends StatelessWidget {
  const _BreathingShortcut();
  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pop();
      context.read<AppProvider>().setNavIndex(2);
    });
    return const SizedBox();
  }
}
