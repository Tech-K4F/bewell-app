import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _page = 0;
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  String _userType = 'worker';
  int _stressLevel = 3;
  String _primaryGoal = 'stress';

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      setState(() => _page++);
      _pageCtrl.nextPage(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeInOut);
    } else {
      _finish();
    }
  }

  Future<void> _finish() async {
    final profile = UserProfile(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: _nameCtrl.text.trim().isEmpty ? 'Utente' : _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      userType: _userType,
      stressLevel: _stressLevel,
      primaryGoal: _primaryGoal,
    );
    await context.read<AppProvider>().completeOnboarding(profile);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BwColors.darkPanel,
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    height: 3,
                    decoration: BoxDecoration(
                      color: i <= _page
                          ? BwColors.teal
                          : Colors.white.withOpacity(.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [_step1(), _step2(), _step3()],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: ElevatedButton(
                onPressed: _next,
                style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(54)),
                child: Text(
                  _page < 2 ? 'Avanti →' : 'Inizia 🌿',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Ciao! 👋',
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text('Parliamo un po\' di te',
              style: TextStyle(
                  fontSize: 16, color: Colors.white.withOpacity(.5))),
          const SizedBox(height: 32),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              labelText: 'Il tuo nome',
              prefixIcon: Icon(Icons.person_outline, color: BwColors.teal),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _emailCtrl,
            style: const TextStyle(color: Colors.white),
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email (opzionale)',
              prefixIcon: Icon(Icons.email_outlined, color: BwColors.teal),
            ),
          ),
          const SizedBox(height: 28),
          Text('Sei principalmente...',
              style: TextStyle(
                  color: Colors.white.withOpacity(.8),
                  fontSize: 14,
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: [
              _typeCard('worker', '💼', 'Lavoratore'),
              const SizedBox(width: 8),
              _typeCard('student', '📚', 'Studente'),
              const SizedBox(width: 8),
              _typeCard('both', '🎯', 'Entrambi'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeCard(String type, String emoji, String label) {
    final sel = _userType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _userType = type),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: sel ? BwColors.tealLight : Colors.white.withOpacity(.04),
            border: Border.all(
                color: sel ? BwColors.teal : Colors.white.withOpacity(.1)),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 22)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: sel
                          ? BwColors.teal
                          : Colors.white.withOpacity(.5))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _step2() {
    final emojis = ['😌', '😊', '😐', '😓', '😰'];
    final labels = [
      'Molto tranquillo',
      'Abbastanza calmo',
      'Normale',
      'Un po\' stressato',
      'Molto stressato',
    ];
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Come ti senti?',
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text('Livello di stress attuale',
              style: TextStyle(
                  fontSize: 16, color: Colors.white.withOpacity(.5))),
          const SizedBox(height: 56),
          Center(
            child: Text(emojis[_stressLevel - 1],
                style: const TextStyle(fontSize: 80)),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(labels[_stressLevel - 1],
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 32),
          Slider(
            value: _stressLevel.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            onChanged: (v) => setState(() => _stressLevel = v.round()),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Tranquillo',
                    style: TextStyle(
                        fontSize: 11, color: Colors.white.withOpacity(.3))),
                Text('Stressato',
                    style: TextStyle(
                        fontSize: 11, color: Colors.white.withOpacity(.3))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _step3() {
    final goals = [
      ('stress', '🧘', 'Ridurre lo stress', 'Respirazione e relax'),
      ('focus', '⏱', 'Migliorare il focus', 'Timer e sessioni concentrate'),
      ('health', '💧', 'Migliorare la salute', 'Idratazione, postura, occhi'),
      ('sleep', '😴', 'Dormire meglio', 'Routine serale e recupero'),
    ];
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          const Text('Il tuo obiettivo 🎯',
              style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                  color: Colors.white)),
          const SizedBox(height: 8),
          Text('Cosa vuoi migliorare prima?',
              style: TextStyle(
                  fontSize: 16, color: Colors.white.withOpacity(.5))),
          const SizedBox(height: 28),
          ...goals.map((g) {
            final sel = _primaryGoal == g.$1;
            return GestureDetector(
              onTap: () => setState(() => _primaryGoal = g.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: sel
                      ? BwColors.tealLight
                      : Colors.white.withOpacity(.03),
                  border: Border.all(
                    color: sel ? BwColors.teal : Colors.white.withOpacity(.08),
                    width: sel ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Text(g.$2, style: const TextStyle(fontSize: 28)),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(g.$3,
                              style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: sel ? BwColors.teal : Colors.white)),
                          Text(g.$4,
                              style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.white.withOpacity(.4))),
                        ],
                      ),
                    ),
                    if (sel)
                      const Icon(Icons.check_circle,
                          color: BwColors.teal, size: 22),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
