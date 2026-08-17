# BeWell — Contesto progetto per Claude Code

## Overview
App Flutter wellness/productivity per K4F. Firebase Auth, 5 lingue, companion Welly, sistema abitudini progressivo con scelte utente e sblocchi graduali.

- **GitHub**: https://github.com/Tech-K4F/bewell-app
- **Firebase**: progetto `bewell-1e64c`
- **Cartella**: `C:\progetti\bewell`

---

## Stack tecnico
- Flutter (Android principalmente)
- Firebase Auth (email/password + Google + Apple)
- Provider per state management
- SharedPreferences per persistenza locale
- `flutter analyze` deve dare 0 errori prima di ogni build

---

## Struttura `lib/`

```
l10n/
  app_localizations.dart     ← sistema i18n: BwStrings abstract + _En _It _Fr _De _Es
                               LocaleProvider, BwLocale enum, extension LocaleContext
                               context.s (listen:false), context.sL (listen:true)

providers/
  auth_provider.dart
  app_provider.dart          ← resetOnLogout(), onLoginComplete() chiama init()
                               completeActivity(id) → punti + streak + badge
  onboarding_provider.dart
  settings_provider.dart
  theme_provider.dart        ← BwStyle (card/ambient) + BwPalette (5 palette)
                               buildMaterialTheme({largeText, highContrast})
  progression_provider.dart  ← HabitState, tracking, fasi, unlock, choice pairs

models/
  habit_library.dart         ← 21 abitudini con IF-THEN rules, choicePairs (5 coppie)
                               UnlockCondition con altRequiredHabitId (OR logic)

screens/
  auth/
    splash_screen.dart
    login_screen.dart
  home/
    home_screen.dart         ← companion + water tracker + _PendingChoiceCard + _NextHabitPreview
    home_shell.dart          ← StatefulWidget, nav progressiva semantica, auto-popup scelte
  habits/
    habits_screen.dart       ← lista abitudini attive giornaliere + completion + timer focus
  onboarding/
    welly_welcome_screen.dart
  growth/
    growth_screen.dart       ← display-only: companion hero + habit rows + badge grid + _NextUnlock
  focus/
    focus_screen.dart        ← timer Pomodoro 25 min (navigato da HabitsScreen per focus_25)
  planner/planner_screen.dart
  profile/profile_screen.dart
  settings/
    settings_screen.dart
    theme_screen.dart

widgets/
  bw_scaffold.dart
  companion/
    companion_widget.dart
    companion_home_card.dart
  habits/
    habit_intro_sheet.dart   ← popup scelta coppia abitudini (HabitIntroSheet.show)
  locale_selector.dart
  debug_panel.dart           ← 7 tap companion → panel; simula giorni, reset, sblocca tutto
```

---

## Sistema i18n
- Abstract class `BwStrings` con ~210 getter tipizzati (incluse stringhe HabitIntroSheet)
- Sottoclassi `_En`, `_It`, `_Fr`, `_De`, `_Es`
- **REGOLA**: ogni stringa UI usa `context.sL.chiave` (ascolta) o `context.s.chiave` (no rebuild)
- Nuovi getter aggiunti: `habitChoiceTitle`, `habitChoiceSub`, `habitChoiceShowOther`, `habitChoiceOpen`, `habitEffortLow/Medium/High`, `lockedForNow`

---

## Sistema temi
- **BwStyle**: `card` | `ambient`
- **BwPalette**: naturaCalma | ariaFresca | notteProfonda | ambientaleAlba | ambientaleNotte (default)
- `buildMaterialTheme({bool largeText=false, bool highContrast=false})` — supporto accessibilità
- `BwPaletteData`: bg, bg2, card, cardBorder, text, textSec, textMut, primary, primaryLight, primaryText, accent, btn, btnText, nav, navBorder

---

## Companion Welly
- Nome scelto nell'onboarding, salvato in SharedPreferences `welly_name`
- Assets: `assets/images/companion/` — PNG fasi + 10 video MP4
- `DebugTrigger`: avvolge companion in home, 7 tap = apre debug panel

---

## Habit Library
21 abitudini in `habit_library.dart`. Percorso di sblocco:

```
water (starter)
  └─ focus_25        [water ≥ 3gg]        → auto-attiva, sblocca tab Habits
       └─ eyes_20_20_20 [focus_25 ≥ 7gg]
            └─ SCELTA: neck_stretch | postura   [eyes_20_20_20 ≥ 5gg]
                 └─ SCELTA: breathing_box | stretching_active
                                              [neck_stretch OR postura ≥ 7gg]
                      └─ SCELTA: walk_lunch | desk_exercise  [breathing_box ≥ 5gg, appDay≥28]
                           └─ SCELTA: focus_50 | meditation
                                └─ SCELTA: sleep_routine | nap
```

- `isStarter`: solo `water`
- `UnlockCondition`: `requiredHabitId`, `altRequiredHabitId` (OR logic), `requiredDaysCompleted`, `appDayMin`
- `choicePairs` (5 coppie in ordine): neck_stretch/postura → breathing_box/stretching_active → walk_lunch/desk_exercise → focus_50/meditation → sleep_routine/nap
- Immagini: `assets/images/habits/habit_*.jpg`
- Nomi/descrizioni abitudini tradotti via `BwStringsHabitUtils.habitName(id)` e `habitDesc(id)`

---

## Progression Provider

### Stati abitudine
```
HabitStatus: locked → available → active → sprouting → growing → consolidated → automatic
Fasi (totalDaysCompleted): Seme(0-7) → Germoglio(7-21) → Giovane(21-42) → Maturo(42-90) → Fiorente(90+)
```

### Metodi chiave
- `markCompleted(habitId)`: incrementa `daysCompleted`, setta `lastCompletedAt`, chiama `_evaluateUnlocks`
- `acceptHabit(habitId)`: attiva abitudine, cancella `isChoicePending` su entrambi gli habit della coppia
- `dismissChoice(habitId)`: cancella `isChoicePending` su entrambi (popup chiuso senza scelta — NON cancella la coppia da pendingChoicePair)
- `_evaluateUnlocks()`:
  - Non-pair: auto-attiva (`status = active`) quando condizione soddisfatta
  - Pair: setta entrambi a `available` + `isChoicePending = true`
  - OR logic: controlla `altRequiredHabitId` se il prerequisito primario non soddisfa
  - Ri-sblocco: se gemello rimasto a `available` (non scelto) e quello scelto ha ≥ 14gg → `status = active`
- `pendingChoicePair`: cerca nella lista `choicePairs` il primo dove uno dei due ha `isChoicePending = true`
- `activeHabits`: lista abitudini con status in {active, sprouting, growing, consolidated, automatic}

### Debug
- `debugSimulateDays(days)`: `_debugDayOffset += days`; `lastCompletedAt = ieri (36h fa)`; reset water prefs; chiama `_evaluateUnlocks`
- `debugResetToday()`: sposta `lastCompletedAt` di oggi a ieri; reset water prefs
- `debugUnlockAll()`: status active + daysCompleted=5 per tutte; `_debugDayOffset = 30`

---

## Nav progressiva (HomeShell)
```dart
enum NavItem { home, habits, growth, profile }

// Unlock semantico (non basato su giorno app):
_habitsUnlocked(p) = p.activeHabits.any((h) => h.id == 'focus_25')
_growthUnlocked(p) = p.totalDaysCompleted >= 14
```
- `HomeShell` è **StatefulWidget** con `addListener(_checkPendingChoice)` su `ProgressionProvider`
- `_checkPendingChoice`: quando `pendingChoicePair != null` e non c'è già un popup aperto → `HabitIntroSheet.show()`
- Tab bloccati mostrano icona lucchetto + snackbar con hint al tap
- `_buildScreens`: Home / **HabitsScreen** / GrowthScreen / ProfileScreen
  - Habits tab → `HabitsScreen` (non più FocusScreen)

---

## HabitIntroSheet
- Popup modal bottom sheet con due opzioni illustrate affiancate
- Auto-appare da `HomeShell._checkPendingChoice` quando `pendingChoicePair != null`
- Se chiuso senza scegliere (`_showOthers` → `Navigator.pop`): **non** cancella `isChoicePending`
- Il box "coming up" in home e growth rimane come **bottone persistente** (`_PendingChoiceCard`) per riaprire il popup
- Scelta effettuata (`_choose`): chiama `progression.acceptHabit(id)` → attiva + cancella pending su entrambi

---

## HabitsScreen (tab Habits)
- Lista di tutte le `activeHabits` con stato di completamento giornaliero
- **water**: read-only (tracciato in HomeScreen con 8 bicchieri)
- **focus_25**: bottone `▶ 25 min` che naviga a `FocusScreen` via `Navigator.push`
- **altre abitudini**: check circle; tap → `progression.markCompleted` + `appProvider.completeActivity`
- Completare un'abitudine assegna punti (10 fallback se ID non trovato in activities.json, altrimenti valore da JSON)

---

## GrowthScreen
- **Display-only** — nessun pulsante di completamento nelle habit rows
- Sezione "active habits": mostra stato (icona read-only) ma NON permette di completare
- Sezione `_NextUnlock`: se `pendingChoicePair != null` → bottone che apre `HabitIntroSheet`; altrimenti → preview abitudine bloccata con giorni mancanti

---

## HomeScreen (tab Home)
- Sezione "coming up": se `pendingChoicePair != null` → `_PendingChoiceCard` (bottone che apre popup); altrimenti → `_NextHabitPreview` (preview bloccata)
- Water tracker: 8 bicchieri, blocca editing dopo completamento giornaliero
- Al completamento dell'8° bicchiere: `progression.markCompleted('water')` + `appProvider.completeActivity('HYD001')`
- `ProgressionProvider.addListener(_loadData)` per aggiornamento reattivo dopo debug simulate

---

## Sistema punti (AppProvider)
- `completeActivity(activityId)`: aggiunge a `_completedToday`, incrementa `_user.points`, streak, sessioni
- Punti: letti da `activities.json` per ID; fallback 10 pt se non trovato
- Badge: verificati automaticamente dopo ogni completamento
- Streak: calcolato a ritroso su `weeklyCompletions` (chiavi = date ISO)

---

## Debug Panel
- Attivazione: 7 tap sul companion in home
- **"+N giorni"**: simula N giorni (aggiorna offset + history), poi mostra snackbar con giorno e fase corrente
- **"Reset completamenti di oggi"**: sposta lastCompletedAt di oggi a ieri, resetta acqua
- **"Sblocca abitudine"**: sblocco manuale per ogni abitudine non ancora attiva
- **"Sblocca tutto (giorno 30)"**: porta tutto allo stato attivo con 5gg completati
- **"Reset onboarding Welly"**: rimuove welly_welcomed/welly_name e naviga a `/welly-welcome`
- **"Reset tutto"**: `prefs.clear()` + `progression.resetAll()` + naviga a `/welly-welcome`
- Sezione "Stato": mostra appDayNumber, fase, totalDaysCompleted, abitudini attive, completate oggi, nav sbloccate

---

## Reset acqua
- `home_screen.dart` usa `WidgetsBindingObserver`
- `didChangeAppLifecycleState(resumed)` → chiama `_loadData()`
- `_loadData()` confronta `water_date` con oggi e resetta se diverso (reset reale, non simulabile via debug)
- `debugSimulateDays` e `debugResetToday` resettano anche `water_count` e `water_date` in prefs

---

## Flusso autenticazione
```
Splash → check welly_welcomed → /welly-welcome o /home
Login → onLoginComplete() → init() → notifyListeners()
Logout → resetOnLogout() → pushNamedAndRemoveUntil('/login')
```

---

## Bug risolti (storico sessioni)
- ✅ Logout/re-login → schermata profilo bianca
- ✅ Nav labels non traducibili (enum NavItem + switch exhaustive)
- ✅ Growth tab puntava a schermata sbagliata
- ✅ Debug panel crash navigazione
- ✅ Testi abitudini non tradotti (via BwStringsHabitUtils)
- ✅ Large text / high contrast crasha (buildMaterialTheme con params)
- ✅ Water tracker: punti, blocco dopo 8 bicchieri, feedback visivo
- ✅ Debug simulate: timestamp ieri, reactive reload in HomeScreen
- ✅ HabitIntroSheet non collegato al sistema sblocco (popup + bottone persistente)
- ✅ Nav unlock semantico (focus_25 attivo / totalDaysCompleted≥14)
- ✅ Habit non scelto nella coppia si ri-sblocca dopo 14gg del gemello
- ✅ Non-pair habits auto-attivate senza popup
- ✅ Popup scelta non riapribile dopo dismiss (fix: _showOthers non chiama dismissChoice)
- ✅ Growth screen "fa passare i giorni" (rimosso completion button, ora display-only)
- ✅ Habits tab mostra solo FocusScreen (sostituito con HabitsScreen lista completa)
- ✅ Punti non assegnati per abitudini non-water (HabitsScreen chiama completeActivity)

---

## Convenzioni codice
- Strings UI: `context.sL.chiave` nei Consumer/StatefulWidget; `s.chiave` se già si ha `final s = context.sL`
- Import l10n: `import '../../l10n/app_localizations.dart';`
- Provider: `context.read<X>()` per azioni, Consumer o `context.watch<X>()` per rebuild
- Niente `const` sulle SnackBar che usano `context.sL`
- Abitudini: nomi/descrizioni **mai** hardcoded — usare sempre `s.habitName(id)` / `s.habitDesc(id)`

---

## Comandi utili
```powershell
cd C:\progetti\bewell
flutter analyze              # deve dare 0 errori
flutter build apk --debug    # build APK test
git add -A && git commit -m "..." && git push
python check_translations.py # verifica chiavi i18n
```

---

## Prossimi step funzionali
- [ ] Notifiche acqua reali (flutter_local_notifications già in pubspec)
- [ ] Persistere `_debugDayOffset` in SharedPreferences per test tra sessioni
- [ ] Schermata dedicata per ogni abitudine (breathing timer, stretching guide, ecc.)
- [ ] Onboarding questionario (Q2, Q4, Q11, Q15...) per personalizzazione IF-THEN
- [ ] Animazione di sblocco quando una nuova abitudine diventa disponibile
- [ ] Notifiche push per reminder abitudini giornaliere
