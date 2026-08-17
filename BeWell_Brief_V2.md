# BeWell — Brief Evolutivo V2
# Da leggere DOPO CONTEXT.md e BeWell_ProductBrief.md
# Questo documento aggiorna e integra il brief precedente con decisioni definitive

---

## IMPORTANTE — COME USARE QUESTO DOCUMENTO

1. Leggi prima CONTEXT.md e BeWell_ProductBrief.md se non l'hai già fatto
2. Questo documento SOSTITUISCE le sezioni corrispondenti del brief precedente
3. Implementa nell'ordine dei TASK indicati in fondo
4. Dopo ogni task: `flutter analyze` → 0 errori → dimmi cosa hai fatto → prossimo task

---

## 1. TRACKER ACQUA — REVISIONE COMPLETA

### Cosa cambia
Il tracker acqua precedente aveva una doppia rappresentazione (8 gocce + barra). Si rimuove completamente la riga delle 8 gocce. Rimane SOLO la barra fluida con personalizzazione.

### Specifica definitiva

**Struttura nel ListView di home_screen.dart:**

```
[Titolo "Acqua oggi"] [X / N contenitori]
[Barra fluida LinearProgressIndicator]
[Testo contestuale Welly — piccolo, textSec]
[Link discreto: "bicchiere · 250ml" — cliccabile]
[Pulsante "+ Segna" se non completato | Badge "✓ Completato" se fatto]
```

**Barra fluida:**
- `LinearProgressIndicator` altezza 8px (non 4px — più visibile)
- `borderRadius: BorderRadius.circular(4)`
- `backgroundColor: p.bg2`
- `color: p.accent` se in corso, `p.primary` se completato
- Animazione fluida — `AnimatedContainer` con duration 400ms

**Personalizzazione contenitore:**
Sotto la barra, allineato a destra, un testo piccolo cliccabile:
```dart
GestureDetector(
  onTap: _openWaterSettings,
  child: Text(
    _containerLabel, // es. "bicchiere · 250ml" o "borraccia · 500ml"
    style: TextStyle(fontSize: 11, color: p.textSec, decoration: TextDecoration.underline),
  ),
)
```

**Bottom sheet `_openWaterSettings`:**
Mostra due opzioni con grande tab selezionabile:

```
┌─────────────────────────────────┐
│ Come stai tracciando l'acqua?   │
│                                 │
│  [🥛 Bicchiere]  [🫙 Borraccia] │
│                                 │
│ Dimensione: [slider o input ml] │
│ Obiettivo: ~2 litri al giorno   │
│                                 │
│ "Ci vuole circa N contenitori"  │
└─────────────────────────────────┘
```

Opzioni:
- **Bicchiere**: slider da 150ml a 400ml, step 50ml, default 250ml
- **Borraccia**: campo testo ml (default 500ml), o scelta tra 350/500/750/1000ml

Il sistema calcola N = ceil(2000 / ml_scelto) e aggiorna il contatore e la barra.

**Dati salvati in SharedPreferences:**
- `water_container_type`: 'glass' | 'bottle'
- `water_container_ml`: int (default 250)
- `water_target_n`: int calcolato (default 8)
- `water_count`: int (già esistente)
- `water_date`: string (già esistente)

**Testi contestuali Welly sotto la barra** (12px, textSec, corsivo in ambient):
- 0 contenitori: "Inizia con il primo — anche uno piccolo conta."
- 1-30% completato: "Stai andando bene. Continua così."
- 31-60%: "Più della metà. Il corpo te ne è grato."
- 61-99%: "Quasi — ancora poco."
- 100%: "Fatto. Il tuo corpo te ne è grato." + barra diventa primary

---

## 2. DISTANZE DI SBLOCCO — BASATE SULLA SCIENZA

### Fondamento scientifico
Phillippa Lally (UCL, 2010): mediamente 66 giorni per automatizzare un'abitudine, range 18-254 giorni.
La soglia pratica per considerare un'abitudine "sufficientemente radicata" da aggiungere qualcosa di nuovo è **21 giorni** (tre settimane di consistenza).
Non serve aspettare l'automatizzazione completa — serve che l'abitudine non sia più a rischio.

### Schema di sblocco definitivo

Implementare in `habit_library.dart` nei campi `UnlockCondition` di ogni abitudine:

```
ACQUA (water) — starter, giorno 0
  Obiettivo: 2L/giorno (8 bicchieri da 250ml o N borracce)

FOCUS 25 MIN (focus_25) — dopo 14 giorni di acqua completata
  Ratio: 2 settimane. L'abitudine base è stabile, il cervello è pronto per il focus.

REGOLA 20-20-20 (eyes_20_20_20) — si sblocca INSIEME a focus_25
  Non è una scelta separata. Quando sblocchi il focus, sai già che userai gli occhi.
  Appare come suggerimento automatico il giorno dopo lo sblocco di focus_25.

STRETCHING COLLO E SPALLE (neck_stretch) — dopo 21 giorni di acqua
  Prima coppia di scelta con esercizi alla scrivania.
  21 giorni = soglia di radicamento sicuro.

ESERCIZI ALLA SCRIVANIA (desk_exercise) — coppia con neck_stretch
  L'utente sceglie uno dei due. L'altro viene proposto dopo 21 giorni dal primo.

RESPIRAZIONE BOX (breathing_box) — dopo 21 giorni di focus_25
  Non prima. Il focus va consolidato prima di aggiungere un'altra pratica cognitiva.

ACQUA APPENA SVEGLI (water_morning) — dopo 21 giorni di acqua
  È un'evoluzione naturale dell'abitudine acqua. Coppia con spuntino sano.

SPUNTINO SANO (snack) — coppia con water_morning
  Stessa logica: evoluzione dell'abitudine nutrizionale.

PASSEGGIATA PRANZO (walk_lunch) — dopo 42 giorni totali completati
  6 settimane: abitudini consolidate, l'utente ha dimostrato consistenza.
  Coppia con pranzo al parco (se disponibile in base al profilo).

PRANZO SENZA SCHERMO (lunch_no_screen) — dopo 42 giorni totali
  Coppia con passeggiata pranzo. Si sblocca in contemporanea.

CHECK POSTURA (posture) — dopo 21 giorni di neck_stretch o desk_exercise
  Evoluzione naturale delle abitudini di movimento.

RESPIRAZIONE 4-7-8 (breathing_478) — dopo 21 giorni di breathing_box
  Upgrade della respirazione. Solo quando quella base è consolidata.

FOCUS PROFONDO 50 MIN (focus_50) — dopo 42 giorni di focus_25
  Upgrade del focus. 6 settimane di Pomodoro prima di passare ai cicli lunghi.

STRETCHING ATTIVO 5 MIN (stretching_active) — dopo 42 giorni di neck_stretch o desk_exercise
  Evoluzione delle abitudini di movimento.

MICRO-MEDITAZIONE 3 MIN (meditation) — dopo 42 giorni di breathing_box o breathing_478
  Evoluzione delle pratiche di mindfulness.

POWER NAP 20 MIN (nap) — dopo 60 giorni totali
  Abitudine avanzata. Solo per chi ha dimostrato lunga consistenza.

FOCUS SENZA TELEFONO (focus_no_phone) — dopo 21 giorni di focus_25
  Potenziamento naturale del focus. Non richiede molto tempo.

ROUTINE PRE-SONNO (sleep_routine) — dopo 60 giorni totali
  Abitudine avanzata. Richiede maturità del percorso.

SVEGLIA COSTANTE (wake_consistent) — dopo 21 giorni di sleep_routine
  Solo dopo che la routine serale è stabile.

SCALA INVECE ASCENSORE (stairs) — dopo 21 giorni di walk_lunch o passeggiata
  Evoluzione del movimento quotidiano.

PRANZO AL PARCO (lunch_park) — coppia con passeggiata pranzo
  Si propone dopo che la passeggiata è consolidata (21 giorni).
```

### Regola anti-sovraccarico
**MAI due sblocchi nello stesso giorno.**
**Minimo 7 giorni di distanza tra un nuovo sblocco e il successivo.**
Implementare in `_evaluateUnlocks()` nel `progression_provider.dart`:
```dart
// Controlla quanti giorni fa è avvenuto l'ultimo sblocco
// Se < 7 giorni, posticipa anche se la condizione è soddisfatta
final daysSinceLastUnlock = _daysSinceLastUnlock();
if (daysSinceLastUnlock < 7) return; // aspetta
```

---

## 3. SISTEMA ADATTIVO — RALLENTAMENTO E ACCELERAZIONE

### Rallentamento volontario
In ogni card abitudine nella schermata Abitudini, un menu contestuale (icona ⋮ o long press) offre:
- "Ho bisogno di più tempo con questa"
- "Questa abitudine mi pesa troppo"

Risposta di Welly (bottom sheet):
```
"Nessun problema — rafforziamo questa prima di aggiungere altro.
È esattamente la scelta giusta."
```
Effetto: posticipa il prossimo sblocco di 14 giorni. Rimuove pressione.
Salva in SharedPreferences: `habit_{id}_slowdown_count: int`

### Rallentamento automatico (rilevamento difficoltà)
Il sistema monitora:
- Tasso di completamento degli ultimi 7 giorni per ogni abitudine
- Se una o più abitudini scendono sotto il 60% di completamento per 3+ giorni consecutivi

Welly interviene in home (non come notifica push — come messaggio in app):
```
"Ho notato che stai trovando un po' difficile mantenere il ritmo.
Vuoi che rallentiamo un po'?"
```
Due opzioni:
- **"Sì, rallentiamo"** → posticipa sblocchi pendenti di 14 giorni, riduce reminder a 1/giorno
- **"No, continuo"** → nessun cambiamento, Welly non richiede per 7 giorni

Implementare in `ProgressionProvider` con getter:
```dart
bool get needsSlowdown {
  // Controlla ultimi 7 giorni per ogni abitudine attiva
  // Se completamento medio < 60%, return true
}
```
E in `home_screen.dart` mostrare il messaggio se `progression.needsSlowdown && !_slowdownDismissed`.

### Accelerazione (per utenti molto consistenti)
Se tasso di completamento > 90% per 14 giorni consecutivi e ci sono sblocchi in attesa:
Welly suggerisce:
```
"Stai andando molto bene — sei pronto per qualcosa di nuovo prima del previsto?"
```
Due opzioni:
- **"Sì, sono pronto"** → anticipa prossimo sblocco di 7 giorni
- **"No, resto qui"** → nessun cambiamento

---

## 4. ONBOARDING — SCELTA STUDENTE/LAVORATORE

### Dove si fa la scelta
**Nel Welly Welcome, schermata 2** (quella del nome), DOPO aver inserito il nome.
Non aggiunge una schermata nuova — si aggiunge al contenuto della schermata 2.

### Struttura schermata 2 aggiornata
```
[CompanionWidget]

"Come ti chiamo?"
"Il mio nome è Welly, ma tu puoi darmi il nome che preferisci."

[Campo testo nome — già esistente]

─────────────────────────

"E come passi le tue giornate?"

[🎓 Studio]    [💼 Lavoro]
```

Le due opzioni sono card selezionabili affiancate, grandi e visive.
La selezione è richiesta per procedere (ma con un default: Lavoro).

Salvare in SharedPreferences:
- `user_type`: 'student' | 'worker' (già esiste nel modello)

### Banner orario in home (solo per lavoratori)
Il giorno 2 (non il primo — prima lascia che si abitui), appare un banner discreto
SOPRA il tracker acqua, SOTTO il messaggio Welly:

```
┌─────────────────────────────────────────────────────┐
│ 💼 Ho impostato orario standard: 9-13 / 14-18       │
│    È quello giusto per te?  [Modifica] [Va bene]    │
└─────────────────────────────────────────────────────┘
```

Stile: sfondo p.bg2, bordo p.cardBorder 0.5, radius 12, padding 12.
Scompare definitivamente dopo che l'utente tocca uno dei due CTA.
Salva: `work_schedule_confirmed: bool`

**Bottom sheet "Modifica orario":**
```
"I tuoi orari di lavoro"

Mattina:
  Inizio: [picker ora — default 09:00]
  Fine:   [picker ora — default 13:00]

Pomeriggio:
  Inizio: [picker ora — default 14:00]
  Fine:   [picker ora — default 18:00]

[ ] Ho una pausa pranzo fissa
    Orario: [picker — default 13:00]  Durata: [30min ▾]

[Salva]
```

Salvare in SharedPreferences:
- `work_start_morning`: '09:00'
- `work_end_morning`: '13:00'
- `work_start_afternoon`: '14:00'
- `work_end_afternoon`: '18:00'
- `lunch_time`: '13:00'
- `lunch_duration_min`: 30

Questi dati alimentano la logica di schedulazione della schermata Abitudini.

---

## 5. SCHERMATA ABITUDINI — SPECIFICA COMPLETA CON SCHEDULAZIONE

### Fondamento scientifico (da implementare, non da mostrare all'utente)
- **Ritmo circadiano**: picchi cognitivi nelle prime 2-3 ore dopo il risveglio e nel tardo pomeriggio
- **Ritmo ultradiano**: cicli di 90 minuti di alta/bassa energia durante la veglia
- **Formula lavoratori**: 4 ore mattina + pausa vera 10 min a metà + 4 ore pomeriggio + pausa vera 10 min a metà + 5 min/ora per micro-attività
- **Formula studenti**: blocchi di 90 min (3 Pomodoro) + pausa 20 min, più flessibili nel pomeriggio

### Header schermata
```dart
// Titolo dinamico per ora del giorno
String _habitsTitle(int hour) {
  if (hour < 10) return s.habitsMorningTitle; // "Inizia bene la giornata."
  if (hour < 13) return s.habitsMiddayTitle;  // "Nel momento giusto."
  if (hour < 17) return s.habitsAfternoonTitle; // "Buon pomeriggio."
  return s.habitsEveningTitle; // "Come è andata oggi?"
}

// Sottotitolo
'${habits.length} ${s.activeHabits.toLowerCase()} · ${completedToday} ${s.completedToday}'
```

### Sezione "Adesso" — card prioritaria in cima
Prima di tutte le altre card, una card prominente che mostra COSA fare IN QUESTO MOMENTO.

Logica `_getHabitForNow(hour, userType, habits, workSchedule)`:

**Per lavoratori (orario default 9-18):**
```
Prima dell'inizio lavoro (< work_start_morning):
  → acqua_appena_svegli (se sbloccata) | acqua | stretching_active

Inizio lavoro (work_start_morning):
  → focus_25 (primo blocco — picco cognitivo massimo)

Ogni 60 minuti nel blocco lavoro:
  → micro-break: eyes_20_20_20 | neck_stretch | posture (1 minuto ciascuna)

Metà mattina (work_start_morning + 2h):
  → pausa vera 10 min: stretching | breathing_box | acqua

Fine mattina (work_end_morning - 30min):
  → snack | acqua

Pausa pranzo (lunch_time):
  → walk_lunch (se sbloccata) | lunch_no_screen | acqua

Inizio pomeriggio (work_start_afternoon):
  → power_nap (se sbloccata e < 14:30) | micro_meditazione | breathing_478

Primo blocco pomeriggio (work_start_afternoon + 30min):
  → focus_25 o focus_50 (secondo blocco — secondo picco)

Ogni 60 minuti nel blocco pomeriggio:
  → micro-break: posture | eyes_20_20_20 | acqua

Metà pomeriggio (work_start_afternoon + 2h):
  → pausa vera 10 min: desk_exercise | stretching_active | breathing_box

Fine lavoro (work_end_afternoon):
  → stairs (se sbloccata) | acqua | stretching_active

Sera (> work_end_afternoon + 2h):
  → routine_pre_sonno (dopo le 21) | acqua

Nessuna abitudine disponibile per quell'ora:
  → "Tutto sotto controllo per ora. Welly è con te."
```

**Per studenti:**
```
Mattina (8-12): focus_25 × 3 (ciclo 90 min) → pausa 20 min → repeat
Metà mattina (10:30): acqua + snack
Primo pomeriggio (13-14): pausa pranzo attiva → walk_lunch | lunch_no_screen
Pomeriggio (14-17): più flessibile — breathing | micro-meditazione | secondo focus
Sera (> 18): routine serale → sleep_routine
```

**Card "Adesso" — design:**
```dart
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: p.primaryLight,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: p.primary.withValues(alpha: 0.3), width: 1),
  ),
  child: Column(children: [
    Row(children: [
      Text('Adesso', style: /* piccolo, textSec, uppercase */),
      Spacer(),
      Text(_currentTimeSlot(hour), style: /* ora corrente, piccolo */),
    ]),
    SizedBox(height: 10),
    Row(children: [
      // Immagine abitudine 52px circolare
      // Nome + descrizione breve
      // Pulsante azione grande a destra
    ]),
  ]),
)
```

### Fascia oraria sulle card
Sotto il nome di ogni abitudine, una piccola indicazione NON ORARIA ma per fascia:
```
🌅 Mattina     → attività da fare prima delle 10
☀️ Metà mattina → 10-12
🍃 Pausa pranzo → 12-14
🌤 Pomeriggio   → 14-18
🌙 Sera         → dopo le 18
```
Testo: 11px, textMut. Questa indicazione è educativa — spiega PERCHÉ quell'abitudine va fatta in quel momento.

### Ordine dinamico delle card
```dart
List<HabitDefinition> _sortHabits(List<HabitDefinition> habits, int hour) {
  // 1. Prima: abitudine suggerita per l'ora corrente
  // 2. Poi: abitudini per la fascia oraria corrente, non ancora completate
  // 3. Poi: abitudini per fasce orarie future, non completate
  // 4. Alla fine: abitudini già completate oggi (opacity 0.75)
}
```

### Card abitudine — design hero definitivo
```dart
AnimatedOpacity(
  opacity: done ? 0.75 : 1.0,
  duration: Duration(milliseconds: 400),
  child: Container(
    margin: EdgeInsets.only(bottom: 12),
    decoration: BoxDecoration(
      color: p.card,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(
        color: done ? p.primary.withValues(alpha: 0.4) : p.cardBorder,
        width: done ? 1 : 0.5,
      ),
    ),
    child: Column(children: [
      // IMMAGINE HERO — 140px altezza full width
      Stack(children: [
        ClipRRect(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          child: ColorFiltered(
            colorFilter: done ? /* desatura */ : /* colori pieni */,
            child: Image.asset(habit.imageAsset, height: 140, fit: BoxFit.cover),
          ),
        ),
        if (done) /* overlay verde con ✓ bianco 44px al centro */,
        if (days > 0) /* badge streak top-right: "🔥 X giorni" */,
        /* badge fascia oraria top-left: "🌅 Mattina" */,
        if (isWater) /* badge "💧 traccia in home" */,
      ]),
      // INFO + AZIONE — padding 14px
      Padding(
        padding: EdgeInsets.fromLTRB(14, 12, 14, 14),
        child: Row(children: [
          Expanded(child: Column(children: [
            Text(s.habitName(habit.id), /* nome tradotto, 15px w600 */),
            Text(done ? '✓ completata' : habit.description, /* 11px textSec */),
          ])),
          /* pulsante azione contestuale */,
        ]),
      ),
    ]),
  ),
)
```

**Pulsanti azione per tipo:**
- `water`: icona 💧 read-only, tooltip "Traccia in home"
- `focus_25` / `focus_50`: `Container` "▶ 25 min" → push a FocusScreen
- `eyes_20_20_20`: `Container` "▶ 20 sec" → piccolo timer inline o overlay
- `neck_stretch` / `desk_exercise` / `stretching_active`: `Container` "Fatto" (o avvia guida se implementata)
- `breathing_box` / `breathing_478`: `Container` "▶ Avvia" → push a BreathingScreen
- altre: cerchio → tap → spunta

### Sezione "In arrivo" in fondo
Separata da `Divider`. Massimo 2 abitudini locked.
```
Titolo: "Prossimamente"
Per ogni abitudine locked:
  - Immagine 52px desaturata + lucchetto overlay
  - Nome + giorni mancanti
  - Fascia oraria prevista
```

---

## 6. CALENDARIO — PROGRESSIONE PER FASI

### Fase 1 — Solo acqua (giorni 0-13)
La schermata Abitudini ha UNA sola card: acqua.
Sotto la card acqua, il calendario non esiste ancora.
Welly in home: tutto sull'acqua.

### Fase 2 — Focus sbloccato (giorni 14+)
Il calendario appare come sezione NUOVA in fondo alla schermata Abitudini:
```
"Il tuo ritmo oggi"

[08:00] 💧 Acqua appena svegli
[09:00] 🎯 Focus 25 min ──────┐
[09:25]    Pausa 5 min        │ Ciclo ultradiano
[09:30] 🎯 Focus 25 min       │
[09:55]    Pausa 5 min        │
[10:00] 🎯 Focus 25 min ──────┘
[10:25]    Pausa lunga 15-20 min
...
```
Il calendario è minimale — solo blocchi focus e pause. Nient'altro.
I colori: focus = p.primary, pausa = p.bg2, acqua = accent.

### Fase 3+ — Abitudini nelle pause
Man mano che le abitudini si sbloccano, entrano automaticamente nel calendario nelle slot corrette:
- Stretching → nella pausa lunga dopo il ciclo focus
- Passeggiata → nella pausa pranzo
- Respirazione → nella pausa tra cicli focus
- Check postura → ogni ora (marcatore leggero, non invasivo)

**Regola di inserimento:**
Un'abitudine entra nel calendario SOLO dopo 7 giorni dal suo sblocco.
Prima la fa "liberamente", poi il calendario la contestualizza.

---

## 7. HOME — AGGIORNAMENTI

### Speech bubble posizionamento
Il fumetto di Welly va SOPRA il companion nel ListView.
Ordine definitivo dall'alto:
1. Header (saluto + nome + pillola fase)
2. Speech bubble Welly (con triangolino in basso)
3. CompanionWidget 180px
4. [Divider]
5. Tracker acqua (solo barra + personalizzazione)
6. [Divider]
7. Pillole statistiche
8. Card "momento attuale"
9. [Divider — solo se esiste sezione "In arrivo"]
10. Sezione "In arrivo" (se pendingPair o nextHabit)

### Card "momento attuale"
Usa la stessa logica `_getHabitForNow` definita in Abitudini.
In home è più compatta — mostra solo il nome dell'abitudine e il pulsante.
Se l'utente è nella Fase 1 (solo acqua), questa card NON appare — il tracker acqua è già sufficiente.

### Banner orario (solo per lavoratori, solo giorno 2)
Posizionato TRA il messaggio Welly e il tracker acqua.
Vedi sezione 4 per la specifica completa.

---

## 8. AGGIORNAMENTI ALLE CHIAVI i18n

Aggiungere in BwStrings abstract + tutte e 5 le lingue:

```dart
// Tracker acqua personalizzato
String get waterContainerGlass;      // "bicchiere"
String get waterContainerBottle;     // "borraccia"
String get waterContainerSettings;   // "Come stai tracciando l'acqua?"
String get waterGoalCalc;            // "Ci vogliono circa N contenitori"

// Schermata Abitudini
String get habitsMorningTitle;       // "Inizia bene la giornata."
String get habitsMiddayTitle;        // "Nel momento giusto."
String get habitsAfternoonTitle;     // "Buon pomeriggio."
String get habitsEveningTitle;       // "Come è andata oggi?"
String get habitsNowLabel;           // "Adesso"
String get habitsComingSoon;         // "Prossimamente"
String get habitsAllDone;            // "Tutto fatto per ora. Welly è con te."
String get completedToday;           // "completate oggi"

// Fasce orarie
String get timeMorning;              // "Mattina"
String get timeMidday;               // "Metà mattina"
String get timeLunch;                // "Pausa pranzo"
String get timeAfternoon;            // "Pomeriggio"
String get timeEvening;              // "Sera"

// Onboarding tipo utente
String get onboardingUserTypeTitle;  // "E come passi le tue giornate?"
String get onboardingStudent;        // "Studio"
String get onboardingWorker;         // "Lavoro"

// Banner orario
String get workScheduleBanner;       // "Ho impostato orario standard: 9-13 / 14-18"
String get workScheduleConfirm;      // "Va bene così"
String get workScheduleEdit;         // "Modifica"
String get workScheduleTitle;        // "I tuoi orari di lavoro"
String get workScheduleMorning;      // "Mattina"
String get workScheduleAfternoon;    // "Pomeriggio"
String get workScheduleLunch;        // "Ho una pausa pranzo fissa"
String get workScheduleSave;         // "Salva"

// Sistema adattivo
String get slowdownPrompt;           // "Ho notato che stai trovando un po' difficile..."
String get slowdownYes;              // "Sì, rallentiamo"
String get slowdownNo;               // "No, continuo"
String get slowdownHabitMenu;        // "Ho bisogno di più tempo con questa"
String get slowdownWellyResponse;    // "Nessun problema — rafforziamo questa prima..."
String get speedupPrompt;            // "Stai andando molto bene — sei pronto per qualcosa..."
String get speedupYes;               // "Sì, sono pronto"
String get speedupNo;                // "No, resto qui"

// Calendario
String get calendarTitle;            // "Il tuo ritmo oggi"
String get calendarFocus;            // "Focus"
String get calendarBreak;            // "Pausa"
String get calendarLongBreak;        // "Pausa lunga"
```

**Traduzioni per tutte le 5 lingue (EN/IT/FR/DE/ES):**

```
waterContainerGlass:
  en: "glass"  it: "bicchiere"  fr: "verre"  de: "Glas"  es: "vaso"

waterContainerBottle:
  en: "bottle"  it: "borraccia"  fr: "gourde"  de: "Flasche"  es: "botella"

waterContainerSettings:
  en: "How are you tracking your water?"
  it: "Come stai tracciando l'acqua?"
  fr: "Comment suis-tu ta consommation d'eau ?"
  de: "Wie verfolgst du dein Wasser?"
  es: "¿Cómo estás registrando tu agua?"

habitsMorningTitle:
  en: "Start the day well."  it: "Inizia bene la giornata."
  fr: "Bien commencer la journée."  de: "Starte gut in den Tag."
  es: "Empieza bien el día."

habitsMiddayTitle:
  en: "In the right moment."  it: "Nel momento giusto."
  fr: "Au bon moment."  de: "Im richtigen Moment."  es: "En el momento justo."

habitsAfternoonTitle:
  en: "Good afternoon."  it: "Buon pomeriggio."
  fr: "Bon après-midi."  de: "Guten Nachmittag."  es: "Buenas tardes."

habitsEveningTitle:
  en: "How did it go today?"  it: "Come è andata oggi?"
  fr: "Comment s'est passée ta journée ?"
  de: "Wie war dein Tag?"  es: "¿Cómo te fue hoy?"

habitsNowLabel:
  en: "Right now"  it: "Adesso"  fr: "Maintenant"  de: "Jetzt"  es: "Ahora"

habitsComingSoon:
  en: "Coming up"  it: "Prossimamente"  fr: "À venir"
  de: "Demnächst"  es: "Próximamente"

habitsAllDone:
  en: "All good for now. Welly is with you."
  it: "Tutto sotto controllo per ora. Welly è con te."
  fr: "Tout est bon pour l'instant. Welly est avec toi."
  de: "Alles gut für jetzt. Welly ist bei dir."
  es: "Todo bien por ahora. Welly está contigo."

completedToday:
  en: "completed today"  it: "completate oggi"
  fr: "complétées aujourd'hui"  de: "heute erledigt"  es: "completadas hoy"

timeMorning:
  en: "Morning"  it: "Mattina"  fr: "Matin"  de: "Morgen"  es: "Mañana"

timeMidday:
  en: "Mid-morning"  it: "Metà mattina"  fr: "Milieu de matinée"
  de: "Vormittag"  es: "Media mañana"

timeLunch:
  en: "Lunch break"  it: "Pausa pranzo"  fr: "Pause déjeuner"
  de: "Mittagspause"  es: "Pausa del almuerzo"

timeAfternoon:
  en: "Afternoon"  it: "Pomeriggio"  fr: "Après-midi"
  de: "Nachmittag"  es: "Tarde"

timeEvening:
  en: "Evening"  it: "Sera"  fr: "Soir"  de: "Abend"  es: "Noche"

onboardingUserTypeTitle:
  en: "And how do you spend your days?"
  it: "E come passi le tue giornate?"
  fr: "Et comment passes-tu tes journées ?"
  de: "Und wie verbringst du deine Tage?"
  es: "¿Y cómo pasas tus días?"

onboardingStudent:
  en: "Study"  it: "Studio"  fr: "Études"  de: "Studium"  es: "Estudio"

onboardingWorker:
  en: "Work"  it: "Lavoro"  fr: "Travail"  de: "Arbeit"  es: "Trabajo"

workScheduleBanner:
  en: "I've set standard hours: 9-13 / 14-18. Is that right for you?"
  it: "Ho impostato orario standard: 9-13 / 14-18. È quello giusto per te?"
  fr: "J'ai configuré les horaires standard : 9-13 / 14-18. C'est le bon ?"
  de: "Ich habe Standardzeiten eingestellt: 9-13 / 14-18. Stimmt das für dich?"
  es: "He configurado el horario estándar: 9-13 / 14-18. ¿Es el correcto para ti?"

workScheduleConfirm:
  en: "That's fine"  it: "Va bene così"  fr: "C'est bon"
  de: "Passt so"  es: "Está bien"

workScheduleEdit:
  en: "Edit"  it: "Modifica"  fr: "Modifier"  de: "Bearbeiten"  es: "Editar"

slowdownPrompt:
  en: "I noticed you're finding it a bit hard to keep the pace. Want to slow down a little?"
  it: "Ho notato che stai trovando un po' difficile mantenere il ritmo. Vuoi che rallentiamo un po'?"
  fr: "J'ai remarqué que tu as du mal à maintenir le rythme. Tu veux qu'on ralentisse un peu ?"
  de: "Ich habe bemerkt, dass du Schwierigkeiten hast, das Tempo zu halten. Sollen wir ein wenig langsamer werden?"
  es: "He notado que te está costando mantener el ritmo. ¿Quieres que vayamos más despacio?"

slowdownYes:
  en: "Yes, let's slow down"  it: "Sì, rallentiamo"
  fr: "Oui, ralentissons"  de: "Ja, langsamer"  es: "Sí, vamos más despacio"

slowdownNo:
  en: "No, I'll keep going"  it: "No, continuo"
  fr: "Non, je continue"  de: "Nein, ich mache weiter"  es: "No, sigo adelante"

slowdownWellyResponse:
  en: "No problem — let's strengthen this one before adding anything new. That's exactly the right choice."
  it: "Nessun problema — rafforziamo questa prima di aggiungere altro. È esattamente la scelta giusta."
  fr: "Pas de problème — renforçons celle-ci avant d'en ajouter une autre. C'est exactement le bon choix."
  de: "Kein Problem — stärken wir diese, bevor wir etwas Neues hinzufügen. Das ist genau die richtige Entscheidung."
  es: "Sin problema — reforcemos esta antes de añadir algo nuevo. Es exactamente la decisión correcta."

calendarTitle:
  en: "Your rhythm today"  it: "Il tuo ritmo oggi"
  fr: "Ton rythme aujourd'hui"  de: "Dein Rhythmus heute"  es: "Tu ritmo hoy"
```

---

## 9. NUOVI FILE DA CREARE

### `lib/screens/habits/habit_calendar.dart`
Widget che renderizza il calendario giornaliero.
Si mostra SOLO dalla Fase 2 in poi (quando focus_25 è sbloccato).
Inizialmente: solo blocchi focus + pause.
Cresce man mano che si sbloccano abitudini.

### `lib/providers/schedule_provider.dart`
Gestisce orari utente (student/worker) e logica di schedulazione.
Espone:
- `UserType get userType`
- `WorkSchedule get schedule`
- `HabitDefinition? getHabitForNow(List<HabitDefinition> active, int hour)`
- `String getTimeSlot(HabitDefinition habit)` — restituisce fascia oraria
- `bool get needsSlowdown`
- `void setSlowdown(String habitId)`

### Aggiornamenti file esistenti
- `habit_library.dart`: aggiornare UnlockCondition per ogni abitudine con i giorni corretti
- `progression_provider.dart`: aggiungere `_daysSinceLastUnlock()`, `needsSlowdown`, sistema accelerazione
- `welly_welcome_screen.dart`: aggiungere scelta studente/lavoratore nella schermata 2
- `home_screen.dart`: aggiungere banner orario (solo giorno 2, solo worker), rimuovere gocce acqua
- `habits_screen.dart`: aggiungere card "Adesso", ordine dinamico, fasce orarie, calendario

---

## 10. ORDINE DI IMPLEMENTAZIONE

### TASK 1 — Tracker acqua (home_screen.dart)
- Rimuovere la Row delle 8 gocce
- Sostituire con barra fluida 8px
- Aggiungere link "bicchiere · 250ml" cliccabile
- Implementare `_openWaterSettings()` bottom sheet
- Aggiungere SharedPreferences per container_type, container_ml, target_n
- flutter analyze → 0 errori

### TASK 2 — i18n: aggiungere tutte le nuove chiavi
- Aggiungere in BwStrings abstract
- Aggiungere in _En, _It, _Fr, _De, _Es con le traduzioni della sezione 8
- flutter analyze → 0 errori

### TASK 3 — Onboarding: scelta studente/lavoratore
- Modificare welly_welcome_screen.dart schermata 2
- Aggiungere le due card selezionabili dopo il campo nome
- Salvare user_type in SharedPreferences
- flutter analyze → 0 errori

### TASK 4 — ScheduleProvider
- Creare lib/providers/schedule_provider.dart
- Implementare UserType enum, WorkSchedule model
- Implementare getHabitForNow() con la logica della sezione 5
- Implementare getTimeSlot()
- Registrare il provider in main.dart
- flutter analyze → 0 errori

### TASK 5 — Banner orario in home
- Aggiungere `_showWorkBanner` bool gestito da SharedPreferences
- Mostrare banner solo se: worker + giorno 2 + non ancora confermato
- Implementare bottom sheet modifica orario
- flutter analyze → 0 errori

### TASK 6 — Schermata Abitudini: card "Adesso" e ordine dinamico
- Aggiungere card "Adesso" in cima usando ScheduleProvider.getHabitForNow()
- Implementare _sortHabits() con ordine dinamico
- Aggiungere badge fascia oraria sulle card hero
- flutter analyze → 0 errori

### TASK 7 — Distanze sblocco in habit_library.dart
- Aggiornare ogni UnlockCondition con i giorni corretti della sezione 2
- Aggiungere logica anti-sovraccarico in _evaluateUnlocks()
- flutter analyze → 0 errori

### TASK 8 — Sistema adattivo
- Implementare needsSlowdown in ProgressionProvider
- Aggiungere menu contestuale sulle card abitudini
- Aggiungere messaggio Welly di rallentamento in home
- flutter analyze → 0 errori

### TASK 9 — Calendario (Fase 2)
- Creare lib/screens/habits/habit_calendar.dart
- Mostrare solo quando focus_25 è sbloccato
- Renderizzare blocchi focus + pause
- flutter analyze → 0 errori

### TASK 10 — Build finale
- `flutter build apk --debug`
- Dimmi cosa hai fatto e cosa manca
