import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/bw_scaffold.dart';
import 'package:flutter/services.dart';
import '../../providers/app_provider.dart';
import '../../models/reward_model.dart';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});
  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _selectedCategory = 'Tutti';
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    return BwScaffold(
      appBar: AppBar(
        title: Text(context.sL.rewards),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: p.primary,
          labelColor: p.primary,
          unselectedLabelColor: p.textSec,
          tabs: [
            Tab(text: context.sL.rewards),
            Tab(text: context.sL.rewardsPoints),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _CatalogTab(
            selectedCategory: _selectedCategory,
            search: _search,
            onCategoryChanged: (c) => setState(() => _selectedCategory = c),
            onSearchChanged: (s) => setState(() => _search = s),
          ),
          const _WalletTab(),
        ],
      ),
    );
  }
}

// ─── Catalog Tab ──────────────────────────────────────────────────────────────

class _CatalogTab extends StatefulWidget {
  final String selectedCategory;
  final String search;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<String> onSearchChanged;

  const _CatalogTab({
    required this.selectedCategory,
    required this.search,
    required this.onCategoryChanged,
    required this.onSearchChanged,
  });

  @override
  State<_CatalogTab> createState() => _CatalogTabState();
}

class _CatalogTabState extends State<_CatalogTab> {
  List<RewardItem> _catalog = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    setState(() { _loading = true; _error = null; });
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

    // Loading state
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: p.primary),
            const SizedBox(height: 16),
            Text(context.sL.rewardsLockedDesc,
                style: TextStyle(color: p.textSec, fontSize: 13)),
          ],
        ),
      );
    }

    // Error state
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 40)),
            const SizedBox(height: 12),
            Text(context.sL.errorGeneral,
                style: TextStyle(color: p.textSec, fontSize: 14)),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadCatalog,
              child: Text(context.sL.confirm),
            ),
          ],
        ),
      );
    }

    final filtered = _catalog.where((r) {
      final matchCat = widget.selectedCategory == 'Tutti' ||
          r.category == widget.selectedCategory;
      final matchSearch = widget.search.isEmpty ||
          r.title.toLowerCase().contains(widget.search.toLowerCase()) ||
          r.brand.toLowerCase().contains(widget.search.toLowerCase());
      return matchCat && matchSearch;
    }).toList();

    return Consumer<AppProvider>(builder: (context, ap, _) {
      final userPoints = ap.user?.points ?? 0;

      return Column(
        children: [
          // Points banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  p.primary.withOpacity(.14),
                  p.primary.withOpacity(.05),
                ]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.primary.withOpacity(.25)),
              ),
              child: Row(
                children: [
                  const Text('⭐', style: TextStyle(fontSize: 24)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$userPoints punti disponibili',
                            style: TextStyle(
                                color: p.text,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        Text('Completa attività per guadagnarne altri',
                            style: TextStyle(
                                color: p.textMut,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: widget.onSearchChanged,
              style: TextStyle(color: p.text),
              decoration: InputDecoration(
                hintText: context.sL.rewards,
                prefixIcon: Icon(Icons.search, color: p.textMut),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(height: 10),

          // Category chips
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: rewardCategories.length,
              itemBuilder: (_, i) {
                final cat = rewardCategories[i];
                final sel = cat == widget.selectedCategory;
                return GestureDetector(
                  onTap: () => widget.onCategoryChanged(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: sel ? p.primary : p.bg2,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(cat,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel ? Colors.white : p.textSec)),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🔍', style: TextStyle(fontSize: 40)),
                        const SizedBox(height: 10),
                        Text(context.sL.rewardsLocked,
                            style: TextStyle(
                                color: p.textMut,
                                fontSize: 14)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCatalog,
                    color: p.primary,
                    child: GridView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: .78,
                      ),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) => _RewardCard(
                        reward: filtered[i],
                        userPoints: userPoints,
                        onTap: () => _showDetail(context, filtered[i], ap),
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }

  void _showDetail(BuildContext context, RewardItem reward, AppProvider ap) {
    final p = context.read<ThemeProvider>().paletteData;
    showModalBottomSheet(
      context: context,
      backgroundColor: p.card,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeNotifierProvider.value(
        value: ap,
        child: _RewardDetailSheet(reward: reward),
      ),
    );
  }
}

// ─── Reward Card ──────────────────────────────────────────────────────────────

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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _canAfford
                ? p.primary.withOpacity(.3)
                : p.cardBorder,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji area
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: _canAfford ? p.bg2 : p.bg2.withOpacity(.6),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(reward.emoji,
                        style: TextStyle(
                            fontSize: 42,
                            color: _canAfford
                                ? null
                                : p.textMut)),
                  ),
                  if (reward.originalValue != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.primaryLight,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(reward.originalValue!,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: p.primary)),
                      ),
                    ),
                  if (!_canAfford)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: p.bg2,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: const Text('🔒',
                            style: TextStyle(fontSize: 10)),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reward.brand,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: p.textMut)),
                    const SizedBox(height: 2),
                    Text(reward.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _canAfford ? p.text : p.textMut)),
                    const Spacer(),
                    Row(
                      children: [
                        const Text('⭐', style: TextStyle(fontSize: 11)),
                        const SizedBox(width: 3),
                        Text('${reward.pointsCost}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _canAfford
                                    ? p.primary
                                    : p.textMut)),
                        const SizedBox(width: 3),
                        Text('pt',
                            style: TextStyle(
                                fontSize: 10,
                                color: p.textMut)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Detail Sheet ─────────────────────────────────────────────────────────────

class _RewardDetailSheet extends StatelessWidget {
  final RewardItem reward;
  const _RewardDetailSheet({required this.reward});

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    return Consumer<AppProvider>(builder: (context, ap, _) {
      final userPoints = ap.user?.points ?? 0;
      final canAfford = userPoints >= reward.pointsCost;
      final pointsAfter = userPoints - reward.pointsCost;

      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: p.cardBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: p.bg2,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                          child: Text(reward.emoji,
                              style: const TextStyle(fontSize: 38))),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(reward.brand,
                              style: TextStyle(
                                  color: p.textSec,
                                  fontSize: 12)),
                          Text(reward.title,
                              style: TextStyle(
                                  color: p.text,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 4),
                          _typePill(context, reward.type, p),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                Text(reward.description,
                    style: TextStyle(
                        color: p.textSec,
                        fontSize: 14,
                        height: 1.5)),
                const SizedBox(height: 20),

                // Cost breakdown
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: p.bg2,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.cardBorder),
                  ),
                  child: Column(
                    children: [
                      _costRow('I tuoi punti', '$userPoints ⭐', p.text, p),
                      const SizedBox(height: 8),
                      _costRow('Costo premio', '- ${reward.pointsCost} ⭐',
                          p.textSec, p),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: p.cardBorder, height: 1),
                      ),
                      _costRow('Punti rimanenti', '$pointsAfter ⭐',
                          canAfford ? p.primary : p.textMut,
                          p, bold: true),
                    ],
                  ),
                ),

                if (!canAfford) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: p.bg2,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: p.cardBorder),
                    ),
                    child: Row(
                      children: [
                        const Text('⚠️', style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ti mancano ${reward.pointsCost - userPoints} punti. Completa altre attività!',
                            style: TextStyle(
                                color: p.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed:
                      canAfford ? () => _confirmRedeem(context, ap, p) : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: canAfford
                        ? p.primary
                        : p.bg2,
                    disabledForegroundColor: p.textMut,
                  ),
                  child: Text(
                    canAfford
                        ? 'Riscatta per ${reward.pointsCost} pt ⭐'
                        : 'Punti insufficienti',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    });
  }

  Widget _typePill(BuildContext context, String type, dynamic p) {
    final labels = {
      'voucher': ('🎟️', 'Voucher', p.primary),
      'discount': ('🏷️', 'Sconto', p.primary),
      'experience': ('✨', 'Esperienza', p.accent),
      'digital': ('💻', 'Digitale', p.primary),
    };
    final l = labels[type] ?? ('🎁', type, p.primary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: (l.$3 as Color).withOpacity(.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('${l.$1} ${l.$2}',
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: l.$3 as Color)),
    );
  }

  Widget _costRow(String label, String value, Color valueColor, dynamic p,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: (p.textSec) as Color, fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }

  void _confirmRedeem(BuildContext context, AppProvider ap, dynamic p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: p.card as Color,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Riscatta ${reward.emoji} ${reward.title}?',
            style: TextStyle(
                color: p.text as Color,
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        content: Text(
          'Verranno scalati ${reward.pointsCost} punti dal tuo saldo.\nRiceverai un codice da utilizzare subito.',
          style: TextStyle(color: p.textSec as Color, fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla',
                style: TextStyle(color: p.textMut as Color)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);
              final ok = await ap.redeemReward(reward);
              if (ok && context.mounted) _showSuccessDialog(context, ap, p);
            },
            child: Text(context.sL.confirm),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, AppProvider ap, dynamic p) {
    final redeemed = ap.redeemedRewards.first;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: p.card as Color,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🎉', style: TextStyle(fontSize: 56)),
            const SizedBox(height: 12),
            Text(context.sL.rewardsPoints,
                style: TextStyle(
                    color: p.text as Color,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const SizedBox(height: 8),
            Text(reward.title,
                style: TextStyle(color: p.textSec as Color, fontSize: 13)),
            const SizedBox(height: 20),
            // Code box
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (p.primaryLight) as Color,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: (p.primary as Color).withOpacity(.4)),
              ),
              child: Column(
                children: [
                  Text('Il tuo codice',
                      style: TextStyle(
                          color: p.textSec as Color, fontSize: 11)),
                  const SizedBox(height: 6),
                  Text(redeemed.code,
                      style: TextStyle(
                          color: p.primary as Color,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: 2)),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: redeemed.code));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Codice copiato!'),
                          duration: Duration(seconds: 2)));
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.copy,
                            size: 14,
                            color: (p.primary as Color).withOpacity(.6)),
                        const SizedBox(width: 4),
                        Text('Copia codice',
                            style: TextStyle(
                                fontSize: 11,
                                color: (p.primary as Color).withOpacity(.6))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(44)),
            child: Text(context.sL.rewards),
          ),
        ],
      ),
    );
  }
}

// ─── Wallet Tab ───────────────────────────────────────────────────────────────

class _WalletTab extends StatelessWidget {
  const _WalletTab();

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    return Consumer<AppProvider>(builder: (context, ap, _) {
      final redeemed = ap.redeemedRewards;

      if (redeemed.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎁', style: TextStyle(fontSize: 56)),
              const SizedBox(height: 16),
              Text(context.sL.rewardsLocked,
                  style: TextStyle(
                      color: p.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Text(context.sL.rewardsLockedDesc,
                  style: TextStyle(
                      color: p.textMut, fontSize: 13)),
            ],
          ),
        );
      }

      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Summary
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                p.primary.withOpacity(.12),
                p.bg2.withOpacity(.5),
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.primary.withOpacity(.2)),
            ),
            child: Row(
              children: [
                const Text('🎟️', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${redeemed.length} premi riscattati',
                        style: TextStyle(
                            color: p.text,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    Text(
                        '${redeemed.where((r) => !r.isUsed).length} ancora disponibili',
                        style: TextStyle(
                            color: p.textMut,
                            fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          if (redeemed.any((r) => !r.isUsed)) ...[
            _sectionLabel('Disponibili', p),
            const SizedBox(height: 8),
            ...redeemed.where((r) => !r.isUsed).map((r) => _RedeemedCard(reward: r)),
          ],

          if (redeemed.any((r) => r.isUsed)) ...[
            const SizedBox(height: 16),
            _sectionLabel('Utilizzati', p),
            const SizedBox(height: 8),
            ...redeemed.where((r) => r.isUsed).map((r) => _RedeemedCard(reward: r)),
          ],
        ],
      );
    });
  }

  Widget _sectionLabel(String t, dynamic p) => Text(t.toUpperCase(),
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: p.textMut as Color,
          letterSpacing: .5));
}

class _RedeemedCard extends StatelessWidget {
  final RedeemedReward reward;
  const _RedeemedCard({required this.reward});

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    final isUsed = reward.isUsed;
    final date =
        '${reward.redeemedAt.day}/${reward.redeemedAt.month}/${reward.redeemedAt.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUsed ? p.bg2 : p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUsed
              ? p.cardBorder
              : p.primary.withOpacity(.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(reward.rewardEmoji,
                  style: TextStyle(
                      fontSize: 28,
                      color: isUsed ? p.textMut : null)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reward.rewardTitle,
                        style: TextStyle(
                            color: isUsed ? p.textMut : p.text,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            decoration:
                                isUsed ? TextDecoration.lineThrough : null)),
                    Text('Riscattato il $date · ${reward.pointsSpent} pt',
                        style: TextStyle(
                            color: p.textMut,
                            fontSize: 11)),
                  ],
                ),
              ),
              if (isUsed)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: p.bg2,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text('Usato',
                      style: TextStyle(
                          fontSize: 10,
                          color: p.textMut,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          if (!isUsed) ...[
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: p.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: p.primary.withOpacity(.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(reward.code,
                        style: TextStyle(
                            color: p.primary,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            letterSpacing: 1.5)),
                  ),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: reward.code));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                          content: Text('Codice copiato!'),
                          duration: Duration(seconds: 2)));
                    },
                    child: Icon(Icons.copy, size: 16, color: p.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () =>
                  context.read<AppProvider>().markRewardUsed(reward.code),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 14, color: p.textMut),
                  const SizedBox(width: 4),
                  Text('Segna come utilizzato',
                      style: TextStyle(
                          fontSize: 11, color: p.textMut)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
