# Changelog

Tutte le modifiche rilevanti a Be Well sono documentate in questo file.

Il formato è basato su [Keep a Changelog](https://keepachangelog.com/it/1.1.0/).
Finché l'app non viene pubblicata sugli store, tutto vive sotto **[Non
rilasciato]** — da qui in avanti, ogni versione effettivamente rilasciata
avrà la propria sezione datata con il numero di versione da `pubspec.yaml`.

## [Non rilasciato]

### Aggiunto
- Sistema di progressione basato sul consolidamento reale delle abitudini
  (non più a giorni fissi): celebrazione a schermo intero con coriandoli
  quando un'abitudine diventa automatica, seguita dalla scelta guidata
  della prossima.
- Snooze di 7 giorni per "non mi sento pronto" invece di un blocco a
  tempo indeterminato che fermava anche la valutazione di altre abitudini.
- Celebrazione dedicata alle soglie di streak (7/21/66 giorni — i numeri
  reali dello studio Lally UCL 2010), distinta dal consolidamento abitudine.
- Motivazione personalizzata nella scelta della prossima abitudine ("in
  linea con il tuo obiettivo"), quando c'è un riscontro reale con le
  risposte del questionario.
- Animazione a cascata sulle card di scelta abitudine, invece di comparire
  di scatto subito dopo una celebrazione a schermo intero.
- Haptic feedback su tap bicchiere d'acqua, completamento abitudini,
  redenzione premi, badge/achievement, navigazione nel tutorial.
- Fasi con timing reale (alza/tieni/abbassa, destra/centro/sinistra) per le
  abitudini guidate (stretching, esercizi scrivania) invece di un unico
  timer con etichetta a ripetizioni; colori per fase come nel box
  respirazione.
- Back button e "Salta" espliciti nei tour guidati del tutorial.
- Fatto scientifico collassabile nei popup tutorial (tap per espandere),
  per non appesantire ogni passo con un muro di testo.
- Empty state dedicato per la lista abitudini al giorno 1.
- Riga di prova sociale discreta nella prima schermata di benvenuto.
- Crash reporting (Firebase Crashlytics) con handler di errore globali
  (`runZonedGuarded`, `FlutterError.onError`) — prima un'eccezione non
  gestita spariva senza lasciare traccia.
- Consenso pubblicitario GDPR/UMP (UE/UK) e App Tracking Transparency
  (iOS) richiesti prima di inizializzare gli annunci.
- Funzione "Elimina account" completa (Auth + Firestore + dati locali),
  richiesta obbligatoria da Google Play e App Store.
- Flag remoti (`app_config/features` su Firestore) per spegnere/accendere
  da remoto funzioni non ancora pronte (Premium, annunci rewarded) senza
  dover rilasciare una nuova build.
- Privacy Policy e Termini di Servizio scritti e pubblicati (Firebase
  Hosting), collegati davvero dall'app (checkbox di registrazione,
  Impostazioni → Account).
- Splash screen brandizzato per Android e iOS (prima il template generico
  Flutter su iOS).
- Pipeline CI di base (analyze + test automatici ad ogni push).
- Versione locale dei dati (`schema_version`) predisposta per future
  migrazioni.

### Cambiato
- Lo sblocco delle abitudini è ora legato all'assimilazione reale
  dell'abitudine corrente, non al tempo trascorso dall'installazione.
- Narrativa del tutorial riscritta in tutte le 5 lingue per coerenza:
  niente più claim falsi ("hai sbloccato la schermata Habits", sempre
  accessibile), pacing "senza fretta, senza pressione" esplicito.
- Card "in arrivo" della Home allineata a quella di Habits (nessun
  countdown a giorni fissi, coerente col nuovo sistema di sblocco).
- Font "DM Sans" reso reale tramite `google_fonts` in tutto lo stile Card
  dell'app.
- Aspetto della bolla del tutorial allineato al linguaggio visivo del
  resto dell'app (superficie card invece di sfondo pagina, bordo sottile,
  colore testo secondario) e Welly (companion video) al posto di un'icona
  statica, sia nel tutorial sia nella celebrazione di consolidamento.
- Testo delle notifiche riscritto: ogni fascia oraria ha un messaggio
  concreto e diverso (mattina/metà mattina/pranzo/pomeriggio/sera) invece
  di un unico messaggio generico ripetuto identico più volte al giorno.
- Bottone "Be Well Premium" nascosto finché non è collegato un sistema di
  pagamento reale.
- Card annuncio rewarded nascosta in release finché l'ID pubblicitario non
  è reale (poi riattivata con gli ID di produzione veri).

### Corretto
- Notifica "bevi acqua" che arrivava duplicata in due lingue
  contemporaneamente.
- Vicolo cieco nella registrazione email/password: dopo aver completato
  il questionario post-verifica email, l'utente restava bloccato su una
  schermata vuota invece di arrivare in Home.
- Sottolineatura gialla doppia nei popup del tutorial (mancava un widget
  `Material` come antenato — bug noto di Flutter).
- Bottoni "Ho capito"/"Di più" indistinguibili nelle catene di dialoghi
  concatenati (entrambi avanzavano, "Ho capito" non chiudeva mai nulla).
- Tap che attraversava l'overlay scurito del tutorial arrivando alla UI
  reale sottostante invece di essere assorbito.
- Saluto in Home sempre "Buongiorno" a qualunque ora del giorno.
- Blocco anti tentativi di login ripetuti azzerato al riavvio dell'app
  (viveva solo in memoria, non su storage persistente).
- Tutorial mostrato per un istante in inglese prima di passare alla lingua
  corretta (race condition: `LocaleProvider` partiva con l'inglese di
  default mentre leggeva la lingua salvata in background).
- Font "DM Sans" mai incluso come asset: l'app ricadeva silenziosamente
  sul font di sistema in tutto lo stile Card.

### Sicurezza
- Aggiunta la regola Firestore che permette esplicitamente la
  cancellazione del proprio documento utente (mancava: la regola di
  scrittura generica non copriva le delete, l'eliminazione account non
  avrebbe mai davvero ripulito Firestore).
- Aggiunta regola di lettura pubblica per `app_config/features` (i flag
  remoti), scrittura sempre negata dal client.
