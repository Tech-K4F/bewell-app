# ISTRUZIONI PRECISE PER CLAUDE CODE — BeWell

Leggi prima CONTEXT.md e BeWell_ProductBrief.md.
Poi esegui questi task nell'ordine esatto. Dopo ogni task: flutter analyze (0 errori) poi dimmi cosa hai fatto.

---

## TASK 1 — HOME SCREEN: nuvoletta Welly come fumetto

FILE: lib/screens/home/home_screen.dart

Il messaggio Welly attualmente è una card rettangolare con emoji 💬.
Trasformalo in un fumetto vero sopra il companion.

STRUTTURA ATTUALE da modificare (righe ~174-206):
```dart
// ── Messaggio Welly ──────────────────────────────────────────────────────────
if (message.isNotEmpty)
  Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: p.primaryLight,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(...),
    ),
    child: Row(
      children: [
        const Text('💬', ...),
        Expanded(child: Text(message, ...)),
      ],
    ),
  ),
```

STRUTTURA NUOVA — sostituisci con questo widget `_WellySpeechBubble`:
```dart
if (message.isNotEmpty)
  _WellySpeechBubble(message: message, p: p, isAmb: isAmb),
```

Aggiungi questo widget in fondo al file (prima di _Divider):
```dart
class _WellySpeechBubble extends StatelessWidget {
  final String message;
  final BwPaletteData p;
  final bool isAmb;
  const _WellySpeechBubble({required this.message, required this.p, required this.isAmb});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: p.primaryLight,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: p.primary.withValues(alpha: 0.2), width: 0.5),
          ),
          child: Text(
            message,
            style: TextStyle(
              fontSize: 14,
              color: p.text,
              height: 1.6,
              fontStyle: isAmb ? FontStyle.italic : FontStyle.normal,
              fontFamily: isAmb ? 'CormorantGaramond' : null,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        // Triangolino del fumetto che punta verso il basso (verso Welly)
        Align(
          alignment: Alignment.center,
          child: CustomPaint(
            size: const Size(16, 8),
            painter: _BubbleTailPainter(color: p.primaryLight, borderColor: p.primary.withValues(alpha: 0.2)),
          ),
        ),
      ],
    );
  }
}

class _BubbleTailPainter extends CustomPainter {
  final Color color;
  final Color borderColor;
  const _BubbleTailPainter({required this.color, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = borderColor);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(_BubbleTailPainter old) => old.color != color;
}
```

NOTA: sposta il fumetto SOPRA il companion nel ListView — quindi metti _WellySpeechBubble PRIMA di CompanionWidget. La struttura verticale diventa:
1. Greeting (header)
2. Speech bubble Welly
3. CompanionWidget (Welly)
4. Divider
5. Water tracker
6. Stats pills
7. Coming next

---

## TASK 2 — HOME SCREEN: card "momento attuale" intelligente

FILE: lib/screens/home/home_screen.dart

Dopo le stats pills (dopo la riga con i 3 StatPill), e PRIMA della sezione "coming next", aggiungi una card che suggerisce l'azione più rilevante per l'ora del giorno.

Aggiungi questo metodo nella classe _HomeScreenState:
```dart
String _getCurrentAction(BwStrings s, ProgressionProvider progression) {
  final hour = DateTime.now().hour;
  final waterDone = _isWaterDoneToday(progression);
  
  if (!waterDone) {
    if (hour < 9) return s.goodMorning; // "Buongiorno, — primo bicchiere?"
    if (hour < 12) return s.waterLow;
    if (hour >= 20) return s.waterDone;
    return s.addGlass;
  }
  
  // Acqua fatta — suggerisci altro in base all'ora
  final active = progression.activeHabits.where((h) => h.id != 'water').toList();
  if (active.isEmpty) return '';
  
  if (hour >= 12 && hour < 14) return s.comingNext; // pausa pranzo
  if (hour >= 14 && hour < 18) return s.comingNext; // pomeriggio
  return '';
}
```

Aggiungi nel ListView, dopo le stats pills e prima di "if (pendingPair != null || nextHabit != null)":
```dart
// ── Card momento attuale ──────────────────────────────────────────────────
const SizedBox(height: 24),
_Divider(p: p),
const SizedBox(height: 20),
_CurrentMomentCard(
  waterCount: _waterCount,
  isWaterDone: isWaterDone,
  onAddWater: _addWater,
  progression: progression,
  p: p,
  isAmb: isAmb,
  s: s,
),
```

Aggiungi il widget:
```dart
class _CurrentMomentCard extends StatelessWidget {
  final int waterCount;
  final bool isWaterDone;
  final VoidCallback onAddWater;
  final ProgressionProvider progression;
  final BwPaletteData p;
  final bool isAmb;
  final BwStrings s;

  const _CurrentMomentCard({
    required this.waterCount,
    required this.isWaterDone,
    required this.onAddWater,
    required this.progression,
    required this.p,
    required this.isAmb,
    required this.s,
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    String title;
    String subtitle;
    IconData icon;
    VoidCallback? action;
    String actionLabel;

    if (!isWaterDone) {
      icon = Icons.water_drop_outlined;
      title = s.waterToday;
      subtitle = '$waterCount / 8 ${s.days}';
      action = onAddWater;
      actionLabel = s.addGlass;
    } else {
      final active = progression.activeHabits.where((h) => h.id != 'water').toList();
      if (active.isEmpty) return const SizedBox.shrink();
      
      icon = Icons.check_circle_outline_rounded;
      title = s.waterDone;
      subtitle = '${active.length} ${s.activeHabits.toLowerCase()}';
      action = null;
      actionLabel = '';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isWaterDone ? p.primaryLight : p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isWaterDone ? p.primary.withValues(alpha: 0.3) : p.cardBorder,
          width: isWaterDone ? 1 : 0.5,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: isWaterDone ? p.primary : p.primaryLight,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: isWaterDone ? Colors.white : p.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: p.textSec)),
              ],
            ),
          ),
          if (action != null && !isWaterDone)
            GestureDetector(
              onTap: action,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: p.btn,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(actionLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.btnText)),
              ),
            ),
        ],
      ),
    );
  }
}
```

---

## TASK 3 — HABITS SCREEN: miglioramento card con immagine hero

FILE: lib/screens/habits/habits_screen.dart

La _HabitCard attuale è corretta ma troppo compatta. Sostituiscila con una versione card-hero con immagine grande.

Sostituisci `_HabitCard` con questa versione:
```dart
class _HabitCard extends StatelessWidget {
  final HabitDefinition habit;
  final HabitState? state;
  final BwPaletteData p;
  final bool isAmb;
  final BwStrings s;
  final VoidCallback? onComplete;
  final VoidCallback? onStartTimer;

  const _HabitCard({
    required this.habit,
    required this.state,
    required this.p,
    required this.isAmb,
    required this.s,
    this.onComplete,
    this.onStartTimer,
  });

  bool get _isWater => habit.id == 'water';

  bool get _isCompletedToday {
    final last = state?.lastCompletedAt;
    if (last == null) return false;
    final now = DateTime.now();
    return last.year == now.year && last.month == now.month && last.day == now.day;
  }

  @override
  Widget build(BuildContext context) {
    final done = _isCompletedToday;
    final days = state?.daysCompleted ?? 0;

    return AnimatedOpacity(
      opacity: done ? 0.75 : 1.0,
      duration: const Duration(milliseconds: 400),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: done ? p.primary.withValues(alpha: 0.4) : p.cardBorder,
            width: done ? 1 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Immagine hero
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                  child: ColorFiltered(
                    colorFilter: done
                        ? const ColorFilter.matrix([
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0.2126, 0.7152, 0.0722, 0, 0,
                            0,      0,      0,      1, 0,
                          ])
                        : const ColorFilter.mode(Colors.transparent, BlendMode.saturation),
                    child: Image.asset(
                      habit.imageAsset,
                      height: 140,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        height: 140,
                        color: p.primaryLight,
                        child: Icon(Icons.spa_outlined, color: p.primary, size: 40),
                      ),
                    ),
                  ),
                ),
                // Overlay completata
                if (done)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        color: p.primary.withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      child: const Center(
                        child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 44),
                      ),
                    ),
                  ),
                // Streak badge
                if (days > 0)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('🔥', style: TextStyle(fontSize: 10)),
                          const SizedBox(width: 3),
                          Text(
                            '$days ${s.days}',
                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Water: read-only badge
                if (_isWater)
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text('💧 home', style: TextStyle(color: Colors.white, fontSize: 10)),
                    ),
                  ),
              ],
            ),

            // Info + action
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.habitName(habit.id),
                          style: TextStyle(
                            fontSize: isAmb ? 17 : 15,
                            fontWeight: isAmb ? FontWeight.w300 : FontWeight.w600,
                            fontFamily: isAmb ? 'CormorantGaramond' : null,
                            color: p.text,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          done ? '✓ ${s.waterDone}' : habit.description,
                          style: TextStyle(fontSize: 11, color: p.textSec),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  if (_isWater)
                    Icon(done ? Icons.water_drop : Icons.water_drop_outlined, color: p.primary, size: 24)
                  else if (onStartTimer != null && !done)
                    GestureDetector(
                      onTap: onStartTimer,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: p.btn,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text('▶ 25 min', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: p.btnText)),
                      ),
                    )
                  else if (onStartTimer != null && done)
                    Icon(Icons.check_circle_rounded, color: p.primary, size: 28)
                  else
                    GestureDetector(
                      onTap: done ? null : onComplete,
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done ? p.primary : Colors.transparent,
                          border: Border.all(color: done ? p.primary : p.textMut, width: 1.5),
                        ),
                        child: done ? const Icon(Icons.check, color: Colors.white, size: 18) : null,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

---

## TASK 4 — GROWTH SCREEN: aggiungere sezione marketplace "I tuoi premi"

FILE: lib/screens/growth/growth_screen.dart

Dopo la sezione badge (_BadgeGrid), aggiungi una sezione "I tuoi premi" che mostra i premi del marketplace.

Prima aggiungi l'import:
```dart
import '../marketplace/marketplace_screen.dart';
```

Poi nel ListView della GrowthScreen, dopo `_BadgeGrid(p: p, progression: progression)`, aggiungi:
```dart
const SizedBox(height: 28),
_SectionLabel(label: s.rewardsHeader, p: p),
const SizedBox(height: 8),
Text(
  s.rewardsHeaderSub,
  style: TextStyle(fontSize: 13, color: p.textSec),
),
const SizedBox(height: 16),
GestureDetector(
  onTap: () => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const MarketplaceScreen()),
  ),
  child: Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: p.card,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: p.cardBorder, width: 0.5),
    ),
    child: Row(
      children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: p.primaryLight,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.card_giftcard_rounded, color: p.primary, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.rewards, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: p.text)),
              const SizedBox(height: 2),
              Text(s.rewardsLockedDesc, style: TextStyle(fontSize: 12, color: p.textSec)),
            ],
          ),
        ),
        Icon(Icons.chevron_right_rounded, color: p.textSec, size: 20),
      ],
    ),
  ),
),
```

Poi aggiungi le chiavi mancanti in BwStrings (lib/l10n/app_localizations.dart):
- `rewardsHeader` — "I tuoi premi" / "Your rewards" / etc.
- `rewardsHeaderSub` — "Raccogli quello che hai seminato" / "Collect what you've sown" / etc.

Aggiungi in tutte e 5 le lingue.

---

## TASK 5 — GROWTH SCREEN: rimuovere AppBar con back button

FILE: lib/screens/growth/growth_screen.dart

La GrowthScreen ha un AppBar con back button che non ha senso perché è una tab della nav, non una schermata pushed.

Rimuovi il `appBar:` dal BwScaffold e aggiungi invece un header inline nel ListView come la home e habits screen:

Sostituisci il BwScaffold con appBar con:
```dart
return BwScaffold(
  body: SafeArea(
    child: ListView(
      padding: EdgeInsets.fromLTRB(20, isAmb ? 72 : 24, 20, 40),
      children: [
        // Header
        Text(
          isAmb ? s.yourJourney.toLowerCase() : s.yourJourney,
          style: TextStyle(
            fontSize: isAmb ? 28 : 22,
            fontWeight: isAmb ? FontWeight.w300 : FontWeight.w700,
            fontFamily: isAmb ? 'CormorantGaramond' : null,
            color: p.text,
            letterSpacing: isAmb ? 1 : 0,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '${progression.totalDaysCompleted} ${s.days}',
          style: TextStyle(fontSize: 13, color: p.textSec),
        ),
        const SizedBox(height: 24),
        // ... resto del contenuto
      ],
    ),
  ),
);
```

---

## TASK 6 — DEBUG PANEL: fix definitivo sblocco e simulazione

FILE: lib/widgets/debug_panel.dart
FILE: lib/providers/progression_provider.dart

PROBLEMA: i pulsanti "+N giorni" e "Sblocca tutto" non aggiornano la UI.

FIX in progression_provider.dart:

Trova il metodo `debugSimulateDays` e assicurati che sia esattamente così:
```dart
Future<void> debugSimulateDays(int days) async {
  _debugDayOffset += days;
  for (final state in _states.values) {
    if (state.status != HabitStatus.locked) {
      state.daysCompleted += days;
      state.lastCompletedAt = DateTime.now();
      _updateHabitStatus(state);
    }
  }
  await _saveStates();
  _generateTodayMessage();
  notifyListeners(); // ← questo triggera il rebuild di HomeShell che usa Consumer3
}
```

Trova `debugUnlockAll` e assicurati che sia esattamente così:
```dart
Future<void> debugUnlockAll() async {
  _debugDayOffset = 30; // appDayNumber diventa 30+ → sblocca Habits e Growth
  for (final habit in HabitLibrary.all) {
    if (!_states.containsKey(habit.id)) {
      _states[habit.id] = HabitState(habitId: habit.id);
    }
    _states[habit.id]!
      ..status = HabitStatus.active
      ..daysCompleted = 10
      ..activatedAt = DateTime.now()
      ..isChoicePending = false;
  }
  await _saveStates();
  // NON chiamare _evaluateUnlocks() — riblocca tutto
  notifyListeners();
}
```

FIX in debug_panel.dart:

Il pulsante "+N giorni" deve chiamare debugSimulateDays E aggiornare la UI locale:
```dart
onTap: () async {
  await context.read<ProgressionProvider>().debugSimulateDays(days);
  if (mounted) setState(() {}); // aggiorna il counter nel panel
},
```

Il pulsante "Sblocca tutto" deve chiamare debugUnlockAll e chiudere il panel:
```dart
onTap: () async {
  await context.read<ProgressionProvider>().debugUnlockAll();
  if (mounted) {
    Navigator.pop(context); // chiude il panel
    // HomeShell si ricostruisce automaticamente via Consumer3
  }
},
```

---

## TASK 7 — VERIFICA FINALE

Dopo tutti i task:

1. `flutter analyze` — deve dare 0 errori e 0 warning su file modificati
2. `flutter build apk --debug`
3. Dimmi cosa hai cambiato file per file

COSE DA NON FARE:
- Non cambiare la struttura di BwStrings senza aggiungere la chiave in tutte e 5 le lingue
- Non usare stringhe hardcoded in italiano
- Non usare IndexedStack in home_shell.dart
- Non chiamare _evaluateUnlocks() dentro debugUnlockAll
- Non aggiungere import non necessari
