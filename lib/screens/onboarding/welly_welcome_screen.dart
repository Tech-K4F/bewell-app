import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/theme_provider.dart';
import '../../providers/progression_provider.dart';
import '../../widgets/companion/companion_widget.dart';
import '../../widgets/locale_selector.dart';
import '../../services/notification_service.dart';
import '../../services/analytics_service.dart';

class WellyWelcomeScreen extends StatefulWidget {
  const WellyWelcomeScreen({super.key});

  @override
  State<WellyWelcomeScreen> createState() => _WellyWelcomeScreenState();
}

class _WellyWelcomeScreenState extends State<WellyWelcomeScreen> {
  final PageController _pageCtrl = PageController();
  int _page = 0;
  String _wellyName = 'Welly';
  String _userType = 'worker'; // 'student' | 'worker' — default: worker
  final _nameCtrl = TextEditingController(text: 'Welly');
  bool _firstDrinkDone = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<ProgressionProvider>().init();
    });
  }

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 4) {
      _pageCtrl.nextPage(
        duration: const Duration(milliseconds: 380),
        curve: Curves.easeOutCubic,
      );
      setState(() => _page++);
    }
  }

  Future<void> _finish() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('welly_name', _wellyName);
    await prefs.setString('user_type', _userType);
    await prefs.setBool('welly_welcomed', true);
    AnalyticsService.instance.logOnboardingCompleted(_userType);
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  Future<void> _drinkFirst() async {
    // Registra il primo bicchiere nel contatore giornaliero
    // senza marcare l'abitudine come completata: servono 8 bicchieri.
    // La home screen gestirà il completamento quando il target è raggiunto.
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now();
    final todayStr = '${today.year}-${today.month}-${today.day}';
    await prefs.setString('water_date', todayStr);
    await prefs.setInt('water_count', 1);

    setState(() => _firstDrinkDone = true);
    await Future.delayed(const Duration(milliseconds: 600));
    _next();
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.watch<ThemeProvider>();
    final p = theme.paletteData;

    return Scaffold(
      backgroundColor: p.bg,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Progress dots
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
              child: Row(
                children: List.generate(5, (i) => Expanded(
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    height: 2,
                    decoration: BoxDecoration(
                      color: i <= _page ? p.primary : p.bg2,
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                )),
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _Page1(p: p, onNext: _next),
                  _Page2(
                    p: p,
                    nameCtrl: _nameCtrl,
                    userType: _userType,
                    onUserTypeChanged: (t) => setState(() => _userType = t),
                    onNext: () {
                      FocusScope.of(context).unfocus();
                      final name = _nameCtrl.text.trim().isEmpty
                          ? 'Welly'
                          : _nameCtrl.text.trim();
                      setState(() => _wellyName = name);
                      AnalyticsService.instance.logWellyNamed(name);
                      _next();
                    },
                  ),
                  _Page3(
                    p: p,
                    wellyName: _wellyName,
                    done: _firstDrinkDone,
                    onDrink: _drinkFirst,
                  ),
                  _Page4(p: p, onNext: _next),
                  _Page5(p: p, onFinish: _finish),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pagina 1: Presentazione Be Well ──────────────────────────────────────────
class _Page1 extends StatelessWidget {
  final BwPaletteData p;
  final VoidCallback onNext;
  const _Page1({required this.p, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final s = context.sL;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
      child: Column(
        children: [
          // Welly grande
          CompanionWidget(size: 180, mood: WellyMood.calm),
          const SizedBox(height: 32),

          Text(
            s.wellyHi,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: p.text,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            s.wellyIntro,
            style: TextStyle(
              fontSize: 16,
              color: p.textSec,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          const LocaleSelector(),
          const SizedBox(height: 20),
          _WellyButton(
            label: s.letsGo,
            p: p,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

// ── Pagina 2: Nome Welly + Tipo utente ───────────────────────────────────────
class _Page2 extends StatelessWidget {
  final BwPaletteData p;
  final TextEditingController nameCtrl;
  final String userType;
  final ValueChanged<String> onUserTypeChanged;
  final VoidCallback onNext;
  const _Page2({
    required this.p,
    required this.nameCtrl,
    required this.userType,
    required this.onUserTypeChanged,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.sL;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(28, 32, 28, bottom + 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CompanionWidget(size: 140, mood: WellyMood.calm),
          const SizedBox(height: 32),

          Text(
            s.wellyNameQuestion,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: p.text,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            s.wellyNameSub,
            style: TextStyle(
              fontSize: 15,
              color: p.textSec,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 32),

          // Campo nome
          Container(
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.cardBorder, width: 0.5),
            ),
            child: TextField(
              controller: nameCtrl,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: p.text,
              ),
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                    vertical: 18, horizontal: 20),
                hintText: 'Welly',
                hintStyle: TextStyle(color: p.textMut),
              ),
              onSubmitted: (_) => onNext(),
            ),
          ),

          const SizedBox(height: 32),

          // ── Separatore tipo utente ──────────────────────────────────────
          Row(
            children: [
              Expanded(child: Divider(color: p.cardBorder, thickness: 0.5)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  s.onboardingUserTypeTitle,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: p.textSec,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Expanded(child: Divider(color: p.cardBorder, thickness: 0.5)),
            ],
          ),

          const SizedBox(height: 16),

          // ── Scelta student / worker ─────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _UserTypeCard(
                  emoji: '🎓',
                  label: s.onboardingStudent,
                  selected: userType == 'student',
                  p: p,
                  onTap: () => onUserTypeChanged('student'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _UserTypeCard(
                  emoji: '💼',
                  label: s.onboardingWorker,
                  selected: userType == 'worker',
                  p: p,
                  onTap: () => onUserTypeChanged('worker'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          _WellyButton(
            label: s.perfect,
            p: p,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

// ── Card tipo utente ──────────────────────────────────────────────────────────
class _UserTypeCard extends StatelessWidget {
  final String emoji;
  final String label;
  final bool selected;
  final BwPaletteData p;
  final VoidCallback onTap;

  const _UserTypeCard({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.p,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: selected ? p.primaryLight : p.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? p.primary : p.cardBorder,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: selected ? p.primary : p.text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Pagina 3: Prima abitudine ─────────────────────────────────────────────────
class _Page3 extends StatelessWidget {
  final BwPaletteData p;
  final String wellyName;
  final bool done;
  final VoidCallback onDrink;
  const _Page3({
    required this.p,
    required this.wellyName,
    required this.done,
    required this.onDrink,
  });

  @override
  Widget build(BuildContext context) {
    final s = context.sL;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
      child: Column(
        children: [
          CompanionWidget(
            size: 130,
            mood: done ? WellyMood.radiant : WellyMood.returning,
          ),
          const SizedBox(height: 28),

          Text(
            s.firstHabitTitle,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: p.text,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            s.firstHabitBody1,
            style: TextStyle(
              fontSize: 15,
              color: p.textSec,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            s.firstHabitBody2,
            style: TextStyle(
              fontSize: 15,
              color: p.textSec,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          if (!done)
            _WellyButton(
              label: s.drinkFirstGlass,
              p: p,
              onTap: onDrink,
              icon: '💧',
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle_rounded,
                    color: p.primary, size: 22),
                const SizedBox(width: 8),
                Text(
                  '💧 1/8',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: p.primary,
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

// ── Pagina 4: Premi preview ───────────────────────────────────────────────────
class _Page4 extends StatelessWidget {
  final BwPaletteData p;
  final VoidCallback onNext;
  const _Page4({required this.p, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final s = context.sL;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
      child: Column(
        children: [
          CompanionWidget(size: 130, mood: WellyMood.radiant),
          const SizedBox(height: 28),

          Text(
            s.rewardTitle,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: p.text,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            s.rewardBody,
            style: TextStyle(
              fontSize: 15,
              color: p.textSec,
              height: 1.6,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),

          // Preview premi sfocata
          _RewardsPreview(p: p),

          const Spacer(),

          _WellyButton(
            label: s.letsGo,
            p: p,
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

// ── Pagina 5: Permesso notifiche ──────────────────────────────────────────────
class _Page5 extends StatelessWidget {
  final BwPaletteData p;
  final VoidCallback onFinish;
  const _Page5({required this.p, required this.onFinish});

  @override
  Widget build(BuildContext context) {
    final s = context.sL;
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 40),
      child: Column(
        children: [
          CompanionWidget(size: 150, mood: WellyMood.welcoming),
          const SizedBox(height: 28),

          Text(
            s.notifPermTitle,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: p.text,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            s.notifPermBody,
            style: TextStyle(
              fontSize: 15,
              color: p.textSec,
              height: 1.7,
            ),
            textAlign: TextAlign.center,
          ),

          const Spacer(),

          _WellyButton(
            label: s.notifPermAllow,
            p: p,
            onTap: () async {
              await NotificationService.instance.requestPermission();
              onFinish();
            },
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onFinish,
            child: Text(
              s.notifPermSkip,
              style: TextStyle(
                fontSize: 14,
                color: p.textMut,
                decoration: TextDecoration.underline,
                decorationColor: p.textMut,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Preview Premi ─────────────────────────────────────────────────────────────
class _RewardsPreview extends StatelessWidget {
  final BwPaletteData p;
  const _RewardsPreview({required this.p});

  @override
  Widget build(BuildContext context) {
    final s = context.sL;
    final items = [
      ('🎟️', 'Buono sconto', '10% su partner selezionati'),
      ('☕', 'Voucher caffè', 'Bevanda gratuita'),
      ('✨', 'Premium', 'Funzioni avanzate'),
      ('🎁', 'Sorprese', 'E molto altro...'),
    ];

    return Stack(
      children: [
        // Cards sfocate
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 2.2,
          children: items.map((item) => Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.cardBorder, width: 0.5),
            ),
            child: Row(
              children: [
                Text(item.$1, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(item.$2,
                          style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: p.text)),
                      Text(item.$3,
                          style: TextStyle(
                              fontSize: 10, color: p.textSec)),
                    ],
                  ),
                ),
              ],
            ),
          )).toList(),
        ),

        // Overlay sfocatura + lock
        Positioned.fill(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              color: p.bg.withValues(alpha: 0.55),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: p.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.lock_outline,
                          color: Colors.white, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        s.rewardLocked,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Bottone Welly ─────────────────────────────────────────────────────────────
class _WellyButton extends StatelessWidget {
  final String label;
  final BwPaletteData p;
  final VoidCallback onTap;
  final String? icon;

  const _WellyButton({
    required this.label,
    required this.p,
    required this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          color: p.btn,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Text(icon!, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: p.btnText,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}






