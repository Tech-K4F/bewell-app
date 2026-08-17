import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
// RewardItem nascosto: conflitto con package:bewell/models/reward_model.dart
import 'package:google_mobile_ads/google_mobile_ads.dart' hide RewardItem;
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../services/referral_service.dart';

import '../../l10n/app_localizations.dart';
import '../../providers/theme_provider.dart';
import '../../providers/app_provider.dart';
import '../../models/reward_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/discount_model.dart';
import '../../models/inapp_item_model.dart';
import '../../providers/inapp_provider.dart';
import '../../providers/tutorial_provider.dart';
import '../../widgets/spotlight_overlay.dart';
import '../../widgets/bw_scaffold.dart';
import '../../widgets/banner_ad_widget.dart';
import '../../services/analytics_service.dart';

// ── Colori tematici marketplace ───────────────────────────────────────────────
const _purple = Color(0xFF7C3AED);

// ── Colori categoria reward (costanti light) ──────────────────────────────────
const _catColors = {
  'Food & Drink':    Color(0xFFE0F2F1),
  'Sport & Fitness': Color(0xFFFFF8E1),
  'Benessere':       Color(0xFFF3E5F5),
  'Cultura':         Color(0xFFE3F2FD),
  'Shopping':        Color(0xFFF5F5F5),
};
Color _catColor(String category) =>
    _catColors[category] ?? const Color(0xFFF5F5F5);

// ══════════════════════════════════════════════════════════════════════════════
// ROOT SCREEN
// ══════════════════════════════════════════════════════════════════════════════

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;

  static const List<SpotlightStep> _marketplaceSteps = [
    SpotlightStep(textId: 'marketplace_welcome'),
    SpotlightStep(textId: 'marketplace_points', targetId: 'spot_points_strip'),
    SpotlightStep(textId: 'marketplace_tabs',   targetId: 'spot_market_tabs'),
    SpotlightStep(textId: 'marketplace_card',   targetId: 'spot_reward_card'),
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _checkMarketplaceSpotlight();
    });
  }

  Future<void> _checkMarketplaceSpotlight() async {
    if (!mounted) return;
    final ctrl = context.read<SpotlightController>();
    final seen = await ctrl.hasSeenTutorial('marketplace_tour');
    if (!mounted) return;
    if (!seen) {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) ctrl.startTutorial('marketplace_tour', _marketplaceSteps);
      // Sopprime il Welly dialog rewards_first_visit per evitare duplicati —
      // via TutorialProvider vero (un bool SharedPreferences a parte non
      // veniva mai letto, il dialogo ricompariva comunque).
      if (mounted) {
        await context.read<TutorialProvider>().markSeenExternally('rewards_first_visit');
      }
    } else {
      if (mounted) {
        context.read<TutorialProvider>()
            .scheduleTrigger('rewards_first_visit', context);
      }
    }
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.sL;
    final p = context.read<ThemeProvider>().paletteData;

    return BwScaffold(
      bottomNavigationBar: const BannerAdWidget(),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header inline ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'marketplace',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: p.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    s.rewardsHeader,
                    style: TextStyle(
                      fontSize: 16,
                      fontStyle: FontStyle.italic,
                      fontFamily: 'Georgia',
                      color: p.text,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Striscia punti ───────────────────────────────────────────────
            SpotlightTarget(
              id: 'spot_points_strip',
              child: Consumer<AppProvider>(
                builder: (context, ap, _) => _PointsStrip(
                  points: ap.user?.points ?? 0,
                  p: p,
                  s: s,
                ),
              ),
            ),
            const SizedBox(height: 10),

            // ── Tab bar custom ───────────────────────────────────────────────
            SpotlightTarget(
              id: 'spot_market_tabs',
              child: _MarketplaceTabBar(controller: _tab, p: p, s: s),
            ),
            const SizedBox(height: 4),

            // ── Contenuto tab ────────────────────────────────────────────────
            Expanded(
              child: TabBarView(
                controller: _tab,
                children: [
                  _RewardsTab(tabController: _tab),
                  const _DiscountsTab(),
                  const _InAppTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Striscia punti ────────────────────────────────────────────────────────────

class _PointsStrip extends StatelessWidget {
  final int points;
  final BwPaletteData p;
  final BwStrings s;
  const _PointsStrip({required this.points, required this.p, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 0),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: p.cardBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$points',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'Georgia',
                  color: Colors.amber[700],
                ),
              ),
              Text(
                s.pointsAvailable,
                style: TextStyle(fontSize: 10, color: p.textSec),
              ),
            ],
          ),
          const Spacer(),
          const Text('⭐', style: TextStyle(fontSize: 18)),
        ],
      ),
    );
  }
}

// ── Tab bar stile pill ────────────────────────────────────────────────────────

class _MarketplaceTabBar extends StatelessWidget {
  final TabController controller;
  final BwPaletteData p;
  final BwStrings s;
  const _MarketplaceTabBar(
      {required this.controller, required this.p, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10),
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: p.bg2,
        borderRadius: BorderRadius.circular(10),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: p.text,
        unselectedLabelColor: p.textSec,
        labelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        unselectedLabelStyle:
            const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        dividerColor: Colors.transparent,
        tabs: [
          Tab(text: s.marketplaceTabRewards),
          Tab(text: s.marketplaceTabDiscounts),
          Tab(text: s.marketplaceTabInApp),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 1 — PREMI CON PUNTI
// ══════════════════════════════════════════════════════════════════════════════

class _RewardsTab extends StatefulWidget {
  final TabController tabController;
  const _RewardsTab({required this.tabController});

  @override
  State<_RewardsTab> createState() => _RewardsTabState();
}

class _RewardsTabState extends State<_RewardsTab> {
  List<RewardItem> _catalog = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await RewardRepository.instance.getCatalog();
      if (mounted) setState(() { _catalog = items; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    final s = context.sL;

    if (_loading) {
      return Center(child: CircularProgressIndicator(color: p.primary));
    }

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(s.errorGeneral,
                style: TextStyle(color: p.textSec, fontSize: 14)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _loadCatalog,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: p.btn,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(s.confirm,
                    style: TextStyle(
                        color: p.btnText,
                        fontWeight: FontWeight.w600,
                        fontSize: 13)),
              ),
            ),
          ],
        ),
      );
    }

    return Consumer<AppProvider>(
      builder: (context, ap, _) {
        final userPoints = ap.user?.points ?? 0;
        return ListView(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 40),
          children: [
            // Section label
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 10),
              child: Text(
                s.rewardsToRedeem.toUpperCase(),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                  color: p.textSec,
                ),
              ),
            ),

            // Lista RewardCard — la prima è avvolta in SpotlightTarget
            ..._catalog.asMap().entries.map((entry) {
              final card = _RewardCard(
                reward: entry.value,
                userPoints: userPoints,
                onTap: () => _showRedeemSheet(context, entry.value, ap, p),
              );
              return entry.key == 0
                  ? SpotlightTarget(id: 'spot_reward_card', child: card)
                  : card;
            }),

            const SizedBox(height: 8),

            // RewardedAdCard in fondo
            _RewardedAdCard(p: p, s: s),

            const SizedBox(height: 8),

            // Invita un amico — link referral
            _ReferralCard(p: p),
          ],
        );
      },
    );
  }

  void _showRedeemSheet(
    BuildContext context,
    RewardItem reward,
    AppProvider ap,
    BwPaletteData p,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ChangeNotifierProvider.value(
        value: ap,
        child: _RedeemSheet(reward: reward),
      ),
    );
  }
}

// ── Reward Card (row layout) ──────────────────────────────────────────────────

class _RewardCard extends StatelessWidget {
  final RewardItem reward;
  final int userPoints;
  final VoidCallback onTap;

  const _RewardCard({
    required this.reward,
    required this.userPoints,
    required this.onTap,
  });

  bool get _canAfford => userPoints >= reward.pointsCost;

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    final bgColor = _catColor(reward.category);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _canAfford
                ? p.primary.withValues(alpha: 0.25)
                : p.cardBorder,
            width: 0.5,
          ),
        ),
        child: Row(
          children: [
            // Emoji con sfondo colorato
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  reward.emoji,
                  style: TextStyle(
                    fontSize: 20,
                    color: _canAfford ? null : p.textMut,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 11),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reward.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _canAfford ? p.text : p.textMut,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        reward.brand,
                        style: TextStyle(fontSize: 11, color: p.textSec),
                      ),
                      const SizedBox(width: 6),
                      _TypeBadge(type: reward.type, p: p),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Pulsante punti
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _canAfford ? p.primary : p.bg2,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${reward.pointsCost} pt',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _canAfford ? Colors.white : p.textMut,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TypeBadge extends StatelessWidget {
  final String type;
  final BwPaletteData p;
  const _TypeBadge({required this.type, required this.p});

  @override
  Widget build(BuildContext context) {
    final label = switch (type) {
      'voucher'    => '🎟 voucher',
      'discount'   => '🏷 sconto',
      'experience' => '✨ esperienza',
      'digital'    => '💻 digitale',
      _            => type,
    };
    return Text(
      label,
      style: TextStyle(fontSize: 10, color: p.textMut),
    );
  }
}

// ── Bottom sheet riscatto ─────────────────────────────────────────────────────

enum _RedeemPhase { confirm, animating, success }

class _RedeemSheet extends StatefulWidget {
  final RewardItem reward;
  const _RedeemSheet({required this.reward});

  @override
  State<_RedeemSheet> createState() => _RedeemSheetState();
}

class _RedeemSheetState extends State<_RedeemSheet>
    with SingleTickerProviderStateMixin {
  _RedeemPhase _phase = _RedeemPhase.confirm;
  String? _code;
  late AnimationController _animCtrl;
  late Animation<double> _flyY;
  late Animation<double> _flyOpacity;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _flyY = Tween<double>(begin: 0, end: -30).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _flyOpacity = Tween<double>(begin: 1, end: 0).animate(
        CurvedAnimation(parent: _animCtrl, curve: Curves.easeIn));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _confirm(AppProvider ap) async {
    setState(() => _phase = _RedeemPhase.animating);
    _animCtrl.forward();
    final ok = await ap.redeemReward(widget.reward);
    await Future.delayed(const Duration(milliseconds: 520));
    if (!mounted) return;
    if (ok) {
      final code = ap.redeemedRewards
          .firstWhere((r) => r.rewardId == widget.reward.id)
          .code;
      setState(() { _phase = _RedeemPhase.success; _code = code; });
    } else {
      setState(() => _phase = _RedeemPhase.confirm);
      _animCtrl.reset();
      // Prima falliva in silenzio (punti insufficienti o, ora, scorte
      // esaurite per questo utente) senza dire perché al pulsante "conferma"
      // premuto.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.sL.rewardRedeemFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    final s = context.sL;
    return Consumer<AppProvider>(builder: (context, ap, _) {
      return Container(
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: EdgeInsets.fromLTRB(
            20, 16, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: switch (_phase) {
            _RedeemPhase.confirm   => _buildConfirm(context, ap, p, s),
            _RedeemPhase.animating => _buildAnimating(p),
            _RedeemPhase.success   => _buildSuccess(context, p, s),
          },
        ),
      );
    });
  }

  Widget _buildConfirm(
      BuildContext context, AppProvider ap, BwPaletteData p, BwStrings s) {
    return Column(
      key: const ValueKey('confirm'),
      mainAxisSize: MainAxisSize.min,
      children: [
        // Handle
        Container(
          width: 36, height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: p.cardBorder, borderRadius: BorderRadius.circular(2)),
        ),

        Text(
          s.rewardConfirmTitle,
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: p.text),
        ),
        const SizedBox(height: 8),
        Text(
          s.rewardConfirmBody.replaceAll('X', '${widget.reward.pointsCost}'),
          style: TextStyle(fontSize: 13, color: p.textSec, height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),

        // Reward preview
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: _catColor(widget.reward.category),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(widget.reward.emoji,
                    style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.reward.title,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: p.text)),
                Text(widget.reward.brand,
                    style: TextStyle(fontSize: 11, color: p.textSec)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: p.bg2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.cardBorder, width: 0.5),
                  ),
                  child: Center(
                    child: Text(s.cancel,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: p.textSec)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: () => _confirm(ap),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: p.btn,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(s.confirm,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: p.btnText)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildAnimating(BwPaletteData p) {
    return SizedBox(
      key: const ValueKey('animating'),
      height: 180,
      child: AnimatedBuilder(
        animation: _animCtrl,
        builder: (_, __) => Center(
          child: Transform.translate(
            offset: Offset(0, _flyY.value),
            child: Opacity(
              opacity: _flyOpacity.value,
              child: Text(
                '⭐ ${widget.reward.pointsCost} pt',
                style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: p.primary),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccess(
      BuildContext context, BwPaletteData p, BwStrings s) {
    final code = _code ?? '—';
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
            color: p.cardBorder, borderRadius: BorderRadius.circular(2)),
        ),

        // Welly text
        Text(
          s.rewardRedeemed,
          style: TextStyle(
              fontSize: 16, fontWeight: FontWeight.w700, color: p.text),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),

        // Code reveal
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: p.primaryLight,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: p.primary.withValues(alpha: 0.35), width: 0.5),
          ),
          child: Column(
            children: [
              Text(
                code,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 3,
                  color: p.primary,
                  fontFamily: 'Courier',
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Copia codice
        GestureDetector(
          onTap: () {
            Clipboard.setData(ClipboardData(text: code));
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(s.codeCopied),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ));
          },
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: p.btn,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.copy_rounded, size: 16, color: p.btnText),
                const SizedBox(width: 8),
                Text(
                  s.copyCode,
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: p.btnText),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Chiudi
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Text(
            s.cancel,
            style: TextStyle(fontSize: 13, color: p.textMut),
          ),
        ),
      ],
    );
  }
}

// ── RewardedAdCard ────────────────────────────────────────────────────────────
// Rewarded ad sempre volontario — mai forzato.
// Test ad unit ID usato in debug; sostituire con ID produzione prima del rilascio.

class _RewardedAdCard extends StatefulWidget {
  final BwPaletteData p;
  final BwStrings s;
  const _RewardedAdCard({required this.p, required this.s});

  @override
  State<_RewardedAdCard> createState() => _RewardedAdCardState();
}

class _RewardedAdCardState extends State<_RewardedAdCard> {
  RewardedAd? _rewardedAd;
  bool _adLoading = false;

  // TODO: sostituire con ID produzione prima del rilascio
  static const _adUnitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/5224354917'  // Test Android
      : 'ca-app-pub-REPLACE_WITH_PROD_ID/REPLACE'; // Produzione

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  @override
  void dispose() {
    _rewardedAd?.dispose();
    super.dispose();
  }

  void _loadAd() {
    if (_adLoading) return;
    setState(() => _adLoading = true);
    RewardedAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() { _rewardedAd = ad; _adLoading = false; });
          } else {
            ad.dispose();
          }
        },
        onAdFailedToLoad: (_) {
          if (mounted) setState(() { _rewardedAd = null; _adLoading = false; });
        },
      ),
    );
  }

  Future<void> _watchAd(BuildContext context) async {
    if (_rewardedAd == null) {
      _showUnavailableToast(context);
      _loadAd(); // riprova in background
      return;
    }

    final ap = context.read<AppProvider>();
    final s = context.sL;
    // Cattura messenger prima degli await per evitare uso di context asincrono
    final messenger = ScaffoldMessenger.of(context);

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        ad.dispose();
        if (mounted) { setState(() => _rewardedAd = null); _loadAd(); }
      },
      onAdFailedToShowFullScreenContent: (ad, _) {
        ad.dispose();
        if (mounted) {
          setState(() => _rewardedAd = null);
          _showUnavailableToast(context);
          _loadAd();
        }
      },
    );

    await _rewardedAd!.show(
      onUserEarnedReward: (_, __) async {
        await ap.addPoints(10);
        AnalyticsService.instance.logAdWatched(10);
        if (mounted) {
          messenger.showSnackBar(SnackBar(
            content: Text('+10 pt ${s.pointsAvailable}! 🎉'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 3),
          ));
        }
      },
    );
  }

  void _showUnavailableToast(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(
        widget.s.marketAdUnavailable,
        style: const TextStyle(fontSize: 13),
      ),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final s = widget.s;

    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: p.cardBorder, width: 0.5),
      ),
      child: GestureDetector(
        onTap: () => _showHelpDialog(context),
        behavior: HitTestBehavior.opaque,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icona play in cerchio
                Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    color: p.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.play_arrow_rounded,
                      color: p.primary, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.marketAdTitle,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.text),
                      ),
                      Text(
                        s.marketAdSubtitle,
                        style: TextStyle(fontSize: 11, color: p.textSec),
                      ),
                    ],
                  ),
                ),
                // Indicatore caricamento ad
                if (_adLoading)
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 1.5, color: p.textMut),
                  ),
              ],
            ),
            const SizedBox(height: 7),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  s.watchAd,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _rewardedAd != null ? p.primary : p.textMut),
                ),
                GestureDetector(
                  onTap: () => _showWhyDialog(context),
                  child: Text(
                    s.whyAds,
                    style: TextStyle(
                      fontSize: 11,
                      color: p.textSec,
                      decoration: TextDecoration.underline,
                      decorationColor: p.textSec,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    final p = widget.p;
    final s = widget.s;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: p.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: p.primaryLight, shape: BoxShape.circle),
              child: Icon(Icons.play_arrow_rounded, color: p.primary, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(s.marketAdTitle,
                  style: TextStyle(color: p.text, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ],
        ),
        content: Text(
          s.marketAdDialogBody,
          style: TextStyle(color: p.textSec, fontSize: 13, height: 1.6),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(s.cancel, style: TextStyle(color: p.textMut, fontSize: 13)),
          ),
          GestureDetector(
            onTap: () {
              Navigator.pop(dialogCtx);
              _watchAd(context);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(color: p.btn, borderRadius: BorderRadius.circular(10)),
              child: Text(
                s.marketWatchNow,
                style: TextStyle(color: p.btnText, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showWhyDialog(BuildContext context) {
    final p = widget.p;
    final s = widget.s;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.card,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          s.whyAdsTitle,
          style: TextStyle(
              color: p.text, fontWeight: FontWeight.w700, fontSize: 15),
        ),
        content: Text(
          s.whyAdsBody,
          style: TextStyle(color: p.textSec, fontSize: 13, height: 1.6),
        ),
        actions: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: p.btn,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                s.dialogGotIt,
                style: TextStyle(
                    color: p.btnText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ReferralCard ──────────────────────────────────────────────────────────────
// Genera/mostra il codice invito personale e permette di condividerlo o di
// riscattare il codice di un amico. +50 punti al proprietario del codice
// quando qualcuno lo riscatta (accredito gestito da ReferralService via
// Firestore, riscosso in background al prossimo avvio — vedi AppProvider).

class _ReferralCard extends StatefulWidget {
  final BwPaletteData p;
  const _ReferralCard({required this.p});

  @override
  State<_ReferralCard> createState() => _ReferralCardState();
}

class _ReferralCardState extends State<_ReferralCard> {
  String? _myCode;
  bool _loading = true;
  final _codeCtrl = TextEditingController();
  bool _redeeming = false;

  @override
  void initState() {
    super.initState();
    _loadCode();
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCode() async {
    final code = await ReferralService.instance.getOrCreateMyCode();
    if (mounted) setState(() { _myCode = code; _loading = false; });
  }

  void _share(BwStrings s) {
    final code = _myCode;
    if (code == null) return;
    Share.share(s.referralShareMessage(code));
  }

  Future<void> _redeem(BuildContext context, BwStrings s) async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty || _redeeming) return;
    setState(() => _redeeming = true);
    final messenger = ScaffoldMessenger.of(context);
    final error = await ReferralService.instance.redeemCode(code);
    if (!mounted) return;
    setState(() => _redeeming = false);
    if (error == null) {
      _codeCtrl.clear();
      messenger.showSnackBar(SnackBar(
        content: Text(s.referralApplied),
        behavior: SnackBarBehavior.floating,
      ));
    } else {
      messenger.showSnackBar(SnackBar(
        content: Text(_errorLabel(error, s)),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  String _errorLabel(String code, BwStrings s) {
    switch (code) {
      case 'invalid_code':      return s.referralErrorInvalid;
      case 'own_code':          return s.referralErrorOwn;
      case 'already_redeemed':  return s.referralErrorAlready;
      case 'not_signed_in':     return s.referralErrorNotSignedIn;
      default:                  return s.referralErrorGeneric;
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final s = context.sL;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: p.cardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: p.primaryLight, shape: BoxShape.circle),
                child: Icon(Icons.person_add_alt_1_rounded, color: p.primary, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.referralTitle,
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.text)),
                    Text(s.referralSubtitle,
                        style: TextStyle(fontSize: 11, color: p.textSec)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (_loading)
            Center(
              child: SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 1.5, color: p.textMut),
              ),
            )
          else if (_myCode == null)
            GestureDetector(
              onTap: () {
                setState(() => _loading = true);
                _loadCode();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: p.card,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.cardBorder),
                ),
                child: Center(
                  child: Text(
                    s.referralRetry,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: p.textSec, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            )
          else
            GestureDetector(
              onTap: () => _share(s),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: p.btn,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    s.referralShareButton(_myCode ?? ''),
                    style: TextStyle(color: p.btnText, fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _codeCtrl,
                  textCapitalization: TextCapitalization.characters,
                  style: TextStyle(fontSize: 12, color: p.text),
                  decoration: InputDecoration(
                    isDense: true,
                    hintText: s.referralHint,
                    hintStyle: TextStyle(fontSize: 12, color: p.textMut),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: p.cardBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide(color: p.primary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _redeem(context, s),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: p.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _redeeming
                      ? SizedBox(
                          width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 1.5, color: p.primary),
                        )
                      : Text(s.referralApply,
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.primary)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 2 — SCONTI ESCLUSIVI
// ══════════════════════════════════════════════════════════════════════════════

class _DiscountsTab extends StatelessWidget {
  const _DiscountsTab();

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    final s = context.sL;
    const discounts = DiscountCatalog.all;

    return ListView(
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 40),
      children: [
        // Section label
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 10),
          child: Text(
            s.discountsActive.toUpperCase(),
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.4,
              color: p.textSec,
            ),
          ),
        ),

        // Lista DiscountCard
        ...discounts.map((d) => _DiscountCard(
              discount: d,
              onTap: () => _showDiscountSheet(context, d, p, s),
            )),

        // Nota in fondo
        Padding(
          padding: const EdgeInsets.only(top: 12, left: 2),
          child: Text(
            s.discountsNote,
            style: TextStyle(fontSize: 11, color: p.textMut, height: 1.5),
          ),
        ),
      ],
    );
  }

  void _showDiscountSheet(
    BuildContext context,
    BwDiscount discount,
    BwPaletteData p,
    BwStrings s,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _DiscountSheet(discount: discount, p: p, s: s),
    );
  }
}

// ── Discount Card ─────────────────────────────────────────────────────────────

class _DiscountCard extends StatelessWidget {
  final BwDiscount discount;
  final VoidCallback onTap;
  const _DiscountCard({required this.discount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: p.cardBorder, width: 0.5),
        ),
        child: Row(
          children: [
            // Emoji in cerchio colorato
            Container(
              width: 38, height: 38,
              decoration: BoxDecoration(
                color: discount.bgColor,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(discount.categoryEmoji,
                    style: const TextStyle(fontSize: 20)),
              ),
            ),
            const SizedBox(width: 11),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    discount.brandName,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: p.text),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        discount.description,
                        style: TextStyle(fontSize: 11, color: p.textSec),
                      ),
                      const SizedBox(width: 6),
                      // Exclusive badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F5E9),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          discount.exclusiveLabel,
                          style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2E7D32)),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Pulsante "Ottieni"
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.amber[700],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                context.sL.unlockItem,
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Discount Bottom Sheet ─────────────────────────────────────────────────────

class _DiscountSheet extends StatelessWidget {
  final BwDiscount discount;
  final BwPaletteData p;
  final BwStrings s;
  const _DiscountSheet(
      {required this.discount, required this.p, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, 24 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
                color: p.cardBorder, borderRadius: BorderRadius.circular(2)),
          ),

          // Header brand + descrizione
          Row(
            children: [
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: discount.bgColor,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(discount.categoryEmoji,
                      style: const TextStyle(fontSize: 24)),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      discount.brandName,
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: p.text),
                    ),
                    Text(
                      discount.description,
                      style: TextStyle(fontSize: 13, color: p.textSec),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        discount.exclusiveLabel,
                        style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2E7D32)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Codice in box grande
          Container(
            width: double.infinity,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: p.bg2,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.cardBorder, width: 0.5),
            ),
            child: Column(
              children: [
                Text(
                  discount.code,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    color: p.text,
                    fontFamily: 'Courier',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Copia codice
          GestureDetector(
            onTap: () => _copyCode(context),
            child: Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                color: p.btn,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.copy_rounded, size: 16, color: p.btnText),
                  const SizedBox(width: 8),
                  Text(
                    s.copyCode,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: p.btnText),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Vai al sito
          GestureDetector(
            onTap: () => _openSite(context),
            child: Container(
              width: double.infinity,
              height: 46,
              decoration: BoxDecoration(
                color: p.bg2,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.cardBorder, width: 0.5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.open_in_new_rounded, size: 15, color: p.textSec),
                  const SizedBox(width: 6),
                  Text(
                    s.goToSite,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: p.textSec),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Affiliate note
          Text(
            s.affiliateNote,
            style: TextStyle(fontSize: 10, color: p.textMut),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _copyCode(BuildContext context) {
    Clipboard.setData(ClipboardData(text: discount.code));
    AnalyticsService.instance.logDiscountObtained(discount.id);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(context.sL.codeCopied),
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      duration: const Duration(seconds: 2),
    ));
  }

  Future<void> _openSite(BuildContext context) async {
    AnalyticsService.instance.logDiscountObtained(discount.id);
    final uri = Uri.parse(discount.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// TAB 3 — CONTENUTI IN-APP + PREMIUM
// ══════════════════════════════════════════════════════════════════════════════

class _InAppTab extends StatelessWidget {
  const _InAppTab();

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    final s = context.sL;

    return Consumer2<AppProvider, InAppProvider>(
      builder: (context, ap, inApp, _) {
        final userPoints = ap.user?.points ?? 0;
        return ListView(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 40),
          children: [
            // ── Banner Premium ────────────────────────────────────────────
            _PremiumBanner(p: p, s: s),
            const SizedBox(height: 20),

            // ── Welly ─────────────────────────────────────────────────────
            _InAppSectionLabel(label: s.inAppWelly, p: p),
            const SizedBox(height: 8),
            _InAppGrid(
              items: InAppCatalog.byCategory('welly'),
              userPoints: userPoints,
              inApp: inApp,
              ap: ap,
              p: p,
              s: s,
            ),
            const SizedBox(height: 20),

            // ── Soundscape ────────────────────────────────────────────────
            _InAppSectionLabel(label: s.inAppSoundscape, p: p),
            const SizedBox(height: 8),
            _InAppGrid(
              items: InAppCatalog.byCategory('soundscape'),
              userPoints: userPoints,
              inApp: inApp,
              ap: ap,
              p: p,
              s: s,
            ),
            const SizedBox(height: 20),

            // ── Minigame ──────────────────────────────────────────────────
            _InAppSectionLabel(label: s.inAppMinigame, p: p),
            const SizedBox(height: 8),
            ...InAppCatalog.byCategory('minigame').map((item) => _InAppListCard(
                  item: item,
                  userPoints: userPoints,
                  inApp: inApp,
                  ap: ap,
                  p: p,
                  s: s,
                )),

            // ── Percorsi ──────────────────────────────────────────────────
            const SizedBox(height: 20),
            _InAppSectionLabel(label: s.inAppPercorsi, p: p),
            const SizedBox(height: 8),
            ...InAppCatalog.byCategory('percorso').map((item) => _InAppListCard(
                  item: item,
                  userPoints: userPoints,
                  inApp: inApp,
                  ap: ap,
                  p: p,
                  s: s,
                )),
          ],
        );
      },
    );
  }
}

// ── Premium Banner ─────────────────────────────────────────────────────────────

class _PremiumBanner extends StatelessWidget {
  final BwPaletteData p;
  final BwStrings s;
  const _PremiumBanner({required this.p, required this.s});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0x147C3AED), // purple 8%
            Color(0x0F2DD4BF), // teal 6%
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0x337C3AED), width: 0.5), // purple 20%
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Be Well Premium',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500, color: p.text),
              ),
              const Spacer(),
              Text(
                s.premiumPrice('3.99€'),
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: _purple),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _PremiumFeature(s.premiumAllContent),
          _PremiumFeature(s.premiumPoints),
          _PremiumFeature(s.premiumWelly),
          _PremiumFeature(s.premiumDiscounts),
          const SizedBox(height: 8),
          // Pulsante trial
          GestureDetector(
            onTap: () {
              AnalyticsService.instance.logPremiumTapped();
              // TODO: implementare acquisto in-app con RevenueCat/StoreKit
            },
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: const Color(0x1A7C3AED), // purple 10%
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: const Color(0x407C3AED), width: 0.5), // purple 25%
              ),
              child: Text(
                s.premiumTrial,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 10,
                    color: _purple,
                    fontWeight: FontWeight.w500),
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            s.premiumOr,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 9, color: p.textSec),
          ),
        ],
      ),
    );
  }
}

class _PremiumFeature extends StatelessWidget {
  final String text;
  const _PremiumFeature(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          const Text('·',
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _purple)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text,
                style: const TextStyle(fontSize: 11, color: _purple)),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _InAppSectionLabel extends StatelessWidget {
  final String label;
  final BwPaletteData p;
  const _InAppSectionLabel({required this.label, required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: p.textSec,
        ),
      ),
    );
  }
}

// ── Grid 2 colonne (welly / soundscape) ──────────────────────────────────────

class _InAppGrid extends StatelessWidget {
  final List<InAppItem> items;
  final int userPoints;
  final InAppProvider inApp;
  final AppProvider ap;
  final BwPaletteData p;
  final BwStrings s;

  const _InAppGrid({
    required this.items,
    required this.userPoints,
    required this.inApp,
    required this.ap,
    required this.p,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final item = items[i];
        final unlocked = inApp.isUnlocked(item.id);
        final canAfford = userPoints >= item.pointsCost;
        return _InAppGridCard(
          item: item,
          unlocked: unlocked,
          canAfford: canAfford,
          s: s,
          p: p,
          onTap: unlocked
              ? null
              : () => _showUnlockSheet(context, item, ap, inApp, p, s),
        );
      },
    );
  }

  void _showUnlockSheet(
    BuildContext context,
    InAppItem item,
    AppProvider ap,
    InAppProvider inApp,
    BwPaletteData p,
    BwStrings s,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _UnlockSheet(
          item: item, ap: ap, inApp: inApp, p: p, s: s),
    );
  }
}

class _InAppGridCard extends StatelessWidget {
  final InAppItem item;
  final bool unlocked;
  final bool canAfford;
  final BwPaletteData p;
  final BwStrings s;
  final VoidCallback? onTap;

  const _InAppGridCard({
    required this.item,
    required this.unlocked,
    required this.canAfford,
    required this.p,
    required this.s,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: (!unlocked && !canAfford) ? 0.55 : 1.0,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: unlocked ? p.primaryLight : p.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unlocked
                  ? p.primary.withValues(alpha: 0.3)
                  : p.cardBorder,
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 24)),
              const Spacer(),
              Text(
                item.name,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: p.text),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (item.description != null) ...[
                const SizedBox(height: 2),
                Text(
                  item.description!,
                  style: TextStyle(fontSize: 10, color: p.textSec),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 6),
              unlocked
                  ? Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 13, color: p.primary),
                        const SizedBox(width: 4),
                        Text(
                          s.itemUnlocked,
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: p.primary),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Text(
                          '${item.pointsCost} pt',
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: _purple),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: _purple,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            s.unlockItem,
                            style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: Colors.white),
                          ),
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

// ── Lista (minigame / percorsi) ───────────────────────────────────────────────

class _InAppListCard extends StatelessWidget {
  final InAppItem item;
  final int userPoints;
  final InAppProvider inApp;
  final AppProvider ap;
  final BwPaletteData p;
  final BwStrings s;

  const _InAppListCard({
    required this.item,
    required this.userPoints,
    required this.inApp,
    required this.ap,
    required this.p,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final unlocked = inApp.isUnlocked(item.id);
    final canAfford = userPoints >= item.pointsCost;

    return Opacity(
      opacity: (!unlocked && !canAfford) ? 0.55 : 1.0,
      child: GestureDetector(
        onTap: unlocked
            ? null
            : () => _showUnlockSheet(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(11),
          decoration: BoxDecoration(
            color: unlocked ? p.primaryLight : p.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: unlocked
                  ? p.primary.withValues(alpha: 0.3)
                  : p.cardBorder,
              width: 0.5,
            ),
          ),
          child: Row(
            children: [
              // Emoji in cerchio
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3E5F5), // purple-light
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child:
                      Text(item.emoji, style: const TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 11),

              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: p.text),
                    ),
                    if (item.description != null)
                      Text(
                        item.description!,
                        style: TextStyle(fontSize: 11, color: p.textSec),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Badge sblocco
              unlocked
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle_rounded,
                            size: 14, color: p.primary),
                        const SizedBox(width: 4),
                        Text(
                          s.itemUnlocked,
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: p.primary),
                        ),
                      ],
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _purple,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${item.pointsCost} pt',
                        style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUnlockSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) =>
          _UnlockSheet(item: item, ap: ap, inApp: inApp, p: p, s: s),
    );
  }
}

// ── Bottom sheet sblocco in-app ───────────────────────────────────────────────

enum _UnlockPhase { confirm, success }

class _UnlockSheet extends StatefulWidget {
  final InAppItem item;
  final AppProvider ap;
  final InAppProvider inApp;
  final BwPaletteData p;
  final BwStrings s;

  const _UnlockSheet({
    required this.item,
    required this.ap,
    required this.inApp,
    required this.p,
    required this.s,
  });

  @override
  State<_UnlockSheet> createState() => _UnlockSheetState();
}

class _UnlockSheetState extends State<_UnlockSheet> {
  _UnlockPhase _phase = _UnlockPhase.confirm;
  bool _loading = false;

  Future<void> _unlock() async {
    if (_loading) return;
    setState(() => _loading = true);
    final ok = await widget.inApp.unlockItem(
        widget.item.id, widget.item.pointsCost, widget.ap);
    if (!mounted) return;
    if (ok) {
      setState(() { _phase = _UnlockPhase.success; _loading = false; });
    } else {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(widget.s.rewardConfirmBody
            .replaceAll('X', '${widget.item.pointsCost}')),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final s = widget.s;
    final userPoints = widget.ap.user?.points ?? 0;
    final canAfford = userPoints >= widget.item.pointsCost;

    return Container(
      decoration: BoxDecoration(
        color: p.bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 36),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _phase == _UnlockPhase.confirm
            ? _buildConfirm(context, p, s, userPoints, canAfford)
            : _buildSuccess(context, p, s),
      ),
    );
  }

  Widget _buildConfirm(BuildContext context, BwPaletteData p, BwStrings s,
      int userPoints, bool canAfford) {
    return Column(
      key: const ValueKey('confirm'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
              color: p.cardBorder, borderRadius: BorderRadius.circular(2)),
        ),

        Text(widget.item.emoji, style: const TextStyle(fontSize: 36)),
        const SizedBox(height: 10),
        Text(
          widget.item.name,
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: p.text),
          textAlign: TextAlign.center,
        ),
        if (widget.item.description != null) ...[
          const SizedBox(height: 4),
          Text(
            widget.item.description!,
            style: TextStyle(fontSize: 13, color: p.textSec),
          ),
        ],
        const SizedBox(height: 16),

        // Costo
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: p.bg2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.cardBorder, width: 0.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${s.unlockItem} per',
                  style: TextStyle(fontSize: 13, color: p.textSec)),
              Text(
                '${widget.item.pointsCost} pt ⭐',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _purple),
              ),
            ],
          ),
        ),

        if (!canAfford) ...[
          const SizedBox(height: 8),
          Text(
            'Ti mancano ${widget.item.pointsCost - userPoints} pt',
            style: TextStyle(fontSize: 12, color: p.textMut),
          ),
        ],
        const SizedBox(height: 20),

        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: p.bg2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: p.cardBorder, width: 0.5),
                  ),
                  child: Center(
                    child: Text(s.cancel,
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: p.textSec)),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: GestureDetector(
                onTap: canAfford && !_loading ? _unlock : null,
                child: Container(
                  height: 46,
                  decoration: BoxDecoration(
                    color: canAfford ? _purple : p.bg2,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: _loading
                        ? const SizedBox(
                            width: 18, height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white))
                        : Text(
                            s.unlockItem,
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: canAfford
                                    ? Colors.white
                                    : p.textMut),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSuccess(BuildContext context, BwPaletteData p, BwStrings s) {
    return Column(
      key: const ValueKey('success'),
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 36, height: 4,
          margin: const EdgeInsets.only(bottom: 20),
          decoration: BoxDecoration(
              color: p.cardBorder, borderRadius: BorderRadius.circular(2)),
        ),
        const Text('🎉', style: TextStyle(fontSize: 40)),
        const SizedBox(height: 12),
        Text(
          '${widget.item.emoji} ${widget.item.name}',
          style: TextStyle(
              fontSize: 17, fontWeight: FontWeight.w700, color: p.text),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_rounded, size: 16, color: p.primary),
            const SizedBox(width: 6),
            Text(s.itemUnlocked,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: p.primary)),
          ],
        ),
        const SizedBox(height: 24),
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: p.btn,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'Ok',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: p.btnText),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


