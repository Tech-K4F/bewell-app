import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/bw_scaffold.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/bw_scaffold.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
    return BwScaffold(
      appBar: AppBar(
        title: Text('Marketplace'),
        bottom: TabBar(
          controller: _tab,
          indicatorColor: context.read<ThemeProvider>().paletteData.primary,
          labelColor: context.read<ThemeProvider>().paletteData.primary,
          unselectedLabelColor: context.read<ThemeProvider>().paletteData.textSec,
          tabs: [
            Tab(text: 'Catalogo'),
            Tab(text: 'I miei premi'),
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
    // Loading state
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: context.read<ThemeProvider>().paletteData.primary),
            SizedBox(height: 16),
            Text('Caricamento premi...',
                style: TextStyle(color: context.read<ThemeProvider>().paletteData.textSec, fontSize: 13)),
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
            Text('⚠️', style: TextStyle(fontSize: 40)),
            SizedBox(height: 12),
            Text('Impossibile caricare il catalogo',
                style: TextStyle(color: Colors.white.withOpacity(.6), fontSize: 14)),
            SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadCatalog,
              child: Text('Riprova'),
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

    return Consumer<AppProvider>(builder: (context, p, _) {
      final userPoints = p.user?.points ?? 0;

      return Column(
        children: [
          // Points banner
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  context.read<ThemeProvider>().paletteData.bg.withOpacity(.18),
                  context.read<ThemeProvider>().paletteData.bg.withOpacity(.06),
                ]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.read<ThemeProvider>().paletteData.bg.withOpacity(.3)),
              ),
              child: Row(
                children: [
                  Text('⭐', style: TextStyle(fontSize: 24)),
                  SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$userPoints punti disponibili',
                            style: TextStyle(
                                color: context.read<ThemeProvider>().paletteData.bg,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                        Text('Completa attività per guadagnarne altri',
                            style: TextStyle(
                                color: Colors.white.withOpacity(.4),
                                fontSize: 11)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 10),

          // Search
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              onChanged: widget.onSearchChanged,
              style: TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Cerca premi o brand...',
                prefixIcon: Icon(Icons.search, color: context.read<ThemeProvider>().paletteData.bg),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          SizedBox(height: 10),

          // Category chips
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: rewardCategories.length,
              itemBuilder: (_, i) {
                final cat = rewardCategories[i];
                final sel = cat == widget.selectedCategory;
                return GestureDetector(
                  onTap: () => widget.onCategoryChanged(cat),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: EdgeInsets.only(right: 8),
                    padding: EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: sel
                          ? context.read<ThemeProvider>().paletteData.primary
                          : Colors.white.withOpacity(.07),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Center(
                      child: Text(cat,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: sel
                                  ? Colors.white
                                  : Colors.white.withOpacity(.45))),
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(height: 10),

          // Grid
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('🔍', style: TextStyle(fontSize: 40)),
                        SizedBox(height: 10),
                        Text('Nessun premio trovato',
                            style: TextStyle(
                                color: Colors.white.withOpacity(.4),
                                fontSize: 14)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadCatalog,
                    color: context.read<ThemeProvider>().paletteData.primary,
                    child: GridView.builder(
                      padding: EdgeInsets.fromLTRB(16, 0, 16, 40),
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
                        onTap: () => _showDetail(context, filtered[i], p),
                      ),
                    ),
                  ),
          ),
        ],
      );
    });
  }

  void _showDetail(BuildContext context, RewardItem reward, AppProvider p) {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.read<ThemeProvider>().paletteData.bg,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => ChangeNotifierProvider.value(
        value: p,
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
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: context.read<ThemeProvider>().paletteData.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _canAfford
                ? context.read<ThemeProvider>().paletteData.bg
                : Colors.white.withOpacity(.05),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji area
            Container(
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(_canAfford ? .06 : .03),
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Text(reward.emoji,
                        style: TextStyle(
                            fontSize: 42,
                            color: _canAfford
                                ? null
                                : Colors.white.withOpacity(.3))),
                  ),
                  if (reward.originalValue != null)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: context.read<ThemeProvider>().paletteData.primaryLight,
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(reward.originalValue!,
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                                color: context.read<ThemeProvider>().paletteData.primary)),
                      ),
                    ),
                  if (!_canAfford)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.08),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text('🔒',
                            style: TextStyle(fontSize: 10)),
                      ),
                    ),
                ],
              ),
            ),

            // Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reward.brand,
                        style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(.4))),
                    SizedBox(height: 2),
                    Text(reward.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _canAfford
                                ? Colors.white
                                : Colors.white.withOpacity(.4))),
                    const Spacer(),
                    Row(
                      children: [
                        Text('⭐', style: TextStyle(fontSize: 11)),
                        SizedBox(width: 3),
                        Text('${reward.pointsCost}',
                            style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _canAfford
                                    ? context.read<ThemeProvider>().paletteData.bg
                                    : Colors.white.withOpacity(.3))),
                        SizedBox(width: 3),
                        Text('pt',
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.white.withOpacity(.3))),
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
    return Consumer<AppProvider>(builder: (context, p, _) {
      final userPoints = p.user?.points ?? 0;
      final canAfford = userPoints >= reward.pointsCost;
      final pointsAfter = userPoints - reward.pointsCost;

      return Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36, height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20),

                // Header
                Row(
                  children: [
                    Container(
                      width: 72, height: 72,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(.06),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                          child: Text(reward.emoji,
                              style: TextStyle(fontSize: 38))),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(reward.brand,
                              style: TextStyle(
                                  color: Colors.white.withOpacity(.4),
                                  fontSize: 12)),
                          Text(reward.title,
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(height: 4),
                          _typePill(context, reward.type),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),

                Text(reward.description,
                    style: TextStyle(
                        color: Colors.white.withOpacity(.6),
                        fontSize: 14,
                        height: 1.5)),
                SizedBox(height: 20),

                // Cost breakdown
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: context.read<ThemeProvider>().paletteData.bg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: context.read<ThemeProvider>().paletteData.bg),
                  ),
                  child: Column(
                    children: [
                      _costRow('I tuoi punti', '$userPoints ⭐', Colors.white),
                      SizedBox(height: 8),
                      _costRow('Costo premio', '- ${reward.pointsCost} ⭐',
                          context.read<ThemeProvider>().paletteData.bg),
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Divider(color: context.read<ThemeProvider>().paletteData.bg, height: 1),
                      ),
                      _costRow('Punti rimanenti', '$pointsAfter ⭐',
                          canAfford ? context.read<ThemeProvider>().paletteData.primary : context.read<ThemeProvider>().paletteData.bg,
                          bold: true),
                    ],
                  ),
                ),

                if (!canAfford) ...[
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: context.read<ThemeProvider>().paletteData.bg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: context.read<ThemeProvider>().paletteData.bg.withOpacity(.3)),
                    ),
                    child: Row(
                      children: [
                        Text('⚠️', style: TextStyle(fontSize: 16)),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Ti mancano ${reward.pointsCost - userPoints} punti. Completa altre attività!',
                            style: TextStyle(
                                color: context.read<ThemeProvider>().paletteData.bg,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                SizedBox(height: 24),

                ElevatedButton(
                  onPressed:
                      canAfford ? () => _confirmRedeem(context, p) : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54),
                    backgroundColor: canAfford
                        ? context.read<ThemeProvider>().paletteData.primary
                        : Colors.white.withOpacity(.1),
                    disabledForegroundColor: Colors.white.withOpacity(.3),
                  ),
                  child: Text(
                    canAfford
                        ? 'Riscatta per ${reward.pointsCost} pt ⭐'
                        : 'Punti insufficienti',
                    style: TextStyle(
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

  Widget _typePill(BuildContext context, String type) {
    final labels = {
      'voucher': ('🎟️', 'Voucher', context.read<ThemeProvider>().paletteData.bg),
      'discount': ('🏷️', 'Sconto', context.read<ThemeProvider>().paletteData.bg),
      'experience': ('✨', 'Esperienza', context.read<ThemeProvider>().paletteData.bg),
      'digital': ('💻', 'Digitale', context.read<ThemeProvider>().paletteData.primary),
    };
    final l = labels[type] ?? ('🎁', type, context.read<ThemeProvider>().paletteData.primary);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: l.$3.withOpacity(.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text('${l.$1} ${l.$2}',
          style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w600, color: l.$3)),
    );
  }

  Widget _costRow(String label, String value, Color valueColor,
      {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(.5), fontSize: 13)),
        Text(value,
            style: TextStyle(
                color: valueColor,
                fontSize: 13,
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500)),
      ],
    );
  }

  void _confirmRedeem(BuildContext context, AppProvider p) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: context.read<ThemeProvider>().paletteData.bg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Riscatta ${reward.emoji} ${reward.title}?',
            style: TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
        content: Text(
          'Verranno scalati ${reward.pointsCost} punti dal tuo saldo.\nRiceverai un codice da utilizzare subito.',
          style:
              TextStyle(color: Colors.white.withOpacity(.5), fontSize: 13),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Annulla',
                style: TextStyle(color: Colors.white.withOpacity(.4))),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              Navigator.pop(context);
              final ok = await p.redeemReward(reward);
              if (ok && context.mounted) _showSuccessDialog(context, p);
            },
            child: Text('Conferma'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(BuildContext context, AppProvider p) {
    final redeemed = p.redeemedRewards.first;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: context.read<ThemeProvider>().paletteData.bg,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🎉', style: TextStyle(fontSize: 56)),
            SizedBox(height: 12),
            Text('Premio riscattato!',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            SizedBox(height: 8),
            Text(reward.title,
                style: TextStyle(
                    color: Colors.white.withOpacity(.5), fontSize: 13)),
            SizedBox(height: 20),
            // Code box
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.read<ThemeProvider>().paletteData.primaryLight,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.read<ThemeProvider>().paletteData.primary.withOpacity(.4)),
              ),
              child: Column(
                children: [
                  Text('Il tuo codice',
                      style: TextStyle(
                          color: Colors.white.withOpacity(.5), fontSize: 11)),
                  SizedBox(height: 6),
                  Text(redeemed.code,
                      style: TextStyle(
                          color: context.read<ThemeProvider>().paletteData.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: 2)),
                  SizedBox(height: 8),
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
                            color: context.read<ThemeProvider>().paletteData.primary.withOpacity(.6)),
                        SizedBox(width: 4),
                        Text('Copia codice',
                            style: TextStyle(
                                fontSize: 11,
                                color: context.read<ThemeProvider>().paletteData.primary.withOpacity(.6))),
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
            child: Text('Vai ai miei premi'),
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
    return Consumer<AppProvider>(builder: (context, p, _) {
      final redeemed = p.redeemedRewards;

      if (redeemed.isEmpty) {
        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('🎁', style: TextStyle(fontSize: 56)),
              SizedBox(height: 16),
              Text('Nessun premio ancora',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600)),
              SizedBox(height: 8),
              Text('Riscatta i tuoi punti nel Catalogo',
                  style: TextStyle(
                      color: Colors.white.withOpacity(.4), fontSize: 13)),
            ],
          ),
        );
      }

      return ListView(
        padding: EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          // Summary
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                context.read<ThemeProvider>().paletteData.primary.withOpacity(.12),
                context.read<ThemeProvider>().paletteData.bg.withOpacity(.06),
              ]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: context.read<ThemeProvider>().paletteData.primary.withOpacity(.2)),
            ),
            child: Row(
              children: [
                Text('🎟️', style: TextStyle(fontSize: 28)),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${redeemed.length} premi riscattati',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
                    Text(
                        '${redeemed.where((r) => !r.isUsed).length} ancora disponibili',
                        style: TextStyle(
                            color: Colors.white.withOpacity(.4),
                            fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          if (redeemed.any((r) => !r.isUsed)) ...[
            _sectionLabel('Disponibili'),
            SizedBox(height: 8),
            ...redeemed.where((r) => !r.isUsed).map((r) => _RedeemedCard(reward: r)),
          ],

          if (redeemed.any((r) => r.isUsed)) ...[
            SizedBox(height: 16),
            _sectionLabel('Utilizzati'),
            SizedBox(height: 8),
            ...redeemed.where((r) => r.isUsed).map((r) => _RedeemedCard(reward: r)),
          ],
        ],
      );
    });
  }

  Widget _sectionLabel(String t) => Text(t.toUpperCase(),
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(.3),
          letterSpacing: .5));
}

class _RedeemedCard extends StatelessWidget {
  final RedeemedReward reward;
  const _RedeemedCard({required this.reward});

  @override
  Widget build(BuildContext context) {
    final isUsed = reward.isUsed;
    final date =
        '${reward.redeemedAt.day}/${reward.redeemedAt.month}/${reward.redeemedAt.year}';

    return Container(
      margin: EdgeInsets.only(bottom: 10),
      padding: EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isUsed ? Colors.white.withOpacity(.03) : context.read<ThemeProvider>().paletteData.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isUsed
              ? Colors.white.withOpacity(.06)
              : context.read<ThemeProvider>().paletteData.primary.withOpacity(.25),
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
                      color: isUsed ? Colors.white.withOpacity(.3) : null)),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(reward.rewardTitle,
                        style: TextStyle(
                            color: isUsed
                                ? Colors.white.withOpacity(.35)
                                : Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            decoration:
                                isUsed ? TextDecoration.lineThrough : null)),
                    Text('Riscattato il $date · ${reward.pointsSpent} pt',
                        style: TextStyle(
                            color: Colors.white.withOpacity(.3),
                            fontSize: 11)),
                  ],
                ),
              ),
              if (isUsed)
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(.07),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text('Usato',
                      style: TextStyle(
                          fontSize: 10,
                          color: Colors.white54,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          if (!isUsed) ...[
            SizedBox(height: 10),
            Container(
              padding:
                  EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: context.read<ThemeProvider>().paletteData.primaryLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: context.read<ThemeProvider>().paletteData.primary.withOpacity(.3)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(reward.code,
                        style: TextStyle(
                            color: context.read<ThemeProvider>().paletteData.primary,
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
                    child: Icon(Icons.copy, size: 16, color: context.read<ThemeProvider>().paletteData.primary),
                  ),
                ],
              ),
            ),
            SizedBox(height: 8),
            GestureDetector(
              onTap: () =>
                  context.read<AppProvider>().markRewardUsed(reward.code),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      size: 14, color: Colors.white.withOpacity(.3)),
                  SizedBox(width: 4),
                  Text('Segna come utilizzato',
                      style: TextStyle(
                          fontSize: 11, color: Colors.white.withOpacity(.3))),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}






