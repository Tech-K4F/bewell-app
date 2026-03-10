// ─── Models ───────────────────────────────────────────────────────────────────

class RewardItem {
  final String id;
  final String title;
  final String brand;
  final String description;
  final String emoji;
  final String category;
  final int pointsCost;
  final String? originalValue;
  final bool isAvailable;
  final int stock; // -1 = illimitato
  final String type; // voucher | discount | experience | digital

  const RewardItem({
    required this.id,
    required this.title,
    required this.brand,
    required this.description,
    required this.emoji,
    required this.category,
    required this.pointsCost,
    this.originalValue,
    this.isAvailable = true,
    this.stock = -1,
    required this.type,
  });

  factory RewardItem.fromJson(Map<String, dynamic> j) => RewardItem(
        id: j['id'] as String,
        title: j['title'] as String,
        brand: j['brand'] as String,
        description: j['description'] as String,
        emoji: j['emoji'] as String,
        category: j['category'] as String,
        pointsCost: j['pointsCost'] as int,
        originalValue: j['originalValue'] as String?,
        isAvailable: j['isAvailable'] as bool? ?? true,
        stock: j['stock'] as int? ?? -1,
        type: j['type'] as String,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'brand': brand,
        'description': description,
        'emoji': emoji,
        'category': category,
        'pointsCost': pointsCost,
        'originalValue': originalValue,
        'isAvailable': isAvailable,
        'stock': stock,
        'type': type,
      };
}

class RedeemedReward {
  final String rewardId;
  final String rewardTitle;
  final String rewardEmoji;
  final int pointsSpent;
  final DateTime redeemedAt;
  final String code;
  final bool isUsed;

  const RedeemedReward({
    required this.rewardId,
    required this.rewardTitle,
    required this.rewardEmoji,
    required this.pointsSpent,
    required this.redeemedAt,
    required this.code,
    this.isUsed = false,
  });

  Map<String, dynamic> toJson() => {
        'rewardId': rewardId,
        'rewardTitle': rewardTitle,
        'rewardEmoji': rewardEmoji,
        'pointsSpent': pointsSpent,
        'redeemedAt': redeemedAt.toIso8601String(),
        'code': code,
        'isUsed': isUsed,
      };

  factory RedeemedReward.fromJson(Map<String, dynamic> j) => RedeemedReward(
        rewardId: j['rewardId'],
        rewardTitle: j['rewardTitle'],
        rewardEmoji: j['rewardEmoji'],
        pointsSpent: j['pointsSpent'],
        redeemedAt: DateTime.parse(j['redeemedAt']),
        code: j['code'],
        isUsed: j['isUsed'] ?? false,
      );

  RedeemedReward copyWithUsed() => RedeemedReward(
        rewardId: rewardId,
        rewardTitle: rewardTitle,
        rewardEmoji: rewardEmoji,
        pointsSpent: pointsSpent,
        redeemedAt: redeemedAt,
        code: code,
        isUsed: true,
      );
}

// ─── Catalogo mock ────────────────────────────────────────────────────────────
// Brand TUTTI fittizi, usati solo a scopo dimostrativo.
// Sostituiti da RewardRepository.getCatalog() a regime.

const List<RewardItem> _mockRewards = [

  // ☕ Food & Drink
  RewardItem(
    id: 'BRW_001',
    title: 'Caffè gratis',
    brand: 'BrewBuddies',
    description: 'Un caffè a tua scelta da BrewBuddies. "Il caffè che ti capisce." Valido 30 giorni dall\'attivazione.',
    emoji: '☕',
    category: 'Food & Drink',
    pointsCost: 150,
    originalValue: '€5',
    type: 'voucher',
  ),
  RewardItem(
    id: 'BRW_002',
    title: 'Smoothie XL',
    brand: 'BrewBuddies',
    description: 'Smoothie XL con frutta di stagione. Perché a volte la vita è già abbastanza amara.',
    emoji: '🥤',
    category: 'Food & Drink',
    pointsCost: 200,
    originalValue: '€7',
    type: 'voucher',
  ),
  RewardItem(
    id: 'ZPPD_001',
    title: 'Sconto €5 su ordine',
    brand: 'ZippaDoor',
    description: 'Sconto €5 sul prossimo ordine ZippaDoor. Consegna veloce garantita, o quasi. Minimo €15.',
    emoji: '🛵',
    category: 'Food & Drink',
    pointsCost: 120,
    originalValue: '€5',
    type: 'discount',
  ),
  RewardItem(
    id: 'FRKK_001',
    title: 'Pranzo per 2',
    brand: 'ForchettaKebab™',
    description: 'Menù pranzo per 2 da ForchettaKebab™. "Mangiare bene è un atto rivoluzionario."',
    emoji: '🍽️',
    category: 'Food & Drink',
    pointsCost: 380,
    originalValue: '€18',
    type: 'voucher',
    stock: 30,
  ),
  RewardItem(
    id: 'MNCF_001',
    title: 'Box colazione',
    brand: 'MunchFactory',
    description: 'Box colazione MunchFactory con 5 prodotti artigianali consegnati a casa. Inizia bene la giornata.',
    emoji: '🥐',
    category: 'Food & Drink',
    pointsCost: 280,
    originalValue: '€12',
    type: 'voucher',
  ),

  // 🏋️ Sport & Fitness
  RewardItem(
    id: 'SWTS_001',
    title: '1 settimana palestra',
    brand: 'SweatStation',
    description: 'Accesso illimitato per una settimana in qualsiasi SweatStation d\'Italia. Sudore incluso, asciugamano no.',
    emoji: '🏋️',
    category: 'Sport & Fitness',
    pointsCost: 500,
    originalValue: '€30',
    type: 'experience',
    stock: 50,
  ),
  RewardItem(
    id: 'FLXY_001',
    title: '3 lezioni online',
    brand: 'FlexYogi',
    description: '3 lezioni live con i trainer FlexYogi. "Inspira. Espira. Guadagna punti."',
    emoji: '🧘',
    category: 'Sport & Fitness',
    pointsCost: 350,
    originalValue: '€25',
    type: 'experience',
  ),
  RewardItem(
    id: 'KCKR_001',
    title: 'Sconto 20% scarpe',
    brand: 'KickRunner',
    description: '20% di sconto su tutto il catalogo KickRunner. Per chi corre, e per chi fa finta di correre.',
    emoji: '👟',
    category: 'Sport & Fitness',
    pointsCost: 300,
    originalValue: '20% off',
    type: 'discount',
  ),
  RewardItem(
    id: 'CYCL_001',
    title: '3 corse in bici elettrica',
    brand: 'CycleMe',
    description: '3 corse con le bici elettriche CycleMe. Eco-friendly e figo. Doppia vittoria.',
    emoji: '🚴',
    category: 'Sport & Fitness',
    pointsCost: 180,
    originalValue: '€9',
    type: 'voucher',
  ),

  // 🧠 Benessere
  RewardItem(
    id: 'CLMD_001',
    title: '1 mese premium',
    brand: 'CalmDojo',
    description: 'Un mese di CalmDojo completo: meditazioni, sleep sounds, percorsi anti-stress. Zen garantito.',
    emoji: '🧠',
    category: 'Benessere',
    pointsCost: 400,
    originalValue: '€12',
    type: 'digital',
  ),
  RewardItem(
    id: 'SNZZ_001',
    title: '2 settimane sleep program',
    brand: 'Snoozify',
    description: '2 settimane di programma sonno guidato con Snoozify. Per chi dorme male e ne va fiero.',
    emoji: '🌙',
    category: 'Benessere',
    pointsCost: 250,
    originalValue: '€8',
    type: 'digital',
  ),
  RewardItem(
    id: 'BBLB_001',
    title: 'Sessione relax 60 min',
    brand: 'BubbleLab',
    description: 'Una sessione relax da 60 min nel centro BubbleLab. "Perché te lo meriti davvero."',
    emoji: '🛁',
    category: 'Benessere',
    pointsCost: 800,
    originalValue: '€35',
    type: 'experience',
    stock: 20,
  ),
  RewardItem(
    id: 'MNDF_001',
    title: 'Kit aromaterapia',
    brand: 'MindfulStuff',
    description: 'Kit con 3 oli essenziali e diffusore mini MindfulStuff. Niente più scuse per non rilassarsi.',
    emoji: '🕯️',
    category: 'Benessere',
    pointsCost: 320,
    originalValue: '€15',
    type: 'voucher',
  ),

  // 📚 Cultura
  RewardItem(
    id: 'PGTR_001',
    title: '1 mese lettura illimitata',
    brand: 'PageTurner+',
    description: 'Accesso illimitato a 800.000+ ebook su PageTurner+. La crescita personale è gratis (quasi).',
    emoji: '📚',
    category: 'Cultura',
    pointsCost: 200,
    originalValue: '€9',
    type: 'digital',
  ),
  RewardItem(
    id: 'EARW_001',
    title: '1 mese audiolibri',
    brand: 'EarWorm',
    description: 'Un mese di EarWorm con 1 audiolibro incluso. Ascolta mentre cammini. Due piccioni, una app.',
    emoji: '🎧',
    category: 'Cultura',
    pointsCost: 180,
    originalValue: '€10',
    type: 'digital',
  ),
  RewardItem(
    id: 'SKLS_001',
    title: 'Corso online a scelta',
    brand: 'SkillSpark',
    description: 'Accesso a 1 corso su SkillSpark: design, coding, marketing, cucina molecolare e altro.',
    emoji: '🎓',
    category: 'Cultura',
    pointsCost: 450,
    originalValue: '€20',
    type: 'digital',
  ),

  // 🛍️ Shopping
  RewardItem(
    id: 'BOXD_001',
    title: 'Buono €10',
    brand: 'BoxDrop',
    description: 'Buono acquisto BoxDrop del valore di €10. Valido su tutto il catalogo, nessuna scusa.',
    emoji: '📦',
    category: 'Shopping',
    pointsCost: 600,
    originalValue: '€10',
    type: 'voucher',
  ),
  RewardItem(
    id: 'THRD_001',
    title: 'Sconto 15% abbigliamento',
    brand: 'ThreadHouse',
    description: '15% di sconto su tutto ThreadHouse. Vestiti bene, guadagna punti. La combo definitiva.',
    emoji: '👗',
    category: 'Shopping',
    pointsCost: 280,
    originalValue: '15% off',
    type: 'discount',
  ),
  RewardItem(
    id: 'GRNB_001',
    title: 'Kit piante da scrivania',
    brand: 'GreenBoss',
    description: 'Kit con 2 piante + vaso ceramica GreenBoss. Il collega silenzioso che non ti delude mai.',
    emoji: '🪴',
    category: 'Shopping',
    pointsCost: 360,
    originalValue: '€16',
    type: 'voucher',
    stock: 40,
  ),
];

const List<String> rewardCategories = [
  'Tutti',
  'Food & Drink',
  'Sport & Fitness',
  'Benessere',
  'Cultura',
  'Shopping',
];

// ─── Repository ───────────────────────────────────────────────────────────────
//
// UNICO punto in cui l'app sa da dove arrivano i premi.
// Le schermate chiamano sempre RewardRepository — non sanno nulla
// dell'origine dei dati (mock, Firebase o REST API).
//
// Per passare a Firebase: sostituisci il corpo di getCatalog().
// Zero modifiche alle schermate.

class RewardRepository {
  static final RewardRepository instance = RewardRepository._();
  RewardRepository._();

  /// Restituisce il catalogo premi.
  ///
  /// ─────────────────────────────────────────────────────────
  /// TODO (Firebase): sostituire il corpo con:
  ///
  ///   final snap = await FirebaseFirestore.instance
  ///       .collection('rewards')
  ///       .where('isAvailable', isEqualTo: true)
  ///       .orderBy('pointsCost')
  ///       .get();
  ///   return snap.docs
  ///       .map((d) => RewardItem.fromJson(d.data()))
  ///       .toList();
  ///
  /// ─────────────────────────────────────────────────────────
  /// TODO (REST API): sostituire il corpo con:
  ///
  ///   final res = await http.get(
  ///     Uri.parse('$baseUrl/api/v1/rewards'),
  ///     headers: {'Authorization': 'Bearer $token'},
  ///   );
  ///   if (res.statusCode != 200) throw Exception('Catalog fetch failed');
  ///   final list = json.decode(res.body)['rewards'] as List;
  ///   return list.map((j) => RewardItem.fromJson(j)).toList();
  ///
  /// ─────────────────────────────────────────────────────────
  Future<List<RewardItem>> getCatalog() async {
    // Simula latenza di rete anche in modalità mock
    await Future.delayed(const Duration(milliseconds: 300));
    return _mockRewards.where((r) => r.isAvailable).toList();
  }

  /// Recupera un singolo premio per ID.
  Future<RewardItem?> getById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _mockRewards.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }
}
