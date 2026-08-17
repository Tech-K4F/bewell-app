# BeWell — Brief V4: Marketplace Completo
# Da leggere DOPO CONTEXT.md, BeWell_ProductBrief.md, V2 e V3
# Questo documento specifica il marketplace completo con 3 tab

---

## IMPORTANTE
Leggi prima CONTEXT.md, BeWell_ProductBrief.md, BeWell_Brief_V2.md,
BeWell_Brief_V3.md. Questo documento aggiunge il marketplace completo.
Non toccare file non menzionati qui.
Dopo ogni task: flutter analyze → 0 errori → dimmi cosa hai fatto.

---

## 1. STRUTTURA MARKETPLACE — 3 TAB

Il marketplace esistente va completamente ristrutturato.
File: lib/screens/marketplace/marketplace_screen.dart

La schermata ha:
- Header con titolo "i tuoi premi" in stile ambient (Georgia italic)
- Striscia punti disponibili sempre visibile
- 3 tab: Premi | Sconti | In-app
- Contenuto diverso per ogni tab

### Header
```dart
// Eyebrow: "marketplace" — teal, uppercase, 9px, letter-spacing
// Titolo: "i tuoi premi" — Georgia italic, 16px
// Nessun AppBar — header inline come altre schermate
```

### Striscia punti
```dart
Container(
  margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
  padding: EdgeInsets.symmetric(horizontal: 11, vertical: 9),
  decoration: BoxDecoration(
    color: p.card,
    borderRadius: BorderRadius.circular(11),
    border: Border.all(color: p.cardBorder, width: 0.5),
  ),
  child: Row(children: [
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('${user.points}', style: /* 18px, amber, Georgia */),
      Text(s.pointsAvailable, style: /* 10px, textSec */),
    ]),
    Spacer(),
    Text('⭐', style: TextStyle(fontSize: 18)),
  ]),
)
```

### Tab bar
```dart
// 3 tab: s.marketplaceTabRewards | s.marketplaceTabDiscounts | s.marketplaceTabInApp
// Stile: sfondo bg2, tab attiva sfondo card con ombra leggera
// Bordo radius 10px
```

---

## 2. TAB 1 — PREMI CON PUNTI

Mostra i premi riscattabili con i punti. Dati da RewardModel già esistente.

### Struttura
```
[sec label: "da riscattare"]
[lista RewardCard]
[RewardedAdCard — in fondo]
```

### RewardCard
```dart
// Row con:
// - Immagine/emoji 38px, border radius 10px, sfondo colorato per categoria
// - Info: nome, brand, tipo (voucher/sconto/experience)
// - Pulsante "X pt" — teal background se punti sufficienti, grigio se no
// Tap → bottom sheet conferma → riscatto con ProgressionProvider.redeemReward()
```

Colori icona per categoria:
```dart
Map<String, Color> categoryColors = {
  'Food & Drink':    teal-light,
  'Sport & Fitness': amber-light,
  'Benessere':       purple-light,
  'Cultura':         blue-light,
  'Shopping':        gray-light,
};
```

### Bottom sheet riscatto
```dart
// Titolo: "Sei sicuro?"
// Testo: "Verranno scalati X punti dal tuo saldo."
// Pulsanti: Annulla | Conferma
// Dopo conferma:
//   1. Animazione punti che salgono e spariscono (500ms)
//   2. Codice con effetto reveal
//   3. Testo Welly: s.rewardRedeemed ("Eccolo. Te lo sei guadagnato.")
//   4. Pulsante "Copia codice" grande
```

### RewardedAdCard (in fondo alla lista)
```dart
Container(
  margin: EdgeInsets.fromLTRB(10, 8, 10, 0),
  padding: EdgeInsets.all(11),
  decoration: BoxDecoration(
    color: p.card,
    borderRadius: BorderRadius.circular(11),
    border: Border.all(color: p.cardBorder, width: 0.5),
  ),
  child: Column(children: [
    Row(children: [
      // icona play in cerchio teal-light
      // "Aiuta Be Well" + "Guadagna 10 pt guardando uno spot"
    ]),
    SizedBox(height: 7),
    Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(s.watchAd, /* "Guarda uno spot · +10 pt" — teal */),
        GestureDetector(
          onTap: () => _showWhyDialog(context),
          child: Text(s.whyAds, /* "perché?" — textSec, underline */),
        ),
      ],
    ),
  ]),
)
```

Dialog "perché?":
```dart
// Titolo: s.whyAdsTitle ("Be Well è gratuita per tutti")
// Corpo: s.whyAdsBody
// "Be Well è un'app gratuita per essere accessibile a chiunque.
//  Come ogni servizio, ha costi di gestione. Guardando le inserzioni
//  quando puoi, ci aiuti a tenere il servizio attivo e migliorarlo
//  per tutti. Grazie davvero."
// Pulsante: "Capito" — chiude
```

Implementazione AdMob rewarded:
```dart
// Usare RewardedAd da google_mobile_ads package
// Aggiungere google_mobile_ads: ^5.x.x in pubspec.yaml
// Ad unit ID: usare ID di test durante sviluppo
//   Android test ID: 'ca-app-pub-3940256099942544/5224354917'
// Dopo visione completa: progression.addPoints(10) + AnalyticsService.logAdWatched()
// Se ad non disponibile: mostrare toast "Spot non disponibile al momento"
```

---

## 3. TAB 2 — SCONTI ESCLUSIVI

Sconti Awin negoziati — gratuiti, nessun punto richiesto.
Dati: lista statica hardcodata inizialmente, poi da remote config.

### Struttura
```
[sec label: "sconti attivi"]
[lista DiscountCard]
[nota in fondo: "Gli sconti sono aggiornati ogni mese. Nessun punto richiesto."]
```

### Modello dati (nuovo)
```dart
class BwDiscount {
  final String id;
  final String brandName;
  final String description;     // es. "-15% su tutto"
  final String code;            // es. "BEWELL15"
  final String categoryEmoji;
  final String url;             // link affiliato Awin
  final String exclusiveLabel;  // es. "esclusivo Be Well"
  final Color bgColor;

  const BwDiscount({...});
}
```

Creare file: lib/models/discount_model.dart

### Lista sconti iniziale (hardcodata)
```dart
static const List<BwDiscount> all = [
  BwDiscount(
    id: 'myprotein',
    brandName: 'MyProtein',
    description: '-15% su tutto',
    code: 'BEWELL15',
    categoryEmoji: '💪',
    url: 'https://www.myprotein.com', // sostituire con link Awin reale
    exclusiveLabel: 'esclusivo Be Well',
    bgColor: teal-light,
  ),
  BwDiscount(
    id: 'decathlon',
    brandName: 'Decathlon',
    description: '-10% su tutto il catalogo',
    code: 'BEWELL10',
    categoryEmoji: '🏊',
    url: 'https://www.decathlon.it',
    exclusiveLabel: 'esclusivo Be Well',
    bgColor: amber-light,
  ),
  BwDiscount(
    id: 'iherb',
    brandName: 'iHerb',
    description: '-20% integratori naturali',
    code: 'BEWELL20',
    categoryEmoji: '🌿',
    url: 'https://www.iherb.com',
    exclusiveLabel: 'esclusivo Be Well',
    bgColor: teal-light,
  ),
  BwDiscount(
    id: 'yogi_tea',
    brandName: 'Yogi Tea',
    description: '-10% tisane biologiche',
    code: 'BEWELLTEA',
    categoryEmoji: '🍵',
    url: 'https://www.yogitea.com',
    exclusiveLabel: 'esclusivo Be Well',
    bgColor: amber-light,
  ),
  BwDiscount(
    id: 'garmin',
    brandName: 'Garmin',
    description: '-8% wearable salute',
    code: 'BEWELLFIT',
    categoryEmoji: '⌚',
    url: 'https://www.garmin.com',
    exclusiveLabel: 'esclusivo Be Well',
    bgColor: gray-light,
  ),
];
```

### DiscountCard
```dart
// Row con:
// - Emoji 38px in cerchio colorato
// - Info: brandName bold, description, exclusive badge verde
// - Pulsante "Ottieni" — amber background
// Tap → bottom sheet con:
//   - Brand + descrizione sconto
//   - Codice in box grande con pulsante "Copia codice"
//   - Pulsante "Vai al sito" → apre url in browser
//   - Nota: "Questo link supporta Be Well"
```

---

## 4. TAB 3 — CONTENUTI IN-APP + PREMIUM

### Struttura
```
[Banner Premium — in cima]
[sec label: "welly"]
[griglia 2x2 outfit/animazioni]
[sec label: "soundscape"]
[griglia 2x2 suoni]
[sec label: "minigame"]
[lista minigame]
[sec label: "percorsi"]
[lista percorsi]
```

### Banner Premium
```dart
Container(
  margin: EdgeInsets.fromLTRB(10, 0, 10, 10),
  padding: EdgeInsets.all(12),
  decoration: BoxDecoration(
    gradient: LinearGradient(
      colors: [purple.withOpacity(0.08), teal.withOpacity(0.06)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    borderRadius: BorderRadius.circular(12),
    border: Border.all(color: purple.withOpacity(0.2), width: 0.5),
  ),
  child: Column(children: [
    Row(children: [
      Text('Be Well Premium', style: /* 12px w500 */),
      Spacer(),
      Text('3.99€/mese', style: /* 11px, purple */),
    ]),
    SizedBox(height: 8),
    // 4 feature con dot check purple
    _PremiumFeature(s.premiumAllContent),   // "Tutti i contenuti in-app inclusi"
    _PremiumFeature(s.premiumPoints),        // "+20% punti su ogni abitudine"
    _PremiumFeature(s.premiumWelly),         // "Welly personalizzabile completo"
    _PremiumFeature(s.premiumDiscounts),     // "Sconti esclusivi in anteprima"
    SizedBox(height: 8),
    // Pulsante trial
    Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 7),
      decoration: BoxDecoration(
        color: purple.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: purple.withOpacity(0.25), width: 0.5),
      ),
      child: Text(s.premiumTrial, /* "Prova 7 giorni gratis" */
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10, color: purple, fontWeight: FontWeight.w500),
      ),
    ),
    SizedBox(height: 5),
    Text(s.premiumOr, /* "oppure acquista singolarmente con i punti" */
      textAlign: TextAlign.center,
      style: TextStyle(fontSize: 9, color: p.textSec),
    ),
  ]),
)
```

### Modello InAppItem (nuovo)
```dart
class InAppItem {
  final String id;
  final String name;
  final String emoji;
  final String category;   // 'welly' | 'soundscape' | 'minigame' | 'percorso'
  final int pointsCost;
  final bool isUnlocked;   // da SharedPreferences
  final String? description;
}
```

Creare file: lib/models/inapp_item_model.dart

### Lista contenuti
```dart
static const List<InAppItem> all = [
  // WELLY
  InAppItem(id:'welly_summer', name:'Outfit Estate',    emoji:'🌸', category:'welly',      pointsCost:500),
  InAppItem(id:'welly_winter', name:'Outfit Inverno',   emoji:'❄️', category:'welly',      pointsCost:500),
  InAppItem(id:'welly_dance',  name:'Animazione Danza', emoji:'💃', category:'welly',      pointsCost:800),
  InAppItem(id:'welly_zen',    name:'Personalità Zen',  emoji:'🧘', category:'welly',      pointsCost:300),

  // SOUNDSCAPE
  InAppItem(id:'sound_forest', name:'Foresta',     emoji:'🌲', category:'soundscape', pointsCost:200, description:'per il focus'),
  InAppItem(id:'sound_rain',   name:'Pioggia',     emoji:'🌧', category:'soundscape', pointsCost:200, description:'per il focus'),
  InAppItem(id:'sound_cafe',   name:'Café',        emoji:'☕', category:'soundscape', pointsCost:200, description:'per il focus'),
  InAppItem(id:'sound_ocean',  name:'Oceano',      emoji:'🌊', category:'soundscape', pointsCost:200, description:'per la respirazione'),

  // MINIGAME
  InAppItem(id:'game_garden',    name:'Il giardino di Welly',  emoji:'🌱', category:'minigame', pointsCost:1000, description:'Coltiva piante con le abitudini'),
  InAppItem(id:'game_breathing', name:'Gioco respirazione',    emoji:'💨', category:'minigame', pointsCost:500,  description:'Vola con Welly respirando'),

  // PERCORSI
  InAppItem(id:'path_focus',   name:'Settimana del focus',  emoji:'⭐', category:'percorso', pointsCost:600, description:'7 giorni guidati'),
  InAppItem(id:'path_stress',  name:'Reset dello stress',   emoji:'🌿', category:'percorso', pointsCost:600, description:'7 giorni guidati'),
  InAppItem(id:'path_morning', name:'Buongiorno Be Well',   emoji:'🌅', category:'percorso', pointsCost:600, description:'7 giorni guidati'),
];
```

### InAppCard (griglia 2 colonne per welly/soundscape, lista per minigame/percorsi)
```dart
// Griglia welly e soundscape:
// card con emoji, nome, sottotitolo opzionale
// in basso: "X pt" + pulsante "Sblocca" se non sbloccato
//           badge "✓ Sbloccato" se già posseduto
// Opacity 0.55 se non abbastanza punti

// Lista minigame e percorsi:
// stessa struttura di RewardCard ma con btn-pts color purple
```

### Logica sblocco in-app
```dart
// In InAppProvider (nuovo) o in AppProvider:
// Salva items sbloccati in SharedPreferences: 'unlocked_inapp_items': List<String>
// Metodo: Future<bool> unlockItem(String itemId, int pointsCost)
//   - Verifica user.points >= pointsCost
//   - Scala i punti
//   - Aggiunge itemId agli sbloccati
//   - notifyListeners()
//   - AnalyticsService.logInAppPurchase(itemId, pointsCost)
```

---

## 5. NUOVE CHIAVI i18n

Aggiungere in BwStrings abstract + EN/IT/FR/DE/ES:

```dart
// Marketplace generale
String get pointsAvailable;       // "punti disponibili"
String get marketplaceTabRewards;  // "Premi"
String get marketplaceTabDiscounts;// "Sconti"
String get marketplaceTabInApp;    // "In-app"

// Tab 1 — Premi
String get rewardsToRedeem;       // "da riscattare"
String get rewardRedeemed;        // "Eccolo. Te lo sei guadagnato."
String get rewardConfirmTitle;    // "Sei sicuro?"
String get rewardConfirmBody;     // "Verranno scalati X punti dal tuo saldo."
String get copyCode;              // "Copia codice"
String get codeCopied;            // "Codice copiato"

// Rewarded ad
String get watchAd;               // "Guarda uno spot · +10 pt"
String get whyAds;                // "perché?"
String get whyAdsTitle;           // "Be Well è gratuita per tutti"
String get whyAdsBody;            // testo completo vedi sezione 2

// Tab 2 — Sconti
String get discountsActive;       // "sconti attivi"
String get discountsNote;         // "Gli sconti sono aggiornati ogni mese..."
String get discountExclusive;     // "esclusivo Be Well"
String get goToSite;              // "Vai al sito"
String get affiliateNote;         // "Questo link supporta Be Well"

// Tab 3 — In-app
String get inAppWelly;            // "welly"
String get inAppSoundscape;       // "soundscape"
String get inAppMinigame;         // "minigame"
String get inAppPercorsi;         // "percorsi"
String get unlockItem;            // "Sblocca"
String get itemUnlocked;          // "✓ Sbloccato"

// Premium
String get premiumAllContent;     // "Tutti i contenuti in-app inclusi"
String get premiumPoints;         // "+20% punti su ogni abitudine"
String get premiumWelly;          // "Welly personalizzabile completo"
String get premiumDiscounts;      // "Sconti esclusivi in anteprima"
String get premiumTrial;          // "Prova 7 giorni gratis"
String get premiumOr;             // "oppure acquista singolarmente con i punti"
```

Traduzioni EN/IT/FR/DE/ES:

```
pointsAvailable:
  en:"points available" it:"punti disponibili"
  fr:"points disponibles" de:"Punkte verfügbar" es:"puntos disponibles"

marketplaceTabRewards:
  en:"Rewards" it:"Premi" fr:"Récompenses" de:"Prämien" es:"Premios"

marketplaceTabDiscounts:
  en:"Discounts" it:"Sconti" fr:"Réductions" de:"Rabatte" es:"Descuentos"

marketplaceTabInApp:
  en:"In-app" it:"In-app" fr:"In-app" de:"In-App" es:"En la app"

rewardsToRedeem:
  en:"to redeem" it:"da riscattare" fr:"à échanger"
  de:"einzulösen" es:"para canjear"

rewardRedeemed:
  en:"There it is. You earned it." it:"Eccolo. Te lo sei guadagnato."
  fr:"Le voilà. Tu l'as mérité." de:"Da ist es. Du hast es verdient."
  es:"Ahí está. Te lo ganaste."

rewardConfirmTitle:
  en:"Are you sure?" it:"Sei sicuro?" fr:"Êtes-vous sûr ?"
  de:"Bist du sicher?" es:"¿Estás seguro?"

rewardConfirmBody:
  en:"X points will be deducted from your balance."
  it:"Verranno scalati X punti dal tuo saldo."
  fr:"X points seront déduits de votre solde."
  de:"X Punkte werden von deinem Guthaben abgezogen."
  es:"Se deducirán X puntos de tu saldo."

copyCode:
  en:"Copy code" it:"Copia codice" fr:"Copier le code"
  de:"Code kopieren" es:"Copiar código"

codeCopied:
  en:"Copied" it:"Copiato" fr:"Copié" de:"Kopiert" es:"Copiado"

watchAd:
  en:"Watch a spot · +10 pt" it:"Guarda uno spot · +10 pt"
  fr:"Regarder une pub · +10 pt" de:"Spot ansehen · +10 Pt"
  es:"Ver un anuncio · +10 pt"

whyAds:
  en:"why?" it:"perché?" fr:"pourquoi ?" de:"warum?" es:"¿por qué?"

whyAdsTitle:
  en:"Be Well is free for everyone" it:"Be Well è gratuita per tutti"
  fr:"Be Well est gratuit pour tous" de:"Be Well ist für alle kostenlos"
  es:"Be Well es gratuito para todos"

whyAdsBody:
  en:"Be Well is a free app to be accessible to everyone. Like any service, it has running costs. By watching ads when you can, you help us keep the service running and improve it for everyone. Thank you."
  it:"Be Well è un'app gratuita per essere accessibile a chiunque. Come ogni servizio, ha costi di gestione. Guardando le inserzioni quando puoi, ci aiuti a tenere il servizio attivo e migliorarlo per tutti. Grazie davvero."
  fr:"Be Well est une application gratuite pour être accessible à tous. Comme tout service, elle a des coûts de fonctionnement. En regardant les publicités quand vous le pouvez, vous nous aidez à maintenir le service actif et à l'améliorer pour tous. Merci."
  de:"Be Well ist eine kostenlose App, um für alle zugänglich zu sein. Wie jeder Dienst hat es Betriebskosten. Indem du Werbung ansiehst, wenn du kannst, hilfst du uns, den Dienst am Laufen zu halten und ihn für alle zu verbessern. Danke."
  es:"Be Well es una aplicación gratuita para ser accesible para todos. Como cualquier servicio, tiene costos operativos. Al ver anuncios cuando puedas, nos ayudas a mantener el servicio activo y mejorarlo para todos. Gracias."

discountsActive:
  en:"active discounts" it:"sconti attivi" fr:"réductions actives"
  de:"aktive Rabatte" es:"descuentos activos"

discountsNote:
  en:"Discounts are updated monthly. No points required."
  it:"Gli sconti sono aggiornati ogni mese. Nessun punto richiesto."
  fr:"Les réductions sont mises à jour chaque mois. Aucun point requis."
  de:"Rabatte werden monatlich aktualisiert. Keine Punkte erforderlich."
  es:"Los descuentos se actualizan mensualmente. No se requieren puntos."

discountExclusive:
  en:"exclusive Be Well" it:"esclusivo Be Well"
  fr:"exclusif Be Well" de:"exklusiv Be Well" es:"exclusivo Be Well"

goToSite:
  en:"Go to site" it:"Vai al sito" fr:"Aller sur le site"
  de:"Zur Website" es:"Ir al sitio"

affiliateNote:
  en:"This link supports Be Well" it:"Questo link supporta Be Well"
  fr:"Ce lien soutient Be Well" de:"Dieser Link unterstützt Be Well"
  es:"Este enlace apoya Be Well"

unlockItem:
  en:"Unlock" it:"Sblocca" fr:"Débloquer" de:"Freischalten" es:"Desbloquear"

itemUnlocked:
  en:"Unlocked" it:"Sbloccato" fr:"Débloqué" de:"Freigeschaltet" es:"Desbloqueado"

premiumAllContent:
  en:"All in-app content included" it:"Tutti i contenuti in-app inclusi"
  fr:"Tous les contenus in-app inclus" de:"Alle In-App-Inhalte inklusive"
  es:"Todo el contenido in-app incluido"

premiumPoints:
  en:"+20% points on every habit" it:"+20% punti su ogni abitudine"
  fr:"+20% de points pour chaque habitude" de:"+20% Punkte für jede Gewohnheit"
  es:"+20% puntos en cada hábito"

premiumWelly:
  en:"Fully customizable Welly" it:"Welly personalizzabile completo"
  fr:"Welly entièrement personnalisable" de:"Vollständig anpassbarer Welly"
  es:"Welly completamente personalizable"

premiumDiscounts:
  en:"Exclusive discounts in advance" it:"Sconti esclusivi in anteprima"
  fr:"Réductions exclusives en avant-première" de:"Exklusive Rabatte vorab"
  es:"Descuentos exclusivos por adelantado"

premiumTrial:
  en:"Try 7 days free" it:"Prova 7 giorni gratis"
  fr:"Essayez 7 jours gratuits" de:"7 Tage kostenlos testen"
  es:"Prueba 7 días gratis"

premiumOr:
  en:"or buy individually with points" it:"oppure acquista singolarmente con i punti"
  fr:"ou achetez individuellement avec des points"
  de:"oder einzeln mit Punkten kaufen" es:"o compra individualmente con puntos"
```

---

## 6. NUOVI FILE DA CREARE

```
lib/models/discount_model.dart     ← BwDiscount con lista sconti
lib/models/inapp_item_model.dart   ← InAppItem con lista contenuti
lib/providers/inapp_provider.dart  ← gestione sblocchi in-app con SharedPreferences
```

## 7. FILE DA MODIFICARE

```
lib/screens/marketplace/marketplace_screen.dart  ← ristruttura completamente
lib/l10n/app_localizations.dart                 ← aggiungi tutte le chiavi
pubspec.yaml                                     ← aggiungi google_mobile_ads
```

---

## 8. ORDINE DI IMPLEMENTAZIONE

### TASK 1 — i18n: aggiungi tutte le chiavi
FILE: lib/l10n/app_localizations.dart
- Aggiungi in BwStrings abstract
- Aggiungi in _En, _It, _Fr, _De, _Es con le traduzioni della sezione 5
- flutter analyze → 0 errori

### TASK 2 — Modelli dati
- Crea lib/models/discount_model.dart con BwDiscount e lista sconti
- Crea lib/models/inapp_item_model.dart con InAppItem e lista contenuti
- flutter analyze → 0 errori

### TASK 3 — InAppProvider
- Crea lib/providers/inapp_provider.dart
- Gestisce items sbloccati in SharedPreferences
- Metodo unlockItem(id, cost) che scala i punti e salva
- Registra in main.dart tra i Provider
- flutter analyze → 0 errori

### TASK 4 — Tab 1: Premi con punti
FILE: lib/screens/marketplace/marketplace_screen.dart
- Ristruttura la schermata con header inline + striscia punti + 3 tab
- Implementa Tab 1 con lista RewardCard e bottom sheet riscatto
- Aggiungi RewardedAdCard in fondo con dialog "perché?"
- flutter analyze → 0 errori

### TASK 5 — AdMob rewarded
- Aggiungi google_mobile_ads in pubspec.yaml
- Implementa RewardedAd nel RewardedAdCard
- Usa test ad unit ID durante sviluppo
- Dopo visione: +10 pt + AnalyticsService.logAdWatched()
- flutter analyze → 0 errori

### TASK 6 — Tab 2: Sconti esclusivi
FILE: lib/screens/marketplace/marketplace_screen.dart
- Implementa Tab 2 con lista DiscountCard
- Bottom sheet: codice da copiare + link al sito
- Usa url_launcher per aprire i link
- flutter analyze → 0 errori

### TASK 7 — Tab 3: In-app + Premium
FILE: lib/screens/marketplace/marketplace_screen.dart
- Implementa Banner Premium in cima
- Griglia 2 colonne per welly e soundscape
- Lista per minigame e percorsi
- Logica sblocco con InAppProvider
- flutter analyze → 0 errori

### TASK 8 — Build finale
flutter build apk --debug
Dimmi cosa hai fatto e cosa eventualmente manca.

---

## 9. REGOLE ASSOLUTE

1. flutter analyze → 0 errori dopo OGNI task
2. Ogni stringa UI: context.sL.chiave — mai hardcoded
3. Nuova chiave = BwStrings abstract + TUTTE E 5 LE LINGUE
4. Il rewarded ad è sempre volontario — mai forzato
5. Il dialog "perché?" deve sempre essere presente accanto al pulsante spot
6. I link Awin si aprono nel browser esterno (url_launcher)
7. Gli items in-app sbloccati persistono in SharedPreferences
8. La tab premium non esiste — il banner premium è dentro la tab In-app
9. Nessun dato utente identificabile nei link Awin
10. AnalyticsService va chiamato su ogni azione significativa:
    logRewardRedeemed, logDiscountObtained, logAdWatched, logInAppPurchase, logPremiumTapped
