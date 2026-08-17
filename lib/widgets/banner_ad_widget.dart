import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Banner AdMob discreto, posizionato come bottomNavigationBar del BwScaffold.
/// Si auto-carica; mostra SizedBox.shrink() finché non è pronto.
class BannerAdWidget extends StatefulWidget {
  const BannerAdWidget({super.key});

  @override
  State<BannerAdWidget> createState() => _BannerAdWidgetState();
}

class _BannerAdWidgetState extends State<BannerAdWidget> {
  BannerAd? _ad;
  bool _loaded = false;

  static const _unitId = kDebugMode
      ? 'ca-app-pub-3940256099942544/6300978111' // Test banner ufficiale Google
      : 'ca-app-pub-5624251597550316/9470713799'; // Produzione Be Well

  @override
  void initState() {
    super.initState();
    _ad = BannerAd(
      adUnitId: _unitId,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) => ad.dispose(),
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _ad == null) return const SizedBox.shrink();
    final p = context.read<ThemeProvider>().paletteData;
    return Container(
      width: double.infinity,
      height: _ad!.size.height.toDouble(),
      decoration: BoxDecoration(
        color: p.bg,
        border: Border(
          top: BorderSide(
            color: p.text.withValues(alpha: 0.06),
            width: 0.5,
          ),
        ),
      ),
      child: AdWidget(ad: _ad!),
    );
  }
}
