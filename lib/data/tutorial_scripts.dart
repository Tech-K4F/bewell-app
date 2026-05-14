// ─────────────────────────────────────────────────────────────────────────────
//  BeWell — TutorialScripts
//  Tutti i dialog del tutorial Welly, indicizzati per ID.
//  Testo in italiano. Fatti scientifici con fonte.
//
//  Struttura delle fasi:
//    CAPITOLO 1 — Prime ore (home_first_open … streak_explain)
//    CAPITOLO 2 — Primo sblocco Focus (focus_unlocked … calendar_appears)
//    CAPITOLO 3 — Crescita (phase2_reached … phase3_reached)
//    CAPITOLO 4 — Milestones (milestone_7_days … milestone_66_days)
//    CONTESTUALI — streak_broken, no_completion_3days, perfect_week
// ─────────────────────────────────────────────────────────────────────────────

import '../models/welly_dialog.dart';

abstract class TutorialScripts {
  static final Map<String, WellyDialog> _all = {
    for (final d in _dialogs) d.id: d,
  };

  /// Restituisce il dialog per [id], o null se non esiste.
  /// Gestisce dinamicamente anche i pattern `habit_chosen_*`.
  static WellyDialog? get(String id) {
    if (_all.containsKey(id)) return _all[id];
    // Factory dinamica: popup di presentazione per ogni abitudine scelta
    if (id.startsWith('habit_chosen_')) {
      return WellyDialog(
        id: id,
        mood: TutorialMood.celebrating,
        // Il testo reale viene da sL.tutorialText(id) in ogni lingua.
        // Questo è il fallback italiano usato se la localizzazione non copre l'id.
        text: '✅ Ottima scelta! Trovi la nuova abitudine nella scheda Habits. '
            'Completala ogni giorno per consolidarla.',
        actions: [TutorialAction.ok],
      );
    }
    return null;
  }

  /// Tutti gli ID registrati (per debug / reset).
  static Iterable<String> get allIds => _all.keys;
}

// ─────────────────────────────────────────────────────────────────────────────
// CAPITOLO 1 — Prime ore in app
// ─────────────────────────────────────────────────────────────────────────────

const _dialogs = <WellyDialog>[

  // ── Home: prima apertura ──────────────────────────────────────────────────
  WellyDialog(
    id: 'home_first_open',
    mood: TutorialMood.welcoming,
    text: 'Benvenuto! Questa è la tua base. In cima trovi sempre '
        'l\'abitudine più urgente per adesso. Inizia sempre da lì — '
        'il resto può aspettare.',
    actions: [TutorialAction.ok, TutorialAction.more],
    nextDialogId: 'home_first_open_2',
  ),

  WellyDialog(
    id: 'home_first_open_2',
    mood: TutorialMood.thinking,
    text: 'L\'acqua è la prima abitudine perché è la base biologica di tutto '
        'il resto. Senza idratazione, la concentrazione cala fino al 20% '
        'già dopo 90 minuti.',
    scienceFact: 'Adan et al. (2012): dehydration reduces cognitive performance '
        'significantly after just 90 min.',
    actions: [TutorialAction.ok],
  ),

  // ── Tracker acqua: prima interazione ─────────────────────────────────────
  WellyDialog(
    id: 'water_tracker_first',
    mood: TutorialMood.happy,
    text: 'Il tracker conta i bicchieri da quando apri l\'app ogni mattina. '
        '8 al giorno è il target — ma anche arrivare a 5 è già meglio di ieri.',
    scienceFact: 'EFSA: fabbisogno idrico giornaliero 2,0–2,5 L per adulti in condizioni normali.',
    actions: [TutorialAction.ok],
  ),

  // ── Prima abitudine completata ────────────────────────────────────────────
  WellyDialog(
    id: 'first_completion',
    mood: TutorialMood.celebrating,
    text: 'Fatto! Ogni completamento crea una connessione neurale nuova. '
        'Piccola, ma reale. Il tuo cervello ha appena rinforzato un circuito.',
    scienceFact: 'Hebb (1949): "neurons that fire together, wire together" — '
        'ogni repetizione rafforza la sinapsi.',
    actions: [TutorialAction.ok, TutorialAction.more],
    nextDialogId: 'streak_explain',
  ),

  // ── Streak: concatenato a first_completion ────────────────────────────────
  WellyDialog(
    id: 'streak_explain',
    mood: TutorialMood.thinking,
    text: 'Se torni domani, inizia la tua streak. L\'unica regola che conta: '
        'non saltare mai due giorni di fila. Uno stop è umano. Due sono '
        'un\'abitudine nuova — quella sbagliata.',
    scienceFact: 'James Clear, Atomic Habits: "Never miss twice" è la regola '
        'più efficace per mantenere un\'abitudine.',
    actions: [TutorialAction.ok],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // CAPITOLO 2 — Habits tab + Focus
  // ─────────────────────────────────────────────────────────────────────────

  // ── Prima visita scheda Habits ────────────────────────────────────────────
  WellyDialog(
    id: 'habits_tab_first',
    mood: TutorialMood.excited,
    text: 'Qui trovi tutte le abitudini ordinate per il momento migliore della '
        'tua giornata. Welly conosce i tuoi ritmi — le abitudini mattutine '
        'si mostrano di mattina, quelle serali di sera.',
    actions: [TutorialAction.ok, TutorialAction.more],
    nextDialogId: 'habit_card_explain',
  ),

  // ── Spiegazione card abitudine ────────────────────────────────────────────
  WellyDialog(
    id: 'habit_card_explain',
    mood: TutorialMood.thinking,
    text: 'L\'arco circolare in basso a sinistra si riempie ogni volta che '
        'completi. A 7 giorni scatta qualcosa di interessante — '
        'il tuo cervello inizia a registrarla come routina.',
    scienceFact: 'Phillippa Lally (UCL, 2010): l\'automaticità inizia in media '
        'tra i 18 e i 66 giorni, con il picco di crescita nelle prime settimane.',
    actions: [TutorialAction.ok],
  ),

  // ── Focus 25 sbloccato ────────────────────────────────────────────────────
  WellyDialog(
    id: 'focus_unlocked',
    mood: TutorialMood.excited,
    text: 'Hai sbloccato il Focus da 25 minuti! Il cervello umano ha un ciclo '
        'naturale di concentrazione di circa 20-30 minuti. Hai guadagnato '
        'questa abilità costruendo l\'abitudine dell\'acqua.',
    scienceFact: 'Kleitman (1963): cicli ultradiani di 90 min con picchi di '
        'attenzione da 20-30 min. Tecniche Pomodoro sfruttano questo ritmo.',
    actions: [TutorialAction.ok, TutorialAction.more],
    nextDialogId: 'focus_unlocked_2',
  ),

  WellyDialog(
    id: 'focus_unlocked_2',
    mood: TutorialMood.gentle,
    text: 'Regola d\'oro del Focus: quando il timer parte, il telefono va a '
        'faccia in giù. Anche Welly tace. La notifica che aspetti può '
        'aspettare 25 minuti — lo prometto.',
    actions: [TutorialAction.ok],
  ),

  // ── Calendario compare ────────────────────────────────────────────────────
  WellyDialog(
    id: 'calendar_appears',
    mood: TutorialMood.happy,
    text: 'Nuovo! Il calendario contestuale mostra solo le prossime ore, '
        'non l\'intera giornata. Meno cose da vedere = più spazio mentale '
        'per agire. Il futuro lontano non è ancora il tuo problema.',
    scienceFact: 'Sweller (1988): Cognitive Load Theory — meno informazioni '
        'visibili simultaneamente = migliori decisioni.',
    actions: [TutorialAction.ok],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // CAPITOLO 3 — Growth + fasi
  // ─────────────────────────────────────────────────────────────────────────

  // ── Prima visita Growth ───────────────────────────────────────────────────
  WellyDialog(
    id: 'growth_first_visit',
    mood: TutorialMood.gentle,
    text: 'Questa scheda mostra chi stai diventando, non solo cosa stai facendo. '
        'Le fasi non sono premi — sono descrizioni reali del tuo cambiamento '
        'neurologico. La scienza, non la motivazione, guida il percorso.',
    scienceFact: 'Wood & Neal (2007): l\'identità cambia quando i comportamenti '
        'diventano automatici. Identity precedes action.',
    actions: [TutorialAction.ok],
  ),

  // ── Fase 2 raggiunta ──────────────────────────────────────────────────────
  WellyDialog(
    id: 'phase2_reached',
    mood: TutorialMood.celebrating,
    text: '🌱 Fase 2: Inizio! Hai consolidato la tua prima abitudine. '
        'Il tuo cervello ha creato un automatismo reale. '
        'Ora si sblocca la schermata Habits — esplorarla è il prossimo passo.',
    scienceFact: 'Gardner (2012): automaticità = esecuzione senza intenzione '
        'conscia. Il primo automatismo è sempre il più difficile.',
    actions: [TutorialAction.ok],
  ),

  // ── Fase 3 raggiunta ──────────────────────────────────────────────────────
  WellyDialog(
    id: 'phase3_reached',
    mood: TutorialMood.celebrating,
    text: '🌿 Fase 3: Crescita! Tre abitudini consolidate. '
        'A questo punto la tua routine esiste davvero — '
        'non è più uno sforzo, è una struttura. Il più duro è alle spalle.',
    scienceFact: 'Lally et al. (2010): con 3 abitudini consolidate, '
        'la compliance a lungo termine sale significativamente rispetto a 1 sola.',
    actions: [TutorialAction.ok],
  ),

  // ── Fase 4 raggiunta ──────────────────────────────────────────────────────
  WellyDialog(
    id: 'phase4_reached',
    mood: TutorialMood.celebrating,
    text: '🌳 Fase 4: Radici. Sette abitudini assimilate — la tua routine è '
        'diventata stile di vita. La maggior parte delle persone non arriva '
        'qui. Tu l\'hai fatto con costanza, non con forza di volontà.',
    scienceFact: 'Duhigg (2012): routine consolidate richiedono quasi zero '
        'deliberazione conscia — la corteccia prefrontale delega ai gangli basali.',
    actions: [TutorialAction.ok],
  ),

  // ── Fase 5 raggiunta ──────────────────────────────────────────────────────
  WellyDialog(
    id: 'phase5_reached',
    mood: TutorialMood.celebrating,
    text: '🌸 Fioritura. Sei arrivato. Non vuol dire che finisce — vuol dire '
        'che sei diventato qualcuno che costruisce abitudini. Questo è '
        'il vero risultato. Non le singole abitudini, ma la capacità.',
    actions: [TutorialAction.ok],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // CAPITOLO 4 — Milestone di completamento
  // ─────────────────────────────────────────────────────────────────────────

  WellyDialog(
    id: 'milestone_7_days',
    mood: TutorialMood.celebrating,
    text: '7 giorni consecutivi! Sei nella fase in cui la crescita '
        'dell\'automaticità è più rapida — le prime due settimane costruiscono '
        'lo slancio critico per il mantenimento a lungo termine.',
    scienceFact: 'Gardner, Lally & Wardle (2012), British Journal of General '
        'Practice: l\'automaticità cresce più rapidamente nelle prime settimane — '
        'la consistenza iniziale è il predittore più forte del mantenimento.',
    actions: [TutorialAction.ok],
  ),

  WellyDialog(
    id: 'milestone_21_days',
    mood: TutorialMood.celebrating,
    text: '21 giorni! Il vecchio mito diceva che bastano 3 settimane per formare '
        'un\'abitudine. La verità: 21 giorni costruiscono solo il groove iniziale. '
        'Ora inizia la parte in cui diventa davvero tua.',
    scienceFact: 'Maltz (1960): il "21 giorni" era un\'osservazione chirurgica, '
        'non uno studio scientifico. Lally (2010) stima 66 gg in media.',
    actions: [TutorialAction.ok],
  ),

  WellyDialog(
    id: 'milestone_66_days',
    mood: TutorialMood.celebrating,
    text: '66 giorni! Questo è il numero magico dello studio di Phillippa Lally '
        'all\'UCL. Ufficialmente, secondo la scienza, hai formato un\'abitudine. '
        'Non la stai costruendo — la hai.',
    scienceFact: 'Lally et al. (2010), UCL: media di 66 giorni (range 18-254) '
        'per raggiungere l\'automaticità comportamentale.',
    actions: [TutorialAction.ok],
  ),

  // ─────────────────────────────────────────────────────────────────────────
  // CONTESTUALI — sempre attivi
  // ─────────────────────────────────────────────────────────────────────────

  WellyDialog(
    id: 'streak_broken',
    mood: TutorialMood.gentle,
    text: 'Nessun problema. La regola è semplice: mai saltare due giorni di '
        'fila. Oggi sei già tornato — la streak riparte da adesso. '
        'Welly non conta i giorni saltati.',
    actions: [TutorialAction.ok],
  ),

  WellyDialog(
    id: 'no_completion_3days',
    mood: TutorialMood.gentle,
    text: 'Welly è ancora qui. Nessun giudizio. Rientrare è '
        'più facile di quanto pensi — anche solo un bicchiere d\'acqua '
        'conta. Un atto minimo riattiva il loop.',
    scienceFact: 'Fogg (2020): Tiny Habits — anche un\'azione minima '
        'mantiene vivo il loop neurale dell\'abitudine.',
    actions: [TutorialAction.ok],
  ),

  WellyDialog(
    id: 'perfect_week',
    mood: TutorialMood.celebrating,
    text: 'Settimana perfetta! 7 completamenti su 7. Il tuo cervello ha '
        'ricevuto 7 segnali di rinforzo consecutivi. Dal punto di vista '
        'neurologico, questa settimana ha contato triplo.',
    scienceFact: 'Schultz et al. (1997): il sistema dopaminergico risponde '
        'alla coerenza del rinforzo — sequenze consecutive amplificano l\'effetto.',
    actions: [TutorialAction.ok],
  ),

  WellyDialog(
    id: 'rewards_first_visit',
    mood: TutorialMood.happy,
    text: 'I badge non sono punti finti. Ogni badge corrisponde a un '
        'comportamento reale che hai mantenuto per un periodo misurabile. '
        'Sono snapshot del tuo progresso, non decorazioni.',
    actions: [TutorialAction.ok],
  ),
];
