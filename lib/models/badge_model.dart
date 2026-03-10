class BwBadge {
  final String id;
  final String name;
  final String emoji;
  final String description;
  final String category;
  final int requiredCount;
  final String metric;

  const BwBadge({
    required this.id,
    required this.name,
    required this.emoji,
    required this.description,
    required this.category,
    required this.requiredCount,
    required this.metric,
  });
}

const List<BwBadge> allBadges = [
  BwBadge(
    id: 'HYD_7',
    name: 'Hydration Champion',
    emoji: '💧',
    description: 'Bevi acqua per 7 giorni consecutivi',
    category: 'Hydration',
    requiredCount: 7,
    metric: 'streak',
  ),
  BwBadge(
    id: 'HYD_30',
    name: 'Water Warrior',
    emoji: '🌊',
    description: 'Bevi acqua per 30 giorni consecutivi',
    category: 'Hydration',
    requiredCount: 30,
    metric: 'streak',
  ),
  BwBadge(
    id: 'FOC_10',
    name: 'Focus Starter',
    emoji: '🎯',
    description: 'Completa 10 sessioni focus',
    category: 'Focus',
    requiredCount: 10,
    metric: 'sessions',
  ),
  BwBadge(
    id: 'FOC_50',
    name: 'Focus Master',
    emoji: '🧠',
    description: 'Completa 50 sessioni focus',
    category: 'Focus',
    requiredCount: 50,
    metric: 'sessions',
  ),
  BwBadge(
    id: 'STK_3',
    name: 'First Steps',
    emoji: '👣',
    description: '3 giorni di streak',
    category: 'Streak',
    requiredCount: 3,
    metric: 'streak',
  ),
  BwBadge(
    id: 'STK_7',
    name: 'Week Warrior',
    emoji: '🔥',
    description: '7 giorni di streak',
    category: 'Streak',
    requiredCount: 7,
    metric: 'streak',
  ),
  BwBadge(
    id: 'STK_30',
    name: 'Monthly Champion',
    emoji: '🏆',
    description: '30 giorni di streak',
    category: 'Streak',
    requiredCount: 30,
    metric: 'streak',
  ),
  BwBadge(
    id: 'PTS_100',
    name: 'Point Collector',
    emoji: '⭐',
    description: 'Raggiungi 100 punti',
    category: 'Punti',
    requiredCount: 100,
    metric: 'points',
  ),
  BwBadge(
    id: 'PTS_500',
    name: 'Point Champion',
    emoji: '🌟',
    description: 'Raggiungi 500 punti',
    category: 'Punti',
    requiredCount: 500,
    metric: 'points',
  ),
  BwBadge(
    id: 'STR_10',
    name: 'Calm Seeker',
    emoji: '🧘',
    description: 'Completa 10 esercizi di respirazione',
    category: 'Stress',
    requiredCount: 10,
    metric: 'completions',
  ),
  BwBadge(
    id: 'MOV_7',
    name: 'Active Week',
    emoji: '🏃',
    description: '7 sessioni di movimento',
    category: 'Movimento',
    requiredCount: 7,
    metric: 'completions',
  ),
  BwBadge(
    id: 'PLAN_1',
    name: 'Perfect Day',
    emoji: '✅',
    description: 'Completa il piano giornaliero',
    category: 'Piano',
    requiredCount: 1,
    metric: 'plan_complete',
  ),
  BwBadge(
    id: 'PLAN_7',
    name: 'Perfect Week',
    emoji: '🌈',
    description: '7 piani giornalieri completati',
    category: 'Piano',
    requiredCount: 7,
    metric: 'plan_complete',
  ),
];
