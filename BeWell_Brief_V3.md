# BeWell — Brief V3: Welly Evolution + Habits/Growth Redesign
# Da leggere DOPO CONTEXT.md, BeWell_ProductBrief.md e BeWell_Brief_V2.md
# Questo documento aggiunge le specifiche mancanti e sostituisce le sezioni corrispondenti

---

## IMPORTANTE — ORDINE DI LETTURA
1. CONTEXT.md — architettura tecnica e bug aperti
2. BeWell_ProductBrief.md — visione prodotto e testi Welly
3. BeWell_Brief_V2.md — schedulazione scientifica, tracker acqua, onboarding
4. Questo documento (V3) — evoluzione Welly, redesign Abitudini/Crescita

---

## 1. SISTEMA DI EVOLUZIONE WELLY — SPECIFICA COMPLETA

### Fondamento scientifico
Il "Tamagotchi Effect" (Frude, 2015) dimostra che il cervello attiva circuiti neurali
di caregiving reali in risposta a companion digitali che mostrano stati emotivi e
rispondono alle azioni dell'utente. Finch (2.34M download in 90 giorni) applica
questo principio al self-care con risultati misurabili.

La differenza critica di BeWell rispetto a Finch:
- Finch: "il tuo uccellino ha bisogno di te" → rischio di colpa e obbligo
- BeWell: "Welly ti accompagna e risplende con te" → senso di compagnia, mai dipendenza

Welly non ha mai stati negativi. Non soffre, non è triste, non muore.
Ha stati di attesa calma, presenza, gioia — mai colpa, mai rimprovero.

### Le 3 dimensioni di evoluzione (indipendenti)

#### DIMENSIONE 1 — Aspetto fisico (già implementata)
Legata alla fase globale di progressione (1-5).
Assets già presenti: phase1_seed.png → phase5_radiant.png
Cambia lentamente — riflette chi sei diventato nel lungo periodo.

#### DIMENSIONE 2 — Stato emotivo (da implementare)
Cambia in tempo reale in base alle azioni del giorno corrente.
Implementare tramite enum WellyMood già parzialmente esistente.

Stati da implementare (mappati su video/animazioni esistenti):

```dart
enum WellyMood {
  calm,       // mattino, nessuna azione ancora — video: 'sit' o 'breathe'
  present,    // acqua iniziata (1-3 bicchieri) — video: 'look'
  engaged,    // acqua a metà (4-6 bicchieri) — video: 'sit2'
  radiant,    // giornata completata — video: 'happy'
  welcoming,  // primo accesso del giorno — video: 'hug'
  wondering,  // sera senza azioni (dopo le 20) — video: 'look' con loop lento
  returning,  // rientro dopo 2+ giorni — video: 'encourage'
  resting,    // notte (dopo le 22) — video: 'sleep'
  drinking,   // animazione specifica quando si segna un bicchiere — video: 'drink'
  breathing,  // durante sessione respirazione — video: 'meditate'
}
```

Logica in home_screen.dart — metodo _getCurrentMood():
```dart
WellyMood _getCurrentMood(int waterCount, bool allHabitsDone, int hour) {
  if (allHabitsDone) return WellyMood.radiant;
  if (hour >= 22) return WellyMood.resting;
  if (hour >= 20 && waterCount == 0) return WellyMood.wondering;
  if (waterCount >= 4) return WellyMood.engaged;
  if (waterCount >= 1) return WellyMood.present;
  if (hour < 10) return WellyMood.welcoming;
  return WellyMood.calm;
}
```

Il mood si passa a CompanionWidget che seleziona il video corretto.
CompanionWidget già gestisce la selezione video — estendere il mapping.

#### DIMENSIONE 3 — Ambiente (da implementare)
Il mondo intorno a Welly cambia con la fase globale.
NON è Welly che cresce come una pianta — è l'ambiente che fiorisce con lui.

Implementare come parametri in BwScaffold e HorizonPainter:

```dart
// Aggiungere in BwPaletteData o ThemeProvider
double get ambientGlow {
  // Basato su progression.currentPhase (1-5)
  // Fase 1: 0.0 — Fase 5: 1.0
}
```

In HorizonPainter, aggiungere variazione basata sulla fase:
- Fase 1 (Seme): orizzonte base, colori del tema corrente
- Fase 2 (Germoglio): sottile luce calda sull'orizzonte (+5% luminosità)
- Fase 3 (Giovane): orizzonte più ricco, sfumature leggermente più calde
- Fase 4 (Maturo): piccoli dettagli geometrici nell'orizzonte (punti luminosi)
- Fase 5 (Fiorente): orizzonte trasformato — Welly e ambiente radiosi insieme

Nota implementativa: modificare solo l'alpha e il colore dell'orizzonte in
HorizonPainter — non aggiungere assets nuovi. Usare interpolazione lineare
tra i colori del tema attuale e colori più caldi (verso primaryLight).

### Regola fondamentale
Welly non è mai in uno stato negativo visibile.
La sua "preoccupazione" più intensa è una espressione curiosa e interrogativa
(video 'look' con loop lento) — mai tristezza, mai rimprovero, mai sofferenza.

Quando l'utente torna dopo giorni di assenza:
- Welly usa animazione 'encourage' o 'hug'
- Il messaggio coach è caldo (vedi BeWell_ProductBrief.md sezione rientro)
- L'ambiente NON retrocede alla fase precedente — il progresso rimane

---

## 2. SCHERMATA ABITUDINI — REDESIGN DEFINITIVO

### Principio fondamentale (da ricerca psicologica)
Abitudini risponde a UNA domanda: "cosa faccio adesso?"
È modalità d'azione (implementation mindset) — tutto è cliccabile, tutto è presente.
NULLA in questa schermata guarda al passato o al lungo termine.

### Struttura definitiva

```
[Header dinamico per ora del giorno]
[Card "Adesso" — prominente, con arco piccolo]
[Sezione "In lista oggi" — card hero ordinate dinamicamente]
[Sezione "In arrivo" — locked, max 2]
[Calendario — appare solo da Fase 2]
```

### Header
Titolo dinamico (vedi BeWell_Brief_V2.md sezione 5 per le chiavi i18n).
Sottotitolo: "X attive · Y completate oggi"

### Card "Adesso"
Background: rgba(primaryColor, 0.12), bordo primaryColor 0.3 opacity.
Contiene:
- Label piccola "adesso" in uppercase, colore primary
- Arco SVG 48px con giorni dell'abitudine specifica (NON giorni globali)
- Nome abitudine tradotto
- Meta: fascia oraria + stato breve
- Pulsante azione contestuale (colore dell'abitudine)

L'arco nella card "Adesso" mostra i giorni di QUELLA specifica abitudine
verso la sua prossima fase — non verso la fase globale di Welly.
Questo è il Zeigarnik Effect applicato: vedi quanto manca al completamento
di quel specifico arco, vuoi chiuderlo.

### Card hero abitudine
```
┌─────────────────────────────────┐
│ [IMMAGINE 140px, full width]    │
│ [Badge streak top-right]        │
│ [Badge fascia oraria top-left]  │
│ [Overlay verde + ✓ se done]     │
├─────────────────────────────────┤
│ [Arc 40px] Nome     [Pulsante] │
│            Desc breve           │
└─────────────────────────────────┘
```

L'arco piccolo (40px) nella lista mostra solo i giorni completati
dell'abitudine specifica — visivamente occupa poco spazio ma trasmette
il progresso individuale. NON mostra "% verso fase globale".

Opacity dell'intera card: 1.0 se da fare, 0.75 se completata oggi.
Le completate scendono in fondo alla lista automaticamente.

### Ordine dinamico
```dart
List<HabitDefinition> _sortHabits(habits, completedIds, currentHour) {
  // 1. Abitudine suggerita per ora corrente (da ScheduleProvider)
  // 2. Abitudini per la fascia oraria corrente, non completate
  // 3. Abitudini per fasce future, non completate
  // 4. Abitudini già completate oggi (in fondo, opacity 0.75)
}
```

### Pulsanti azione per tipo di abitudine
- `water`: icona 💧 read-only + badge "traccia in home"
- `focus_25` / `focus_50`: "▶ 25 min" → push FocusScreen
- `breathing_box` / `breathing_478`: "▶ Avvia" → push BreathingScreen
- `eyes_20_20_20`: piccolo timer overlay inline (20 secondi)
- tutte le altre: cerchio vuoto → tap → cerchio pieno con ✓

### Calendario (Fase 2+)
Appare solo quando focus_25 è sbloccato.
Mostra solo le prossime 2-4 ore, non la giornata intera.
Il passato è opacity 0.3. Il futuro lontano è opacity 0.25.
Il blocco corrente è evidenziato con colore primary e tag "▶ in corso".

I 7 dot in cima al calendario = giorni della settimana.
Dot pieno = completato, dot outline = oggi, dot vuoto = non ancora.

Crescita calendario per fase:
- Fase 2: solo Focus + Pause
- Fase 3: Focus + Pause + abitudini nelle pause (dopo 7gg dal loro sblocco)
- Fase 4+: calendario completo con tutte le abitudini contestualizzate

---

## 3. SCHERMATA CRESCITA — REDESIGN DEFINITIVO

### Principio fondamentale
Crescita risponde a UNA domanda: "chi sto diventando?"
È modalità di riflessione (deliberative mindset) — si osserva, si contempla.
NULLA in questa schermata è da completare adesso.

### Struttura definitiva

```
[Header inline — nessun AppBar]
[Welly hero con fase + messaggio narrativo]
[Timeline fasi orizzontale]
[Card Reward — "I tuoi premi"]
[Heatmap consistenza — con tab per abitudine]
[Momenti memorabili — con peso visivo]
[Sezione badge]
```

### Header inline
Nessun AppBar con back button — è una tab, non una schermata pushed.
```dart
// In BwScaffold body, prima degli altri elementi:
Text(s.yourJourney, style: /* ambient: corsivo 20px w300, card: bold 22px */),
Text('${progression.totalDaysCompleted} ${s.days}', style: /* 13px textSec */),
```

### Welly Hero
CompanionWidget 160px con showPhase: true.
Sotto: pillola fase ("Fase 2 · Germoglio").
Frase narrativa personalizzata da getLocalizedMessage(s).
I giorni totali in grande e leggero sotto.

NON c'è nessun pulsante azione qui. Welly si osserva, non si interagisce.

### Timeline fasi
Row orizzontale con 5 fasi. Linea sottile di connessione.
Ogni fase: dot (✓ per passate, pieno per corrente, outline per future).
Nome fase sotto (8px). Fase corrente: colore primary, font w600.

### Card Reward
Posizionata SUBITO dopo la timeline — prima delle abitudini.
Questo è intenzionale: i premi sono la ricompensa della crescita,
vederli prima delle abitudini rinforza il loop cognitivo.

```dart
GestureDetector(
  onTap: () => Navigator.push(context, MaterialPageRoute(
    builder: (_) => const MarketplaceScreen())),
  child: Container(
    // sfondo amber-light, bordo amber 0.25
    child: Row(children: [
      // icona regalo
      // "I tuoi premi" + "Raccogli quello che hai seminato"
      // punti in amber grande
      // freccia destra
    ]),
  ),
)
```

### Heatmap consistenza
QUESTA SEZIONE NON ESISTE nella tab Abitudini — è esclusiva di Crescita.
Griglia 7×5 (7 giorni × 5 settimane).
Ogni cella: rect 14px × 14px, radius 2px.
4 livelli di opacity: 0 completamenti, 1, 2, 3+ (colore primary).
Cella oggi: border 0.5px primary, opacity 0.4.

Tab sopra la heatmap per filtrare per abitudine:
```dart
// Tab: acqua | focus | tutte
// Cambiano i dati mostrati nella heatmap
// Animazione fluida al cambio
```

Sotto la heatmap: label "X sett. fa" e "oggi" agli estremi.

### Momenti memorabili
QUESTA SEZIONE NON ESISTE nella tab Abitudini — è esclusiva di Crescita.
Peso visivo significativo — non una lista di righe sottili.

Ogni milestone è una card compatta:
```dart
Container(
  padding: EdgeInsets.all(10),
  decoration: BoxDecoration(
    color: p.card,
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: p.cardBorder, width: 0.5),
  ),
  child: Row(children: [
    // dot colorato (primary se raggiunto, textMut se futuro)
    // testo milestone ("Prima settimana consecutiva")
    // data a destra ("12 apr")
  ]),
)
```

Milestone predefinite da mostrare:
```dart
const milestones = [
  (7,   'firstWeek',        '7 giorni consecutivi'),
  (14,  'twoWeeks',         '2 settimane completate'),
  (21,  'threeWeeks',       '3 settimane — la svolta'),
  (42,  'sixWeeks',         '6 settimane — consolidamento'),
  (66,  'habitFormed',      '66 giorni — abitudine formata'),
  (100, 'hundredDays',      '100 giorni'),
];
```
Quelle raggiunte: dot primary, testo bianco 0.8, data a destra.
Prossima da raggiungere: dot primary outline, testo bianco 0.4, "tra Xg".
Quelle future: non mostrate (evitano il senso di "troppo lontano").

### Sezione badge
Solo badge guadagnati — mai quelli mancanti.
Griglia 3 colonne. Ogni badge: emoji 32px, nome 11px, descrizione 10px.
Se nessun badge: empty state con Welly e testo da BeWell_ProductBrief.md.

### Sezione "Il percorso di Welly" (nuova — esclusiva Crescita)
Una timeline verticale delle fasi raggiunte da Welly, con data.
È la storia condivisa utente + Welly — non solo dell'utente.

```
🌱 Seme         · iniziato il 5 apr
🌿 Germoglio    · raggiunto il 12 apr  ← fase corrente
🌾 Giovane      · tra 3 giorni         ← prossima
[le altre sfumate]
```

Tono: "il vostro percorso" non "il tuo percorso".
Welly e l'utente sono compagni — il possessivo è plurale.

---

## 4. HOME — AGGIORNAMENTI WELLY

### Fumetto sopra il companion
Il messaggio coach di Welly è un fumetto con triangolino in basso
che punta verso Welly — non una card separata.

Ordine nel ListView:
1. Header (saluto + nome + pillola fase)
2. Fumetto Welly (se message non vuoto)
3. CompanionWidget 180px — con WellyMood dinamico
4. Divider
5. Tracker acqua (solo barra, nessuna goccia)
6. Divider
7. Pillole statistiche
8. Card "momento attuale" (se Fase 2+)
9. Divider (se pendingPair o nextHabit)
10. Sezione "In arrivo"

### WellyMood in home
Il mood di Welly cambia in base allo stato del giorno (vedi Dimensione 2).
```dart
// In home_screen.dart, nel Consumer builder:
final mood = _getCurrentMood(_waterCount, isAllDone, DateTime.now().hour);
// Passare a CompanionWidget come parametro
```

### Animazione al completamento acqua
Quando _waterCount raggiunge il target:
1. Barra diventa primary (era accent)
2. Welly cambia mood → WellyMood.radiant
3. CompanionWidget carica video 'happy'
4. Dopo 3 secondi torna a loop idle normale

### Animazione al segnare un bicchiere
Tap sul pulsante → Welly breve animazione 'drink'
(solo se il video è disponibile e non sta già riproducendo un'animazione)

---

## 5. AGGIORNAMENTI i18n

Aggiungere in BwStrings abstract + tutte e 5 le lingue:

```dart
// Sezione Crescita
String get growthWellyJourney;    // "Il percorso di Welly"
String get growthOurJourney;      // "Il nostro percorso"
String get growthConsistency;     // "Consistenza"
String get growthMoments;         // "Momenti"
String get growthNextMilestone;   // "Prossimo traguardo"

// Milestone
String get milestone7days;        // "Prima settimana consecutiva"
String get milestone14days;       // "Due settimane completate"
String get milestone21days;       // "Tre settimane — la svolta"
String get milestone42days;       // "Sei settimane di crescita"
String get milestone66days;       // "Abitudine formata"
String get milestone100days;      // "Cento giorni"

// Welly stati (per accessibility e testi interni)
String get wellyStateCalm;        // "Welly è con te"
String get wellyStateRadiant;     // "Welly è raggiante"
String get wellyStateReturning;   // "Bentornato"
```

Traduzioni EN/IT/FR/DE/ES:

growthWellyJourney:
  en: "Welly's journey"  it: "Il percorso di Welly"
  fr: "Le parcours de Welly"  de: "Wellys Reise"  es: "El camino de Welly"

growthOurJourney:
  en: "Our journey"  it: "Il nostro percorso"
  fr: "Notre parcours"  de: "Unsere Reise"  es: "Nuestro camino"

growthConsistency:
  en: "Consistency"  it: "Consistenza"
  fr: "Régularité"  de: "Beständigkeit"  es: "Consistencia"

growthMoments:
  en: "Moments"  it: "Momenti"
  fr: "Moments"  de: "Momente"  es: "Momentos"

milestone7days:
  en: "First week in a row"  it: "Prima settimana consecutiva"
  fr: "Première semaine d'affilée"  de: "Erste Woche am Stück"
  es: "Primera semana seguida"

milestone14days:
  en: "Two weeks completed"  it: "Due settimane completate"
  fr: "Deux semaines complétées"  de: "Zwei Wochen geschafft"
  es: "Dos semanas completadas"

milestone21days:
  en: "Three weeks — the turning point"  it: "Tre settimane — la svolta"
  fr: "Trois semaines — le tournant"  de: "Drei Wochen — die Wende"
  es: "Tres semanas — el punto de inflexión"

milestone42days:
  en: "Six weeks of growth"  it: "Sei settimane di crescita"
  fr: "Six semaines de croissance"  de: "Sechs Wochen Wachstum"
  es: "Seis semanas de crecimiento"

milestone66days:
  en: "Habit formed"  it: "Abitudine formata"
  fr: "Habitude formée"  de: "Gewohnheit gebildet"  es: "Hábito formado"

milestone100days:
  en: "One hundred days"  it: "Cento giorni"
  fr: "Cent jours"  de: "Hundert Tage"  es: "Cien días"

wellyStateCalm:
  en: "Welly is here"  it: "Welly è con te"
  fr: "Welly est là"  de: "Welly ist hier"  es: "Welly está contigo"

wellyStateRadiant:
  en: "Welly is radiant"  it: "Welly è raggiante"
  fr: "Welly est radieux"  de: "Welly strahlt"  es: "Welly está radiante"

wellyStateReturning:
  en: "Welcome back"  it: "Bentornato"
  fr: "Bienvenue de retour"  de: "Willkommen zurück"  es: "Bienvenido de vuelta"

---

## 6. ORDINE DI IMPLEMENTAZIONE

### TASK 1 — WellyMood system
FILE: lib/widgets/companion/companion_widget.dart
FILE: lib/screens/home/home_screen.dart

- Aggiornare enum CompanionMood → WellyMood con tutti gli stati
- Implementare _getCurrentMood() in home_screen
- Mappare ogni WellyMood al video corretto
- Aggiungere animazione 'drink' al tap segnare bicchiere
- flutter analyze → 0 errori

### TASK 2 — Ambiente adattivo (HorizonPainter)
FILE: lib/widgets/bw_scaffold.dart
FILE: lib/providers/theme_provider.dart

- Aggiungere getter ambientGlow basato su progression.currentPhase
- Passare il valore a HorizonPainter
- Interpolazione colore orizzonte tra fase 1 e fase 5
- flutter analyze → 0 errori

### TASK 3 — i18n: aggiungere tutte le nuove chiavi
FILE: lib/l10n/app_localizations.dart
- Aggiungere in BwStrings abstract + _En + _It + _Fr + _De + _Es
- Usare le traduzioni della sezione 5
- flutter analyze → 0 errori

### TASK 4 — Schermata Abitudini: card "Adesso" con arco
FILE: lib/screens/habits/habits_screen.dart
- Aggiungere card "Adesso" in cima con arco SVG 48px
- L'arco mostra giorni di QUELLA abitudine specifica
- Colore dell'arco basato sull'abitudine (teal=acqua, purple=focus, amber=altro)
- Ordine dinamico usando ScheduleProvider.getHabitForNow()
- flutter analyze → 0 errori

### TASK 5 — Schermata Abitudini: card hero con arco piccolo
FILE: lib/screens/habits/habits_screen.dart
- Sostituire _HabitCard con versione hero (immagine 140px)
- Aggiungere arco SVG 40px nella sezione info sotto l'immagine
- Badge fascia oraria top-left sull'immagine
- Badge streak top-right sull'immagine
- Overlay verde + ✓ se completata oggi
- flutter analyze → 0 errori

### TASK 6 — Schermata Crescita: header + Welly hero
FILE: lib/screens/growth/growth_screen.dart
- Rimuovere AppBar
- Aggiungere header inline (titolo + giorni)
- CompanionWidget 160px con fase corretta
- Messaggio narrativo getLocalizedMessage(s)
- flutter analyze → 0 errori

### TASK 7 — Schermata Crescita: heatmap
FILE: lib/screens/growth/growth_screen.dart
- Implementare widget _HeatmapGrid
- 7×5 grid di celle colorate per livello completamento
- Tab selector: acqua | focus | tutte
- Dati reali da progression_provider
- flutter analyze → 0 errori

### TASK 8 — Schermata Crescita: momenti memorabili
FILE: lib/screens/growth/growth_screen.dart
- Implementare widget _MilestonesSection
- Lista milestone predefinite (7/14/21/42/66/100 giorni)
- Card compatte con dot colorato, testo, data
- Solo milestone raggiunte + prossima in arrivo
- Usare chiavi i18n milestone*
- flutter analyze → 0 errori

### TASK 9 — Schermata Crescita: percorso Welly
FILE: lib/screens/growth/growth_screen.dart
- Implementare widget _WellyJourneySection
- Timeline verticale delle fasi con date raggiunte
- Possessivo plurale: "il nostro percorso"
- Fase corrente evidenziata, future sfumate
- flutter analyze → 0 errori

### TASK 10 — Schermata Crescita: reward card + badge
FILE: lib/screens/growth/growth_screen.dart
- Aggiungere reward card (sfondo amber-light) DOPO timeline fasi
- Collegare a MarketplaceScreen in push
- Griglia badge solo per guadagnati
- flutter analyze → 0 errori

### TASK 11 — Build finale
flutter build apk --debug
Dimmi cosa hai fatto e cosa eventualmente manca.

---

## 7. REGOLE ASSOLUTE (non derogabili)

1. flutter analyze → 0 errori dopo OGNI task
2. Ogni stringa UI: context.sL.chiave — mai hardcoded
3. Nuova chiave = aggiungerla in BwStrings abstract + TUTTE E 5 LE LINGUE
4. Welly non ha mai stati visivamente negativi (tristezza, sofferenza, rimprovero)
5. La schermata Abitudini non mostra dati storici (heatmap, milestone, storico fasi)
6. La schermata Crescita non ha azioni da completare (nessun pulsante "Fatto")
7. L'arco in Abitudini mostra i giorni dell'abitudine specifica, NON la fase globale
8. La heatmap e i momenti memorabili esistono SOLO in Crescita
9. Il possessivo in Crescita è plurale dove si parla di Welly: "il nostro percorso"
10. debugUnlockAll NON chiama _evaluateUnlocks()
