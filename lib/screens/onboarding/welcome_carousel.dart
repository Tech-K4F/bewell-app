import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/onboarding_provider.dart';

const _teal = Color(0xFF1E9E87);
const _blue = Color(0xFF3A7BD5);
const _amber = Color(0xFFD99820);
const _amberLight = Color(0x1FD99820);

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

  static const _slides = [
    _Slide(
      emoji: '🌿',
      title: 'Il tuo piano\ndi benessere personale',
      subtitle:
          'Be Well costruisce un piano su misura per te, basato sulle tue abitudini e obiettivi.',
      accentColor: _teal,
    ),
    _Slide(
      emoji: '🔔',
      title: 'Reminder che\nconosco il tuo calendario',
      subtitle:
          'I promemoria si adattano ai tuoi meeting e orari, così non ti interrompono mai nel momento sbagliato.',
      accentColor: _blue,
    ),
    _Slide(
      emoji: '🎁',
      title: 'Trasforma le abitudini\nin premi reali',
      subtitle:
          'Guadagna punti completando attività e riscattali per sconti, voucher e molto altro.',
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

  void _nextOrStart() {
    if (_currentPage < _slides.length - 1) {
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
    return Scaffold(
      backgroundColor: const Color(0xFF0B1929),
      body: SafeArea(
        child: Column(
          children: [
            // Skip button top right
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _skip,
                child: const Text(
                  'Salta',
                  style: TextStyle(color: _teal, fontSize: 14),
                ),
              ),
            ),

            // Page view slides
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (context, i) =>
                    _SlideWidget(slide: _slides[i], isActive: i == _currentPage),
              ),
            ),

            // Dot indicators
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _slides.length,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: i == _currentPage ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: i == _currentPage
                          ? _slides[_currentPage].accentColor
                          : Colors.white.withOpacity(0.15),
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
                      onPressed: _nextOrStart,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _slides[_currentPage].accentColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        _currentPage < _slides.length - 1
                            ? 'Avanti →'
                            : 'Inizia la configurazione →',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  if (_currentPage == _slides.length - 1) ...[
                    const SizedBox(height: 10),
                    TextButton(
                      onPressed: _skip,
                      child: Text(
                        'Configura dopo',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
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

  const _SlideWidget({required this.slide, required this.isActive});

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
                color: slide.accentColor.withOpacity(0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: slide.accentColor.withOpacity(0.25),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: slide.accentColor.withOpacity(0.2),
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
                  style: const TextStyle(
                    color: Colors.white,
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
                    color: Colors.white.withOpacity(0.5),
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
