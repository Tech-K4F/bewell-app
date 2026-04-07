// ─────────────────────────────────────────────────────────────────────────────
//  BeWell — Habit Library
//  Catalogo completo delle abitudini con metadati, prerequisiti e regole
//  IF-THEN integrate dal documento BeWell_IF_THEN_Rules.xlsx
// ─────────────────────────────────────────────────────────────────────────────

enum HabitCategory {
  hydration,    // Idratazione
  focus,        // Concentrazione
  eyes,         // Occhi & postura
  breathing,    // Respiro & mente
  movement,     // Movimento
  sleep,        // Sonno & recupero
  nutrition,    // Nutrizione
}

enum HabitEffort {
  low,     // 1 — facile, nessun cambiamento strutturale
  medium,  // 2 — richiede un po' di organizzazione
  high,    // 3 — cambiamento comportamentale significativo
}

/// Condizione di sblocco basata sul comportamento dell'utente
class UnlockCondition {
  /// ID dell'abitudine prerequisita (null = nessun prerequisito)
  final String? requiredHabitId;
  /// Giorni cumulativi completati del prerequisito prima di sbloccare
  final int requiredDaysCompleted;
  /// Giorno dall'installazione dell'app (alternativo al prerequisito)
  final int? appDayMin;

  const UnlockCondition({
    this.requiredHabitId,
    this.requiredDaysCompleted = 0,
    this.appDayMin,
  });
}

/// Regola di personalizzazione IF-THEN
class IfThenRule {
  final String questionId;  // es. 'Q2', 'Q4', 'Q17'
  final String answerValue; // es. 'From home', '5 – Very high'
  final String effect;      // effetto specifico da applicare

  const IfThenRule({
    required this.questionId,
    required this.answerValue,
    required this.effect,
  });
}

class HabitDefinition {
  final String id;
  final String name;
  final String description;
  final String coachIntro;      // Messaggio quando viene introdotta
  final String coachDaily;      // Messaggio giornaliero tipo
  final HabitCategory category;
  final HabitEffort effort;
  final String imageAsset;      // path in assets/images/habits/
  final UnlockCondition unlock;
  final int defaultFrequencyMinutes; // ogni quanti minuti il reminder
  final List<IfThenRule> ifThenRules;
  final bool isStarter;         // true = disponibile dal giorno 1

  const HabitDefinition({
    required this.id,
    required this.name,
    required this.description,
    required this.coachIntro,
    required this.coachDaily,
    required this.category,
    required this.effort,
    required this.imageAsset,
    required this.unlock,
    required this.defaultFrequencyMinutes,
    this.ifThenRules = const [],
    this.isStarter = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
//  CATALOGO COMPLETO
// ─────────────────────────────────────────────────────────────────────────────
class HabitLibrary {
  static const List<HabitDefinition> all = [

    // ── FASE 0: Starter — disponibili dal giorno 1 ───────────────────────────

    HabitDefinition(
      id: 'water',
      name: 'Bevi acqua',
      description: '8 bicchieri d\'acqua durante la giornata',
      coachIntro:
          'Iniziamo da qui. Un bicchiere ogni ora e mezza. '
          'Sembra poco — ma è già un cambiamento reale.',
      coachDaily: 'L\'acqua è la base di tutto il resto.',
      category: HabitCategory.hydration,
      effort: HabitEffort.low,
      imageAsset: 'assets/images/habits/habit_water.jpg',
      unlock: UnlockCondition(appDayMin: 0),
      defaultFrequencyMinutes: 90,
      isStarter: true,
      ifThenRules: [
        // Q16: se beve già poco → reminder ogni 45 min
        IfThenRule(
          questionId: 'Q16',
          answerValue: '<1L',
          effect: 'frequency_45min',
        ),
        // Q16: se beve già >2L → minimal reminders
        IfThenRule(
          questionId: 'Q16',
          answerValue: '>2L',
          effect: 'frequency_minimal',
        ),
        // Q3: obiettivo "develop healthy habits" → streak system attivo
        IfThenRule(
          questionId: 'Q3',
          answerValue: 'Develop healthy habits',
          effect: 'enable_streak_celebration',
        ),
      ],
    ),

    // ── FASE 1: Giorno 4 — dopo 3 giorni di acqua ───────────────────────────

    HabitDefinition(
      id: 'focus_25',
      name: 'Sessione focus 25 min',
      description: 'Una sessione Pomodoro da 25 minuti senza distrazioni',
      coachIntro:
          'Hai sviluppato la tua prima abitudine. '
          'Pronto per la seconda? Imposta 25 minuti. '
          'Niente telefono, niente notifiche. Solo tu e il lavoro.',
      coachDaily: 'Anche una sola sessione oggi fa la differenza.',
      category: HabitCategory.focus,
      effort: HabitEffort.medium,
      imageAsset: 'assets/images/habits/habit_focus_25.jpg',
      unlock: UnlockCondition(
        requiredHabitId: 'water',
        requiredDaysCompleted: 3,
      ),
      defaultFrequencyMinutes: 0, // on-demand, non reminder automatico
      ifThenRules: [
        // Q21: focus <25 min → sessioni da 15 min
        IfThenRule(
          questionId: 'Q21',
          answerValue: '15-25 min',
          effect: 'timer_preset_15min',
        ),
        // Q21: focus 45-60 min → sblocca sessione lunga prima
        IfThenRule(
          questionId: 'Q21',
          answerValue: '45-60 min',
          effect: 'suggest_upgrade_to_focus_50',
        ),
        // Q4: stress alto → riduce sessioni a 20 min
        IfThenRule(
          questionId: 'Q4',
          answerValue: '4 – High',
          effect: 'timer_preset_20min',
        ),
        // Q19: distrazioni telefono → suggerisce DND
        IfThenRule(
          questionId: 'Q19',
          answerValue: 'Phone notifications',
          effect: 'suggest_dnd_mode',
        ),
      ],
    ),

    // ── FASE 2: Settimana 3 — dopo 7 giorni di focus ────────────────────────

    HabitDefinition(
      id: 'eyes_20_20_20',
      name: 'Regola 20-20-20',
      description:
          'Ogni 20 minuti, guarda a 6 metri di distanza per 20 secondi',
      coachIntro:
          'I tuoi occhi lavorano sodo. '
          'Ogni 20 minuti, stacca dallo schermo per 20 secondi. '
          'Guarda fuori dalla finestra.',
      coachDaily: 'I tuoi occhi ti ringrazieranno stasera.',
      category: HabitCategory.eyes,
      effort: HabitEffort.low,
      imageAsset: 'assets/images/habits/habit_eyes_20_20_20.jpg',
      unlock: UnlockCondition(
        requiredHabitId: 'focus_25',
        requiredDaysCompleted: 7,
      ),
      defaultFrequencyMinutes: 20,
      ifThenRules: [
        // Q17: screen time >8h → reminder ogni 20 min obbligatorio
        IfThenRule(
          questionId: 'Q17',
          answerValue: '8-10h',
          effect: 'frequency_mandatory_20min',
        ),
        IfThenRule(
          questionId: 'Q17',
          answerValue: '>10h',
          effect: 'frequency_mandatory_20min_critical',
        ),
        // Q17: screen time <4h → reminder ogni 30 min
        IfThenRule(
          questionId: 'Q17',
          answerValue: '<4h',
          effect: 'frequency_30min',
        ),
      ],
    ),

    // ── FASE 2: Settimana 4 — dopo 5 giorni 20-20-20 ────────────────────────

    HabitDefinition(
      id: 'neck_stretch',
      name: 'Stretching collo e spalle',
      description: '2 minuti di stretching collo e spalle ogni ora',
      coachIntro:
          'Collo e spalle accumulano tensione senza che te ne accorga. '
          'Due minuti sono sufficienti per resettare tutto.',
      coachDaily: 'Abbassa le spalle. Respira. Ruota il collo.',
      category: HabitCategory.eyes,
      effort: HabitEffort.low,
      imageAsset: 'assets/images/habits/habit_neck_stretch.jpg',
      unlock: UnlockCondition(
        requiredHabitId: 'eyes_20_20_20',
        requiredDaysCompleted: 5,
      ),
      defaultFrequencyMinutes: 60,
      ifThenRules: [
        // Q2: lavora in ufficio → reminder discreto (no audio)
        IfThenRule(
          questionId: 'Q2',
          answerValue: 'Office/University',
          effect: 'silent_notification',
        ),
      ],
    ),

    // ── FASE 3: Settimana 5 — dopo 7 giorni stretching ──────────────────────

    HabitDefinition(
      id: 'breathing_box',
      name: 'Respirazione box',
      description: '4 secondi inspira, 4 trattieni, 4 espira, 4 trattieni',
      coachIntro:
          'Hai iniziato a concentrarti. Adesso impara a recuperare. '
          'La respirazione box in 4 minuti resetta il sistema nervoso.',
      coachDaily: 'Un respiro consapevole cambia la chimica del tuo corpo.',
      category: HabitCategory.breathing,
      effort: HabitEffort.low,
      imageAsset: 'assets/images/habits/habit_breathing_box.jpg',
      unlock: UnlockCondition(
        requiredHabitId: 'neck_stretch',
        requiredDaysCompleted: 7,
      ),
      defaultFrequencyMinutes: 120,
      ifThenRules: [
        // Q4: stress molto alto → diventa priorità assoluta
        IfThenRule(
          questionId: 'Q4',
          answerValue: '5 – Very high',
          effect: 'priority_mandatory_every_45min',
        ),
        IfThenRule(
          questionId: 'Q4',
          answerValue: '4 – High',
          effect: 'priority_every_90min',
        ),
        // Q3: obiettivo reduce stress → evidenziata in home
        IfThenRule(
          questionId: 'Q3',
          answerValue: 'Reduce stress',
          effect: 'highlight_in_home',
        ),
      ],
    ),

    // ── FASE 3: Settimana 6 — scelta utente (popup) ──────────────────────────
    // Proposta come prima scelta visuale: walk_lunch vs desk_exercise

    HabitDefinition(
      id: 'walk_lunch',
      name: 'Passeggiata pausa pranzo',
      description: 'Una camminata di 15 minuti durante la pausa pranzo',
      coachIntro:
          'Già cammini? Non ancora. È il momento. '
          '15 minuti fuori cambiano l\'intera seconda metà della giornata.',
      coachDaily: 'Esci. Anche solo 10 minuti. Il resto può aspettare.',
      category: HabitCategory.movement,
      effort: HabitEffort.medium,
      imageAsset: 'assets/images/habits/habit_walk_lunch.jpg',
      unlock: UnlockCondition(
        requiredHabitId: 'breathing_box',
        requiredDaysCompleted: 5,
        appDayMin: 28, // minimo 4 settimane nell'app
      ),
      defaultFrequencyMinutes: 0, // triggered da pranzo
      ifThenRules: [
        // Q11: parco <5 min → suggerita frequentemente
        IfThenRule(
          questionId: 'Q11',
          answerValue: 'Yes – <5 min',
          effect: 'suggest_daily',
        ),
        // Q11: parco >15 min → solo per pause lunghe
        IfThenRule(
          questionId: 'Q11',
          answerValue: 'Yes – 5-15 min',
          effect: 'suggest_only_long_breaks',
        ),
        // Q11: nessun parco → sostituisce con desk_exercise
        IfThenRule(
          questionId: 'Q11',
          answerValue: 'No',
          effect: 'replace_with_indoor_alternative',
        ),
        // Q9: 30 min pranzo → scorciatoia 10 min
        IfThenRule(
          questionId: 'Q9',
          answerValue: '30 minutes',
          effect: 'shorten_to_10min',
        ),
      ],
    ),

    HabitDefinition(
      id: 'desk_exercise',
      name: 'Esercizi alla scrivania',
      description: 'Stretching attivo di 5 minuti ogni 2 ore',
      coachIntro:
          'Non serve alzarsi. Basta sedersi diversamente per 5 minuti. '
          'Braccia, schiena, gambe — tutto si può muovere da qui.',
      coachDaily: 'Piccoli movimenti, grande differenza.',
      category: HabitCategory.movement,
      effort: HabitEffort.low,
      imageAsset: 'assets/images/habits/habit_desk_exercise.jpg',
      unlock: UnlockCondition(
        requiredHabitId: 'breathing_box',
        requiredDaysCompleted: 5,
        appDayMin: 28,
      ),
      defaultFrequencyMinutes: 120,
      ifThenRules: [
        // Q2: lavoro da casa → reminder ogni 2h (rischio sedentarietà)
        IfThenRule(
          questionId: 'Q2',
          answerValue: 'From home',
          effect: 'frequency_120min_mandatory',
        ),
      ],
    ),

    // ── FASE 4: Settimana 7-8 ────────────────────────────────────────────────

    HabitDefinition(
      id: 'water_morning',
      name: 'Acqua appena svegli',
      description: 'Un bicchiere d\'acqua come prima cosa al mattino',
      coachIntro:
          'Il tuo corpo è disidratato dopo 8 ore di sonno. '
          'Un bicchiere d\'acqua prima di tutto il resto.',
      coachDaily: 'Prima dell\'acqua non esiste il caffè.',
      category: HabitCategory.hydration,
      effort: HabitEffort.low,
      imageAsset: 'assets/images/habits/habit_water_morning.jpg',
      unlock: UnlockCondition(
        requiredHabitId: 'water',
        requiredDaysCompleted: 14,
      ),
      defaultFrequencyMinutes: 0, // solo mattina
    ),

    HabitDefinition(
      id: 'posture',
      name: 'Check postura',
      description: 'Controlla e correggi la postura ogni ora',
      coachIntro:
          'Ogni ora, fai una pausa di 10 secondi. '
          'Spalle giù, schiena dritta, piedi a terra.',
      coachDaily: 'La postura non si corregge una volta. Si mantiene.',
      category: HabitCategory.eyes,
      effort: HabitEffort.medium,
      imageAsset: 'assets/images/habits/habit_posture.jpg',
      unlock: UnlockCondition(
        requiredHabitId: 'neck_stretch',
        requiredDaysCompleted: 10,
      ),
      defaultFrequencyMinutes: 60,
      ifThenRules: [
        IfThenRule(
          questionId: 'Q2',
          answerValue: 'Office/University',
          effect: 'silent_notification',
        ),
      ],
    ),

    HabitDefinition(
      id: 'lunch_park',
      name: 'Pranzo al parco',
      description: 'Mangia fuori, all\'aperto, senza schermo',
      coachIntro:
          'Già cammini. E se ci mangiassi anche? '
          'Il parco non è solo un posto — è una pausa vera.',
      coachDaily: 'L\'aria aperta durante il pranzo vale più di qualsiasi integratore.',
      category: HabitCategory.movement,
      effort: HabitEffort.medium,
      imageAsset: 'assets/images/habits/habit_lunch_park.jpg',
      unlock: UnlockCondition(
        requiredHabitId: 'walk_lunch',
        requiredDaysCompleted: 7,
      ),
      defaultFrequencyMinutes: 0,
      ifThenRules: [
        IfThenRule(
          questionId: 'Q11',
          answerValue: 'No',
          effect: 'hide_habit', // non proporre se non c'è parco
        ),
        IfThenRule(
          questionId: 'Q9',
          answerValue: '30 minutes',
          effect: 'hide_habit', // non proporre con pausa corta
        ),
      ],
    ),

    // ── FASE 5: Mese 2 ──────────────────────────────────────────────────────

    HabitDefinition(
      id: 'breathing_478',
      name: 'Respirazione 4-7-8',
      description: 'Tecnica anti-ansia: inspira 4s, trattieni 7s, espira 8s',
      coachIntro:
          'Quando il box breathing non basta, c\'è il 4-7-8. '
          'Attiva il sistema parasimpatico in meno di 2 minuti.',
      coachDaily: 'La respirazione 4-7-8 è un sedativo naturale.',
      category: HabitCategory.breathing,
      effort: HabitEffort.low,
      imageAsset: 'assets/images/habits/habit_breathing_478.jpg',
      unlock: UnlockCondition(
        requiredHabitId: 'breathing_box',
        requiredDaysCompleted: 14,
      ),
      defaultFrequencyMinutes: 0, // on-demand o dopo stress check
      ifThenRules: [
        IfThenRule(
          questionId: 'Q4',
          answerValue: '5 – Very high',
          effect: 'unlock_immediately_skip_prerequisite',
        ),
        IfThenRule(
          questionId: 'Q4',
          answerValue: '4 – High',
          effect: 'suggest_after_each_meeting',
        ),
      ],
    ),

    HabitDefinition(
      id: 'stretching_active',
      name: 'Stretching attivo 5 min',
      description: 'Cinque minuti di movimento globale del corpo',
      coachIntro:
          'Non è ginnastica. È solo ricordare al corpo che esiste. '
          'Cinque minuti, due volte al giorno.',
      coachDaily: 'Muoviti prima di sederti. Muoviti prima di dormire.',
      category: HabitCategory.movement,
      effort: HabitEffort.low,
      imageAsset: 'assets/images/habits/habit_stretching_active.jpg',
      unlock: UnlockCondition(
        requiredHabitId: 'desk_exercise',
        requiredDaysCompleted: 10,
      ),
      defaultFrequencyMinutes: 240,
    ),

    HabitDefinition(
      id: 'snack',
      name: 'Spuntino sano',
      description: 'Un piccolo spuntino nutriente a metà mattina',
      coachIntro:
          'Il crollo di energia alle 11 non è stanchezza. '
          'È glucosio basso. Uno spuntino cambia le prossime 3 ore.',
      coachDaily: 'Frutta, noci, yogurt. Semplice.',
      category: HabitCategory.nutrition,
      effort: HabitEffort.low,
      imageAsset: 'assets/images/habits/habit_snack.jpg',
      unlock: UnlockCondition(
        appDayMin: 21,
        requiredHabitId: 'water',
        requiredDaysCompleted: 14,
      ),
      defaultFrequencyMinutes: 0,
    ),

    HabitDefinition(
      id: 'lunch_no_screen',
      name: 'Pranzo senza schermo',
      description: 'Il pranzo lontano da telefono e computer',
      coachIntro:
          'Il cervello non si riposa se continua a elaborare immagini. '
          'Mangia. Solo mangia.',
      coachDaily: 'Il pasto è già un\'attività. Non serve un\'altra.',
      category: HabitCategory.nutrition,
      effort: HabitEffort.medium,
      imageAsset: 'assets/images/habits/habit_lunch_no_screen.jpg',
      unlock: UnlockCondition(
        appDayMin: 28,
        requiredHabitId: 'snack',
        requiredDaysCompleted: 7,
      ),
      defaultFrequencyMinutes: 0,
    ),

    // ── FASE 6: Mese 3 ──────────────────────────────────────────────────────

    HabitDefinition(
      id: 'focus_50',
      name: 'Focus profondo 50 min',
      description: 'Una sessione di lavoro profondo senza interruzioni',
      coachIntro:
          'Sei pronto per il passo successivo. '
          '50 minuti di concentrazione totale. '
          'Il cervello impara a entrare in stato di flusso.',
      coachDaily: 'Il lavoro profondo è un muscolo. Si allena.',
      category: HabitCategory.focus,
      effort: HabitEffort.high,
      imageAsset: 'assets/images/habits/habit_focus_50.jpg',
      unlock: UnlockCondition(
        requiredHabitId: 'focus_25',
        requiredDaysCompleted: 21,
      ),
      defaultFrequencyMinutes: 0,
      ifThenRules: [
        IfThenRule(
          questionId: 'Q4',
          answerValue: '4 – High',
          effect: 'delay_unlock_one_week',
        ),
        IfThenRule(
          questionId: 'Q4',
          answerValue: '5 – Very high',
          effect: 'hide_habit',
        ),
      ],
    ),

    HabitDefinition(
      id: 'meditation',
      name: 'Micro-meditazione 3 min',
      description: '3 minuti di presenza consapevole, ovunque tu sia',
      coachIntro:
          'Non hai bisogno di un cuscino zen. '
          'Tre minuti di silenzio interiore, anche alla scrivania.',
      coachDaily: 'Il pensiero non si ferma. Ma puoi smettere di inseguirlo.',
      category: HabitCategory.breathing,
      effort: HabitEffort.medium,
      imageAsset: 'assets/images/habits/habit_meditation.jpg',
      unlock: UnlockCondition(
        requiredHabitId: 'breathing_478',
        requiredDaysCompleted: 14,
      ),
      defaultFrequencyMinutes: 0,
      ifThenRules: [
        // Q14: ha spazio quieto al lavoro → suggerita durante pause
        IfThenRule(
          questionId: 'Q14',
          answerValue: 'Yes – at work',
          effect: 'suggest_during_work_breaks',
        ),
        IfThenRule(
          questionId: 'Q14',
          answerValue: 'No',
          effect: 'use_open_eyes_variant',
        ),
      ],
    ),

    HabitDefinition(
      id: 'stairs',
      name: 'Scala invece dell\'ascensore',
      description: 'Scegli le scale ogni volta che puoi',
      coachIntro:
          'Non è fitness. È semplicemente scegliere il percorso più lungo. '
          'Ogni volta che puoi.',
      coachDaily: 'Le scale non finiscono mai troppo presto.',
      category: HabitCategory.movement,
      effort: HabitEffort.low,
      imageAsset: 'assets/images/habits/habit_stairs.jpg',
      unlock: UnlockCondition(
        requiredHabitId: 'walk_lunch',
        requiredDaysCompleted: 14,
      ),
      defaultFrequencyMinutes: 0,
      ifThenRules: [
        IfThenRule(
          questionId: 'Q2',
          answerValue: 'From home',
          effect: 'hide_habit', // non rilevante se lavora da casa
        ),
      ],
    ),

    HabitDefinition(
      id: 'sleep_routine',
      name: 'Routine pre-sonno',
      description: '30 minuti senza schermi prima di dormire',
      coachIntro:
          'Il sonno si prepara un\'ora prima. '
          'Schermo spento 30 minuti prima di dormire. '
          'Il resto viene da sé.',
      coachDaily: 'La notte inizia la sera. Non a mezzanotte.',
      category: HabitCategory.sleep,
      effort: HabitEffort.high,
      imageAsset: 'assets/images/habits/habit_sleep_routine.jpg',
      unlock: UnlockCondition(
        appDayMin: 42, // 6 settimane
        requiredHabitId: 'breathing_box',
        requiredDaysCompleted: 21,
      ),
      defaultFrequencyMinutes: 0,
      ifThenRules: [
        IfThenRule(
          questionId: 'Q15',
          answerValue: '<5h',
          effect: 'unlock_immediately_priority',
        ),
        IfThenRule(
          questionId: 'Q15',
          answerValue: '5-6h',
          effect: 'unlock_week_3_instead_of_6',
        ),
      ],
    ),

    HabitDefinition(
      id: 'wake_consistent',
      name: 'Sveglia costante',
      description: 'Alzati sempre alla stessa ora, anche il weekend',
      coachIntro:
          'Il jet lag sociale è reale. '
          'Alzarsi alla stessa ora ogni giorno è il singolo intervento '
          'più potente per il ritmo circadiano.',
      coachDaily: 'Stessa ora. Ogni giorno. Il corpo impara in fretta.',
      category: HabitCategory.sleep,
      effort: HabitEffort.high,
      imageAsset: 'assets/images/habits/habit_wake_consistent.jpg',
      unlock: UnlockCondition(
        requiredHabitId: 'sleep_routine',
        requiredDaysCompleted: 14,
      ),
      defaultFrequencyMinutes: 0,
    ),

    HabitDefinition(
      id: 'nap',
      name: 'Power nap 20 min',
      description: 'Un riposo breve e intenzionale nel pomeriggio',
      coachIntro:
          'Non è pigrizia. È recupero attivo. '
          'Venti minuti, non di più. Il timer è fondamentale.',
      coachDaily: 'Il pomeriggio riparte dopo il nap, non dopo il caffè.',
      category: HabitCategory.sleep,
      effort: HabitEffort.medium,
      imageAsset: 'assets/images/habits/habit_nap.jpg',
      unlock: UnlockCondition(
        appDayMin: 56, // 2 mesi
        requiredHabitId: 'sleep_routine',
        requiredDaysCompleted: 7,
      ),
      defaultFrequencyMinutes: 0,
      ifThenRules: [
        IfThenRule(
          questionId: 'Q9',
          answerValue: '1 hour',
          effect: 'suggest_daily',
        ),
        IfThenRule(
          questionId: 'Q9',
          answerValue: '30 minutes',
          effect: 'hide_habit',
        ),
      ],
    ),

    HabitDefinition(
      id: 'focus_no_phone',
      name: 'Focus senza telefono',
      description: 'Telefono capovolto o in un\'altra stanza durante il focus',
      coachIntro:
          'Il telefono non deve essere visibile. '
          'La sola presenza dello schermo riduce la concentrazione del 20%.',
      coachDaily: 'Fuori dalla vista, fuori dalla mente.',
      category: HabitCategory.focus,
      effort: HabitEffort.medium,
      imageAsset: 'assets/images/habits/habit_focus_no_phone.jpg',
      unlock: UnlockCondition(
        requiredHabitId: 'focus_25',
        requiredDaysCompleted: 10,
      ),
      defaultFrequencyMinutes: 0,
      ifThenRules: [
        IfThenRule(
          questionId: 'Q19',
          answerValue: 'Phone notifications',
          effect: 'unlock_immediately_skip_prerequisite',
        ),
        IfThenRule(
          questionId: 'Q19',
          answerValue: 'Social media',
          effect: 'unlock_immediately_skip_prerequisite',
        ),
      ],
    ),
  ];

  /// Restituisce solo le abitudini disponibili dal giorno 1
  static List<HabitDefinition> get starters =>
      all.where((h) => h.isStarter).toList();

  /// Restituisce le abitudini per categoria
  static List<HabitDefinition> byCategory(HabitCategory cat) =>
      all.where((h) => h.category == cat).toList();

  /// Trova un'abitudine per ID
  static HabitDefinition? findById(String id) {
    try {
      return all.firstWhere((h) => h.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Restituisce le coppie di scelta per il popup introduttivo
  /// (due abitudini della stessa categoria con lo stesso unlock prerequisito)
  static List<(HabitDefinition, HabitDefinition)> get choicePairs => [
    // Scelta 1: Movimento dopo breathing_box
    (
      findById('walk_lunch')!,
      findById('desk_exercise')!,
    ),
    // Scelta 2: Focus avanzato vs Meditazione
    (
      findById('focus_50')!,
      findById('meditation')!,
    ),
    // Scelta 3: Sonno
    (
      findById('sleep_routine')!,
      findById('nap')!,
    ),
  ];
}
