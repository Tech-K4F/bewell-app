# BeWell — Brief Completo per Claude Code

## ATTENZIONE — LEGGI PRIMA DI TUTTO
Questo documento contiene la specifica completa dell'app BeWell.
Leggi tutto prima di fare qualsiasi modifica.
Dopo aver letto, chiedi conferma su cosa implementare per primo.

---

## STATO ATTUALE DEL PROGETTO

App Flutter funzionante con:
- Firebase Auth (email/password + Google + Apple)
- Sistema i18n 5 lingue (EN/IT/FR/DE/ES) — BwStrings abstract class
- Sistema temi — BwStyle (card/ambient) + BwPalette (5 palette)
- Companion Welly con VideoPlayer e animazioni
- Progression system con HabitState e fasi
- Nav progressiva con enum NavItem (home/habits/growth/profile)
- Debug panel nascosto (7 tap sul companion)

Bug aperti prioritari:
1. Debug panel: "+N giorni" e "Sblocca tutto" non aggiornano correttamente appDayNumber
2. Tab Abitudini rimane grigia anche dopo simulazione giorni
3. Nomi abitudini hardcoded in italiano in alcune schermate
4. HabitIntroSheet non collegato al sistema di sblocco

---

## ARCHITETTURA — NON MODIFICARE SENZA MOTIVO

```
lib/
  l10n/app_localizations.dart     ← BwStrings abstract + _En _It _Fr _De _Es
  providers/
    progression_provider.dart     ← HabitState, appDayNumber, _debugDayOffset
    theme_provider.dart           ← BwStyle + BwPalette
    app_provider.dart             ← user, currentNavIndex, onLoginComplete()
  models/habit_library.dart       ← 21 abitudini, choicePairs
  screens/
    home/home_screen.dart         ← companion + water tracker
    home/home_shell.dart          ← nav enum NavItem
    growth/growth_screen.dart     ← progressione + badge
    focus/focus_screen.dart       ← timer pomodoro
  widgets/
    debug_panel.dart              ← DebugTrigger + DebugPanel
    companion/companion_widget.dart
```

Regole architetturali:
- Ogni stringa UI usa context.sL.chiave (mai hardcoded)
- Aggiungere chiave = aggiungerla in BwStrings abstract + tutte e 5 le lingue
- screens[currentIndex] — NON IndexedStack — per rebuild dinamico
- _debugDayOffset per simulare giorni, non modificare _installDate

---

## STRUTTURA NAVIGAZIONE

```
enum NavItem { home, habits, growth, profile }

Home     — sempre disponibile
Abitudini — si sblocca al giorno 4
Crescita  — si sblocca al giorno 14
Profilo  — sempre disponibile
```

Lo sblocco delle tab è un evento celebrato — non silenzioso.
Vedi FLUSSO 9 per i dettagli.

---

## LE 4 SCHERMATE — CONTENUTO DEFINITIVO

### HOME
Obiettivo: farti sentire accolto e orientato in 3 secondi.

Struttura dall'alto:
1. Header — saluto personalizzato + nome + fase come pillola
2. Welly — grande, centrato, animato, reattivo allo stato del giorno
   - Nuvoletta con messaggio coach (lui che parla, non l'app)
3. Card "momento attuale" — UNA sola azione suggerita per l'orario
   - Pulsante grande: "Fatto" o "Inizia"
   - Al posto di "prossima attività" quando c'è uno sblocco disponibile:
     pulsante cliccabile che apre HabitIntroSheet
4. Tracker acqua — compatto, barra fluida, tap rapido
5. Streak e stato — tre pillole: 🔥 giorni, ⭐ punti oggi, 🌱 fase

NON in home: lista abitudini, badge, progressione dettagliata, marketplace.

### ABITUDINI (si sblocca giorno 4)
Obiettivo: le tue abitudini hanno personalità, vuoi interagire con loro.

Struttura:
1. Header dinamico con sottotitolo contestuale
2. Abitudini attive — carte con:
   - Immagine di sfondo (assets/images/habits/habit_*.jpg)
   - Nome, categoria, stato (completata/da fare/in ritardo)
   - Streak personale ("12 giorni 🔥")
   - Fase dell'abitudine ("Germoglio — 9 giorni al prossimo livello")
   - Pulsante azione: "Inizia" (timer) o "Fatto" (tracciamento)
   - Ordine dinamico: prima quelle da fare ora, poi completate (in fondo, attenuate)
3. Dettaglio abitudine — sheet con descrizione, logica scientifica, storico 7 giorni
4. Sezione "In arrivo" — 1-2 abitudini locked con immagine sfocata e lucchetto

NOTA: mostra SOLO abitudini già sbloccate. Le locked solo in "In arrivo".

### CRESCITA (si sblocca giorno 14)
Obiettivo: renderti orgoglioso di chi stai diventando.

Struttura:
1. Hero narrativo — Welly nella sua fase + frase personale narrativa
2. Timeline fasi — orizzontale scrollabile, Welly evolve mentre scorri
3. Abitudini — barra progressione verso fase successiva per ognuna
4. Momenti memorabili — milestone personali in ordine cronologico
5. Badge — 5-6 significativi, non 20, mostrati come oggetti fisici
6. Statistiche — numeri concreti che crescono: giorni totali, bicchieri, minuti focus
7. "I tuoi premi" — marketplace integrato in fondo a Crescita
   Header sezione: "Raccogli quello che hai seminato"

### PROFILO
Obiettivo: gestione senza attrito.

Struttura:
1. Header identità — avatar, nome, tipo account, punti disponibili grandi
2. Impostazioni — voce singola verso settings screen
3. Account — email, cambio password, lingua, logout

Il marketplace è in Crescita, non qui.

---

## WELLY — SISTEMA COMPLETO

### Profilo psicologico
- Età percepita: 32 anni
- Voce: informale accogliente, caldo, mai aggressivo
- Mix amico + mentore — compagno di viaggio
- Frasi brevi. Spesso molto brevi. Mai più di due concetti.
- Parla sempre di TE, mai in astratto
- Firma: "il tuo corpo", "oggi", "adesso" — mai generico

### NON dice mai
- Mai aggressivo o colpevolizzante
- Mai banalmente positivo ("sei fantastico!")
- Mai neutro come un'assistente virtuale
- Mai ordini secchi ("fallo adesso")

### Stati emotivi
- Saluto mattutino: gesto di benvenuto, animazione "look"
- Soddisfazione: annuisce, varia tra approvazione/esultanza/piccolo salto
- Preoccupazione gentile: espressione interrogativa, non triste
- Celebrazione milestone: animazione speciale più lunga, mai vista prima
- Guida: leggermente in primo piano, espressione attenta

---

## TESTI WELLY COMPLETI

### Onboarding (4 schermate)

SCHERMATA 1 — Presentazione
Titolo: "Ciao, sono Welly."
Corpo: "Sono qui per accompagnarti — non per dirti cosa fare, ma per aiutarti a capire cosa funziona per te. Andremo piano. Una cosa alla volta."
CTA: "Iniziamo"

SCHERMATA 2 — Nome
Titolo: "Come ti chiamo?"
Corpo: "Il mio nome è Welly, ma tu puoi darmi il nome che preferisci. Siamo in questo insieme."
CTA: "Perfetto"

SCHERMATA 3 — Prima abitudine acqua
Titolo: "Partiamo dall'acqua."
Corpo 1: "Non perché sia banale — ma perché è la base di tutto il resto. Quando sei disidratato anche solo del 2%, la concentrazione cala, l'umore peggiora, ti stanchi prima."
Corpo 2: "Oggi iniziamo da qui: 8 bicchieri. Ti ricordo io quando bere. Poi, man mano che consolidi questa abitudine, aggiungiamo qualcosa di nuovo. Sempre al ritmo giusto per te."
CTA: "Bevi il primo bicchiere adesso"

SCHERMATA 4 — Preview premi
Titolo: "Ogni passo vale qualcosa."
Corpo: "Ogni volta che completi un'abitudine guadagni punti Be Well. Li accumuli senza pensarci — e puoi usarli per premi reali: caffè, voucher, esperienze. Perché il cambiamento merita una ricompensa."
CTA: "Vai alla tua home"

### Messaggi coach giornalieri

Giorni 1-3:
- "Iniziamo da qui. Un bicchiere ogni ora e mezza — sembra poco, ma è già un cambiamento reale."
- "Il primo giorno è sempre il più importante. Non perché sia il più difficile — ma perché è quello in cui decidi."
- "Non devi fare tutto perfettamente. Devi solo iniziare."

Giorni 4-6:
- "Tre giorni. Il tuo corpo ha già iniziato a registrarlo."
- "Stai costruendo qualcosa. Non si vede ancora tutto, ma c'è."
- "Sai qual è la cosa più sottovalutata delle abitudini? La costanza sui giorni normali."

Giorno 7:
- "Una settimana. Non è un caso — hai scelto di esserci ogni giorno."

Giorni 8-13:
- "L'acqua è la base di tutto il resto. Lo stai dimostrando ogni giorno."
- "Non stai solo bevendo acqua. Stai imparando come funziona il cambiamento."
- "I giorni che non hai voglia sono quelli che contano di più."

Giorno 14:
- "Due settimane. Questa abitudine è tua adesso — non mia, tua."

Giorni 15-41:
- "Ogni giorno che aggiungi rende il prossimo più facile. È matematica del cervello."
- "Siamo a buon punto. Sai cosa mi piace di come stai andando? Non hai fretta."
- "Stai diventando la persona che beve acqua. Piccola cosa, grande identità."

Giorno 42+:
- "Questa abitudine non ha più bisogno di te che ci pensi. Ci pensa il corpo."
- "Fiorente. Non è una parola che uso spesso."

Mattina:
- "Buongiorno. Primo bicchiere prima del caffè — il tuo corpo te ne sarà grato per le prossime ore."
- "Inizia bene. Un bicchiere d'acqua adesso vale più di tre nel pomeriggio."

Sera:
- "Com'è andata oggi? Anche i giorni imperfetti contano."
- "Prima di dormire — hai bevuto abbastanza? Un ultimo bicchiere non fa male."

Nessun bicchiere dopo le 15:
- "Non ho visto bicchieri oggi. Come stai? Un po' d'acqua potrebbe aiutare."
- "È ancora presto per arrendersi alla giornata. Hai ancora tempo."

### Guida contestuale (prima volta in ogni schermata)

Home:
"Questa è la tua base. Qui trovi come stai oggi e cosa ti aspetta. Io ti aggiorno ogni giorno."

Abitudini (giorno 4):
"Le tue abitudini attive sono qui. Tocca una card per iniziare, o segna 'Fatto' se l'hai già fatta. Ogni giorno che completi costruisce qualcosa."

Crescita (giorno 14):
"Qui vedi il tuo percorso — quanto hai fatto, dove stai andando, cosa hai guadagnato. Non aprirla ogni giorno. Aprila quando vuoi sentirti fiero."

Profilo:
"Le tue impostazioni e il tuo account sono qui. Semplice."

Marketplace (dentro Crescita):
"Questi sono i premi che puoi riscattare con i tuoi punti. Li hai guadagnati tu — goditi la scelta."

### HabitIntroSheet — testi per ogni abitudine

ACQUA
Perché ora: "È la prima perché è la più importante. Non c'è abitudine più semplice con un impatto più immediato."
Cosa fa: "Idrata le cellule, migliora la concentrazione, stabilizza l'umore. In 3 giorni senti la differenza."
Come iniziare: "8 bicchieri al giorno. Io ti ricordo quando bere — tu devi solo rispondere."

FOCUS 25 MIN
Perché ora: "Hai già l'acqua. Ora aggiungiamo qualcosa per la mente. 25 minuti di focus cambiano la produttività dell'intera giornata."
Cosa fa: "Il cervello non è multitasking — è sequenziale. 25 minuti senza interruzioni allena la concentrazione come un muscolo."
Come iniziare: "Scegli un'ora. Telefono capovolto. Timer avviato. Poi vedi tu stesso."

REGOLA 20-20-20
Perché ora: "Stai già lavorando con focus. Adesso proteggi gli occhi che ti permettono di farlo."
Cosa fa: "Ogni 20 minuti, 20 secondi a 6 metri di distanza. Riduce l'affaticamento visivo del 60%."
Come iniziare: "Ti ricordo io ogni 20 minuti. Tu guardi fuori dalla finestra per 20 secondi. Semplice."

STRETCHING COLLO E SPALLE
Perché ora: "Collo e spalle accumulano tensione senza che te ne accorga. Due minuti adesso prevengono ore di dolore dopo."
Cosa fa: "Rilascia la tensione muscolare cronica, migliora la postura, riduce i mal di testa da stress."
Come iniziare: "Due minuti, tre volte al giorno. Ti mostro io i movimenti."

RESPIRAZIONE BOX
Perché ora: "Hai imparato a concentrarti. Ora impara a recuperare. La respirazione box resetta il sistema nervoso in 4 minuti."
Cosa fa: "4 secondi inspira, 4 trattieni, 4 espira, 4 trattieni. Attiva il parasimpatico — lo stesso sistema che si attiva nel sonno profondo."
Come iniziare: "Quando senti tensione o stanchezza mentale. Non aspettare di stare male per usarla."

PASSEGGIATA PRANZO
Perché ora: "Il pomeriggio inizia qui. 15 minuti fuori a pranzo cambiano le prossime 4 ore di lavoro."
Cosa fa: "Movimento, luce naturale, distanza dallo schermo. Tre cose che il cervello chiede e raramente ottiene nel mezzo della giornata."
Come iniziare: "Non serve un parco. Basta uscire. Anche solo girare l'isolato conta."

ESERCIZI ALLA SCRIVANIA
Perché ora: "Non serve alzarsi. Basta sedersi diversamente per 5 minuti. Il corpo lo chiede — tu non l'hai ancora ascoltato."
Cosa fa: "Attiva la circolazione, riduce la rigidità, migliora l'energia nel pomeriggio."
Come iniziare: "5 minuti ogni 2 ore. Ti guido io con i movimenti giusti."

ACQUA APPENA SVEGLI
Perché ora: "Il tuo corpo è disidratato dopo 8 ore di sonno. Un bicchiere prima di tutto il resto cambia come inizi la giornata."
Cosa fa: "Attiva il metabolismo, sveglia il sistema digestivo, aiuta la concentrazione nelle prime ore."
Come iniziare: "Un bicchiere accanto al letto. Prima ancora del telefono."

CHECK POSTURA
Perché ora: "Ogni ora, 10 secondi. Spalle giù, schiena dritta, piedi a terra. La postura non si corregge una volta — si mantiene."
Cosa fa: "Riduce il dolore cronico da sedentarietà, migliora la respirazione, aumenta l'energia."
Come iniziare: "Ti ricordo io ogni ora. Tu fai il check — 10 secondi, poi torni a quello che stavi facendo."

RESPIRAZIONE 4-7-8
Perché ora: "Quando il box breathing non basta, c'è il 4-7-8. Attiva il sistema parasimpatico in meno di 2 minuti."
Cosa fa: "Riduce l'ansia, abbassa la frequenza cardiaca, prepara il corpo al recupero profondo."
Come iniziare: "Inspira 4 secondi, trattieni 7, espira 8. Tre cicli. Poi vedi come ti senti."

STRETCHING ATTIVO 5 MIN
Perché ora: "Non è ginnastica. È solo ricordare al corpo che esiste. Cinque minuti, due volte al giorno."
Cosa fa: "Migliora la flessibilità, riduce la rigidità, aumenta l'energia disponibile."
Come iniziare: "Mattina prima di sederti. Sera prima di dormire. Ti guido io."

SPUNTINO SANO
Perché ora: "Il crollo di energia alle 11 non è stanchezza — è glucosio basso. Uno spuntino cambia le prossime 3 ore."
Cosa fa: "Stabilizza la glicemia, mantiene la concentrazione, evita gli eccessi a pranzo."
Come iniziare: "Frutta, noci, yogurt. Preparalo la sera prima — così è già lì quando serve."

PRANZO SENZA SCHERMO
Perché ora: "Il cervello non si riposa se continua a elaborare immagini. Mangia. Solo mangia."
Cosa fa: "Migliora la digestione, riduce lo stress, dà al cervello una pausa vera."
Come iniziare: "Telefono capovolto durante il pranzo. 20 minuti di silenzio digitale."

FOCUS PROFONDO 50 MIN
Perché ora: "Sei pronto per il passo successivo. Il cervello impara a entrare in stato di flusso."
Cosa fa: "Il lavoro profondo è un muscolo. Più lo alleni, più riesci a sostenere la concentrazione."
Come iniziare: "Un blocco da 50 minuti al giorno. Nessuna interruzione. Il resto aspetta."

MICRO-MEDITAZIONE 3 MIN
Perché ora: "Non hai bisogno di un cuscino zen. Tre minuti di silenzio interiore, anche alla scrivania."
Cosa fa: "Riduce il rumore mentale, migliora la chiarezza, abbassa i livelli di cortisolo."
Come iniziare: "Occhi chiusi. Respiro naturale. Osserva i pensieri senza seguirli. 3 minuti."

SCALA INVECE DELL'ASCENSORE
Perché ora: "Non è fitness. È semplicemente scegliere il percorso più lungo ogni volta che puoi."
Cosa fa: "Movimento quotidiano accumulato, migliora la salute cardiovascolare, aumenta l'energia."
Come iniziare: "Ogni volta che puoi. Non sempre — ogni volta che puoi."

ROUTINE PRE-SONNO
Perché ora: "Il sonno si prepara un'ora prima. Schermo spento 30 minuti prima di dormire. Il resto viene da sé."
Cosa fa: "Migliora la qualità del sonno, riduce il tempo per addormentarsi, aumenta il recupero notturno."
Come iniziare: "Scegli un'ora. Schermo spento. Qualcosa di calmo. Lascia che il corpo capisca che è ora."

SVEGLIA COSTANTE
Perché ora: "Il jet lag sociale è reale. Alzarsi alla stessa ora ogni giorno è il singolo intervento più potente per il ritmo circadiano."
Cosa fa: "Regola il ritmo sonno-veglia, migliora la qualità del sonno profondo, stabilizza l'energia durante il giorno."
Come iniziare: "Stessa ora. Anche il weekend. Per le prime due settimane — poi il corpo se lo ricorda da solo."

POWER NAP 20 MIN
Perché ora: "Non è pigrizia. È recupero attivo. Venti minuti, non di più — il timer è fondamentale."
Cosa fa: "Ripristina la concentrazione, migliora l'umore, aumenta la produttività del pomeriggio."
Come iniziare: "Tra le 13 e le 15. Timer a 20 minuti. Se non riesci a dormire, il solo rilassarsi conta."

FOCUS SENZA TELEFONO
Perché ora: "Il telefono non deve essere visibile. La sola presenza dello schermo riduce la concentrazione del 20%."
Cosa fa: "Elimina la distrazione ambientale, aumenta la profondità del focus, riduce l'ansia da notifica."
Come iniziare: "Telefono in un'altra stanza durante le sessioni focus. Non sulla scrivania — in un'altra stanza."

PRANZO AL PARCO
Perché ora: "Già cammini. E se ci mangiassi anche? Il parco non è solo un posto — è una pausa vera."
Cosa fa: "Luce naturale, aria aperta, distanza dall'ufficio. Tre cose che rigenerano davvero."
Come iniziare: "Una volta a settimana per iniziare. Poi vedi se vuoi di più."

### Milestone

Primo giorno completato:
"Eccolo. Il primo. Non sottovalutarlo — il primo giorno è quello che apre la porta."

3 giorni consecutivi:
"Tre giorni di fila. Il corpo ha iniziato a registrarlo. Continua."

Prima settimana:
"Sette giorni. Non è fortuna — è scelta ripetuta. Sono con te dall'inizio e te lo dico: stai andando bene."

Prima abitudine consolidata:
"Questa abitudine è tua. Non devi più pensarci — è parte di te. Adesso aggiungiamo qualcosa."

Prima abitudine automatica:
"Automatica. Significa che non costa più nulla. Il cambiamento più profondo che esiste."

21 giorni:
"Tre settimane. Secondo la ricerca bastano 66 giorni per automatizzare un'abitudine — sei quasi a metà. E si vede."

Primo premio riscattato:
"Hai usato i tuoi punti. Te li sei guadagnati — spero che il premio valga quanto l'abitudine che ti ha portato fin qui."

### Rientro dopo assenza

2 giorni:
"Bentornato. Mi sei mancato."

3-6 giorni:
"Che bello rivederti. Sei tornato — ed è quello che conta."

7+ giorni:
"Eccoti. Non importa quanto tempo è passato — sei qui adesso, e questo è il punto di partenza."

Streak interrotta:
"La serie si è fermata — ma tutto quello che hai costruito è ancora lì. Continuiamo da dove siamo."

### Notifiche push

ACQUA
Mattina (8:30): "Buongiorno. Che ne dici di iniziare con un bicchiere d'acqua prima del caffè?"
Metà mattina (10:30): "È passata un'oretta — il tuo corpo potrebbe gradire un po' d'acqua."
Pomeriggio (15:00): "Com'è andata stamattina con l'acqua? Se sei indietro, adesso è un buon momento."
Sera (19:00): "La giornata si chiude — hai ancora qualche bicchiere da recuperare? Nessuna fretta, ma prima di dormire fa bene."

FOCUS
Inizio sessione: "Pronto per 25 minuti? Telefono capovolto. Via."

RESPIRAZIONE
Reminder: "Un momento. Respira con me — 4 minuti cambiano il resto del pomeriggio."

PASSEGGIATA
Pranzo: "È ora di uscire. Anche solo 10 minuti fuori vale."

STREAK A RISCHIO (22+ ore senza aprire)
"La giornata sta finendo. Hai ancora tempo."

MILESTONE VICINA
"Ti mancano 2 giorni a una settimana consecutiva. Ci sei quasi."

NUOVO SBLOCCO DISPONIBILE
"C'è qualcosa di nuovo per te. Apri Be Well."

ASSENZA — sequenza notifiche re-engagement
1 giorno senza aprire (ore 20:00): "Come stai? Non ti ho visto oggi."
3 giorni: "Sono qui quando sei pronto. Le tue abitudini ti aspettano."
7 giorni: "È passata una settimana. Nessuna pressione — ma quando vuoi tornare, ci sono."
14 giorni: [nessuna notifica — rispetta lo spazio]

### Empty states

Home senza abitudini aggiuntive:
"Stai costruendo le basi. L'acqua per ora — poi aggiungiamo. Ogni cosa a suo tempo."

Abitudini appena sbloccata, solo acqua:
"Questa è la tua prima abitudine. Tocca la card per vedere come stai andando."

Crescita primissimi giorni:
"Il percorso è appena iniziato. Torna qui tra qualche settimana — vedrai già una storia."

Badge nessuno ancora:
"I tuoi badge appariranno qui man mano che costruisci. Non correre — arrivano da soli."

Marketplace punti insufficienti:
"Ti mancano ancora un po' di punti. Continua con le abitudini — arrivano più in fretta di quanto pensi."

Errori tecnici:
"Qualcosa non ha funzionato. Riprovo?"

---

## FLUSSI DI INTERAZIONE COMPLETI

### FLUSSO 1 — Apertura app ogni giorno

Prima apertura del giorno:
1. Splash screen 800ms
2. Check stato: nuovo giorno? abitudini da fare? messaggio coach giusto?
3. Home con fade morbido
4. Welly gesto saluto (animazione "look" o "breathe" in base all'ora)
5. Dopo 1.5s: nuvoletta con messaggio coach — slide up gentile
6. Se primo avvio assoluto → Welly Welcome
7. Se rientro dopo 2+ giorni → messaggio rientro prima del coach

Riapertura durante la giornata:
1. Home si carica, nessun saluto
2. Stato aggiornato
3. Welly idle — reagisce solo se c'è qualcosa di rilevante

### FLUSSO 2 — Segnare bicchiere d'acqua

1. Tap sul tracker o pulsante
2. Splash animato, numero sale
3. Barra si riempie — 300ms
4. Haptic: tap leggero
5. Ai primi 4 bicchieri: nessuna reazione Welly
6. Al 4° bicchiere: Welly annuisce, nuvoletta "Metà strada."
7. All'8° bicchiere (obiettivo):
   - Barra diventa verde pieno
   - Animazione Welly "happy"
   - Nuvoletta: "Fatto. Il tuo corpo te ne è grato."
   - Punti salgono e spariscono — 600ms
   - Haptic: impulso soddisfacente
   - Pulsante diventa "✓ Obiettivo raggiunto"

Rimozione bicchiere (tap su già segnato):
1. Nessun dialog — undo window 3 secondi
2. Toast: "Rimosso — tocca di nuovo per annullare"

### FLUSSO 3 — Completare un'abitudine

Tap su card:
1. Card si espande leggermente
2. Sheet si apre dal basso
3. Welly piccolo in alto nel sheet

Se "Fatto" (tracciamento manuale):
1. Pausa 200ms
2. Card si trasforma: colore cambia, spunta appare
3. Punti salgono e spariscono
4. Haptic: impulso deciso
5. Sheet si chiude dopo 1 secondo
6. Card scende in fondo alla lista — attenuata, con spunta
7. Se ultima abitudine del giorno → FLUSSO 4

Se "Inizia" (timer):
1. Sheet si trasforma in timer — non chiude e riapre
2. Timer parte con countdown
3. Welly scompare dal sheet
4. Al completamento → stesso di "Fatto"

### FLUSSO 4 — Giornata completata

Tutte le abitudini del giorno segnate:
1. Pausa 500ms
2. Overlay leggero caldo sul colore primario
3. Welly al centro — animazione speciale
4. Testo:
   - Giorni 1-6: "Tutto fatto oggi. Domani si riparte."
   - Giorno 7: "Una settimana intera. Non è poco."
   - Giorno 14: "Due settimane. Stai costruendo qualcosa di solido."
   - Giorni normali: "Giornata completa. Welly è soddisfatto — e tu?"
5. Riepilogo: punti oggi + streak
6. Pulsante: "Chiudi"
7. Haptic: vibrazione lunga soddisfacente

### FLUSSO 5 — Sblocco nuova abitudine

Trigger: raggiunto numero giorni per sblocco.

Il pulsante "In arrivo" in home diventa cliccabile.
Tocca → apre HabitIntroSheet direttamente.
NON interrompe al prossimo avvio.

HabitIntroSheet:
1. Emerge dal basso — più grande del normale sheet
2. Welly in alto, animazione "encourage"
3. Titolo: "C'è qualcosa di nuovo per te."
4. Immagine abitudine con reveal animato
5. Tre sezioni: Perché ora / Cosa fa / Come iniziare

Se coppia di scelta:
1. Titolo: "Scegli dove concentrarti adesso."
2. Sottotitolo: "L'altra arriverà dopo — non perdi nulla."
3. Due card affiancate con immagine, nome, effort
4. Tap su una → si evidenzia, l'altra si attenua
5. Pulsante: "Inizia con questa"

Dopo scelta:
1. Card appare in Abitudini con animazione entrata
2. Welly celebra
3. Primo messaggio coach per quella abitudine

### FLUSSO 6 — Rientro dopo assenza

2 giorni: Welly espressione interrogativa-calda
Nuvoletta: "Bentornato. Mi sei mancato."
Mostra: una sola azione suggerita, la più semplice

3-6 giorni:
Nuvoletta: "Che bello rivederti. Sei tornato — ed è quello che conta."
NON mostrare tutto quello che hai mancato — solo oggi

7+ giorni: Welly espressione calda, nessun giudizio
Nuvoletta: "Eccoti. Non importa quanto tempo è passato — sei qui adesso, e questo è il punto di partenza."
Pulsante: "Riprendiamo"
Reset morbido: non azzera progressi, riporta al ritmo base

Streak interrotta:
"La serie si è fermata — ma tutto quello che hai costruito è ancora lì. Continuiamo da dove siamo."

Grace period streak: 1 giorno automatico, nessun acquisto richiesto.

### FLUSSO 7 — Riscatto premio

1. Profilo → Crescita → "I tuoi premi"
2. Card premi: quelle raggiungibili più luminose
3. Tap su premio → sheet con dettaglio
4. Welly in alto, espressione neutra
5. "Ti resterebbero X punti dopo questo riscatto."
6. Punti insufficienti: pulsante disabilitato, "Ti mancano ancora X punti. Ci arrivi presto."

Tap su Riscatta:
1. Dialog: "Sei sicuro?" / "Verranno scalati X punti." / Annulla + Confermo
2. Animazione punti che volano via — 800ms
3. Pausa 400ms
4. Codice con effetto reveal
5. Welly celebra
6. Nuvoletta: "Eccolo. Te lo sei guadagnato."
7. Pulsante "Copia codice" grande
8. "Come usarlo" — istruzioni brand in 2 righe
9. Premio in "I miei premi" con stato "Non ancora usato"

Segna come usato:
1. Card cambia stato — attenuata, badge "Usato"
2. Nessuna animazione — è azione amministrativa

### FLUSSO 8 — Primo avvio assoluto

1. Splash 1 secondo
2. Welly Welcome — 4 schermate
3. Home per la prima volta:
   - Welly più grande del solito
   - Nuvoletta: "Questa è la tua home. Torna qui ogni giorno — io ci sono."
   - Dopo 3 secondi: guida sui 3 elementi principali
   - Freccia verso nav: "Le altre sezioni si sbloccano man mano che avanzi."

### FLUSSO 9 — Sblocco tab navigazione

Sblocco Abitudini (giorno 4):
1. All'avvio del giorno 4, prima del messaggio coach
2. Welly: "C'è una sezione nuova per te. Le tue abitudini hanno adesso il loro spazio."
3. Tab Abitudini appare in nav con animazione entrata
4. Badge verde "nuovo" sulla tab
5. Primo accesso → guida contestuale

Sblocco Crescita (giorno 14):
1. Welly: "Hai abbastanza storia adesso per guardarla. La tua crescita ha il suo spazio."
2. Tab Crescita appare con animazione
3. Primo accesso → guida contestuale

---

## DECISIONI ARCHITETTURALI PRESE

- Marketplace: IN Crescita, non in Profilo. Header: "Raccogli quello che hai seminato"
- Calendario giornaliero: FASE 2 — non implementare ora
- Grace period streak: 1 giorno automatico, no acquisto
- Limite acqua: fisso a 8 bicchieri
- Notifiche: opt-in proposto dopo il primo giorno
- Re-engagement: notifiche a 1/3/7 giorni di assenza, stop a 14

---

## MICROINTERAZIONI

Pull to refresh: Welly si "sveglia" invece dello spinner

Transizioni tra tab:
- Home: fade morbido
- Abitudini: slide da sinistra
- Crescita: leggero zoom out
- Profilo: slide da destra

Haptic feedback:
- Completare abitudine: impulso deciso
- Segnare bicchiere: tap leggero
- Sblocco livello: vibrazione lunga
- Riscatto premio: impulso + pausa + impulso

Empty states: Welly sempre presente, mai schermata vuota con solo testo grigio

Errori: Welly con espressione dispiaciuta, mai messaggi tecnici

---

## PRIORITÀ DI IMPLEMENTAZIONE

### FASE 1 — Bug critici (fare PRIMA di tutto)
1. Fix debug panel: debugSimulateDays aggiorna _debugDayOffset correttamente
2. Fix sblocco tab: dopo simulazione giorni, Habits e Growth si sbloccano
3. Fix acceptHabit: non riblocca più l'alternativa della coppia
4. Collegare HabitIntroSheet al pulsante "In arrivo" in home

### FASE 2 — Schermata Abitudini
Costruire la vera schermata Abitudini (attualmente punta a FocusScreen).
Carte con immagine, stato, streak, fase, pulsante azione.
Ordine dinamico per orario.
Sezione "In arrivo" in fondo.

### FASE 3 — Home migliorata
Card "momento attuale" intelligente per orario.
Welly reattivo allo stato del giorno.
Nuvoletta come fumetto di Welly, non card separata.

### FASE 4 — Crescita migliorata
Timeline fasi scrollabile orizzontale.
Welly che evolve mentre scorri.
Momenti memorabili come diario automatico.
Marketplace integrato in fondo come "I tuoi premi".

### FASE 5 — Flussi celebrazione
Animazioni milestone.
Giornata completata overlay.
Sblocco tab animato.

### FASE 6 — Notifiche
flutter_local_notifications già in pubspec.
Sequenza re-engagement 1/3/7 giorni.

---

## NOTE TECNICHE IMPORTANTI

- flutter analyze deve dare 0 errori prima di ogni modifica
- Ogni stringa UI in context.sL.chiave — mai hardcoded
- Aggiungere chiave: BwStrings abstract + _En + _It + _Fr + _De + _Es
- appDayNumber = DateTime.now().difference(_installDate).inDays + _debugDayOffset
- debugUnlockAll: NON chiamare _evaluateUnlocks dopo (riblocca tutto)
- screens[currentIndex] NON IndexedStack per rebuild dinamico
- HabitLibrary.choicePairs: le alternative NON si escludono, si propongono in sequenza
