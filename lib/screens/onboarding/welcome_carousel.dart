import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/bw_scaffold.dart';
import '../../l10n/app_localizations.dart';

const _teal = Color(0xFF1E9E87);
const _blue = Color(0xFF3A7BD5);
const _amber = Color(0xFFD99820);

/// S-07 · Welcome Carousel
/// 3 slide swipeable, skip sempre visibile.
class WelcomeCarousel extends StatefulWidget {
  const WelcomeCarousel({super.key});

  @override
  State<WelcomeCarousel> createState() => _WelcomeCarouselState();
}

class _WelcomeCarouselState extends State<WelcomeCarousel> {
  final _controller = PageController();
  int _currentPage = 0;

  List<_Slide> _slides(BwStrings s) => [
    _Slide(
      emoji: '🌿',
      title: s.welcomeSlide1Title,
      subtitle: s.welcomeSlide1Sub,
      accentColor: _teal,
    ),
    _Slide(
      emoji: '🔔',
      title: s.welcomeSlide2Title,
      subtitle: s.welcomeSlide2Sub,
      accentColor: _blue,
    ),
    _Slide(
      emoji: '🎁',
      title: s.welcomeSlide3Title,
      subtitle: s.welcomeSlide3Sub,
      accentColor: _amber,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _skip() {
    context.read<OnboardingProvider>().skipAll();
  }

  void _nextOrStart(int slideCount) {
    if (_currentPage < slideCount - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
      );
    } else {
      context.read<OnboardingProvider>().nextFromWelcome();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ThemeProvider>().paletteData;
    final s = context.sL;
    final slides = _slides(s);

    return BwScaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button top right
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: Text(
                  s.welcomeSkip,
                  style: const TextStyle(color: _teal, fontSize: 14),
                ),
              ),
            ),

            // Page view slides
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) =>
                    _SlideWidget(slide: slides[i], isActive: i == _currentPage, p: p),
              ),
            ),

            // Dot indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? slides[_currentPage].accentColor
                          : p.cardBorder,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ),

            // CTA buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () => _nextOrStart(slides.length),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: slides[_currentPage].accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage < slides.length - 1
                            ? s.welcomeNext
                            : s.welcomeStart,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (_currentPage == slides.length - 1) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _skip,
                      child: Text(
                        s.welcomeConfigureLater,
                        style: TextStyle(
                          color: p.textMut,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlideWidget extends StatelessWidget {
  final _Slide slide;
  final bool isActive;
  final BwPaletteData p;

  const _SlideWidget({required this.slide, required this.isActive, required this.p});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 16, 32, 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Icona con alone colorato
          AnimatedScale(
            scale: isActive ? 1.0 : 0.9,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: slide.accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: slide.accentColor.withValues(alpha: 0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: slide.accentColor.withValues(alpha: 0.2),
                    blurRadius: 32,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  slide.emoji,
                  style: const TextStyle(fontSize: 46),
                ),
              ),
            ),
          ),
          const SizedBox(height: 36),
          AnimatedOpacity(
            opacity: isActive ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 250),
            child: Column(
              children: [
                Text(
                  slide.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: p.text,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  slide.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: p.textSec,
                    fontSize: 15,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Slide {
  final String emoji;
  final String title;
  final String subtitle;
  final Color accentColor;

  const _Slide({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });
}
