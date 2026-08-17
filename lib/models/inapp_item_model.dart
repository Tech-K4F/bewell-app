// ─── Modello contenuto in-app ─────────────────────────────────────────────────

class InAppItem {
  final String id;
  final String name;
  final String emoji;
  final String category;   // 'welly' | 'soundscape' | 'minigame' | 'percorso'
  final int pointsCost;
  final String? description;

  // isUnlocked NON è nel modello: viene gestito da InAppProvider tramite
  // SharedPreferences, per evitare stato mutabile in un oggetto const.

  const InAppItem({
    required this.id,
    required this.name,
    required this.emoji,
    required this.category,
    required this.pointsCost,
    this.description,
  });
}

// ─── Catalogo contenuti in-app ────────────────────────────────────────────────

class InAppCatalog {
  static const List<InAppItem> all = [

    // ── Welly ──────────────────────────────────────────────────────────────
    InAppItem(id: 'welly_summer', name: 'Outfit Estate',    emoji: '🌸', category: 'welly',      pointsCost: 500),
    InAppItem(id: 'welly_winter', name: 'Outfit Inverno',   emoji: '❄️', category: 'welly',      pointsCost: 500),
    InAppItem(id: 'welly_dance',  name: 'Animazione Danza', emoji: '💃', category: 'welly',      pointsCost: 800),
    InAppItem(id: 'welly_zen',    name: 'Personalità Zen',  emoji: '🧘', category: 'welly',      pointsCost: 300),

    // ── Soundscape ────────────────────────────────────────────────────────
    InAppItem(id: 'sound_forest', name: 'Foresta', emoji: '🌲', category: 'soundscape', pointsCost: 200, description: 'per il focus'),
    InAppItem(id: 'sound_rain',   name: 'Pioggia', emoji: '🌧', category: 'soundscape', pointsCost: 200, description: 'per il focus'),
    InAppItem(id: 'sound_cafe',   name: 'Café',    emoji: '☕', category: 'soundscape', pointsCost: 200, description: 'per il focus'),
    InAppItem(id: 'sound_ocean',  name: 'Oceano',  emoji: '🌊', category: 'soundscape', pointsCost: 200, description: 'per la respirazione'),

    // ── Minigame ──────────────────────────────────────────────────────────
    InAppItem(id: 'game_garden',    name: 'Il giardino di Welly', emoji: '🌱', category: 'minigame', pointsCost: 1000, description: 'Coltiva piante con le abitudini'),
    InAppItem(id: 'game_breathing', name: 'Gioco respirazione',   emoji: '💨', category: 'minigame', pointsCost: 500,  description: 'Vola con Welly respirando'),

    // ── Percorsi ──────────────────────────────────────────────────────────
    InAppItem(id: 'path_focus',   name: 'Settimana del focus', emoji: '⭐', category: 'percorso', pointsCost: 600, description: '7 giorni guidati'),
    InAppItem(id: 'path_stress',  name: 'Reset dello stress',  emoji: '🌿', category: 'percorso', pointsCost: 600, description: '7 giorni guidati'),
    InAppItem(id: 'path_morning', name: 'Buongiorno Be Well',  emoji: '🌅', category: 'percorso', pointsCost: 600, description: '7 giorni guidati'),
  ];

  // Helper: filtra per categoria
  static List<InAppItem> byCategory(String category) =>
      all.where((item) => item.category == category).toList();
}
