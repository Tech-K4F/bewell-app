import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/app_provider.dart';
import '../../models/planner_model.dart';
import '../../theme/app_theme.dart';

class PlannerScreen extends StatefulWidget {
  const PlannerScreen({super.key});
  @override
  State<PlannerScreen> createState() => _PlannerScreenState();
}

class _PlannerScreenState extends State<PlannerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BwColors.darkPanel,
      appBar: AppBar(
        title: const Text('Piano Giornaliero'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showSettingsModal(context),
            tooltip: 'Impostazioni',
          ),
          IconButton(
            icon: const Icon(Icons.library_books_outlined),
            onPressed: () => _showActivityLibrary(context),
            tooltip: 'Libreria',
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: BwColors.teal,
          labelColor: BwColors.teal,
          unselectedLabelColor: BwColors.textSecondary,
          tabs: const [
            Tab(text: 'Giornaliero'),
            Tab(text: 'Attività'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _DailyView(
            selectedDate: _selectedDate,
            onDateChange: (d) => setState(() => _selectedDate = d),
          ),
          const _ActivitiesTab(),
        ],
      ),
    );
  }

  void _showSettingsModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BwColors.panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppProvider>(),
        child: const _PlannerSettingsSheet(),
      ),
    );
  }

  void _showActivityLibrary(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: BwColors.panel,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ChangeNotifierProvider.value(
        value: context.read<AppProvider>(),
        child: const _ActivityLibrarySheet(),
      ),
    );
  }
}

class _DailyView extends StatelessWidget {
  final DateTime selectedDate;
  final ValueChanged<DateTime> onDateChange;
  const _DailyView(
      {required this.selectedDate, required this.onDateChange});

  String _formatDate(DateTime d) {
    const weekdays = [
      'Lunedì', 'Martedì', 'Mercoledì', 'Giovedì',
      'Venerdì', 'Sabato', 'Domenica'
    ];
    const months = [
      'gen', 'feb', 'mar', 'apr', 'mag', 'giu',
      'lug', 'ago', 'set', 'ott', 'nov', 'dic'
    ];
    final isToday = _isSameDay(d, DateTime.now());
    final dayStr = '${weekdays[d.weekday - 1]}, ${d.day} ${months[d.month - 1]}';
    return isToday ? 'Oggi · $dayStr' : dayStr;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, p, _) {
      return Column(
        children: [
          // Date navigator
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: BwColors.panelBorder)),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => onDateChange(
                      selectedDate.subtract(const Duration(days: 1))),
                  padding: EdgeInsets.zero,
                  color: Colors.white.withOpacity(.6),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(_formatDate(selectedDate),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 14)),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => onDateChange(
                      selectedDate.add(const Duration(days: 1))),
                  padding: EdgeInsets.zero,
                  color: Colors.white.withOpacity(.6),
                ),
                TextButton(
                  onPressed: () => onDateChange(DateTime.now()),
                  child: const Text('Oggi',
                      style: TextStyle(
                          color: BwColors.teal, fontSize: 12)),
                ),
              ],
            ),
          ),

          // Summary strip
          if (p.scheduleBlocks.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  _pill(
                      '${p.scheduleBlocks.where((b) => b.type == 'focus').length}',
                      '🧠',
                      'Focus'),
                  const SizedBox(width: 8),
                  _pill(
                      '${p.scheduleBlocks.where((b) => b.type == 'short_break' || b.type == 'long_break').length}',
                      '🧘',
                      'Pause'),
                  const SizedBox(width: 8),
                  _pill(
                      '${p.scheduleBlocks.fold(0, (s, b) => s + b.points)}',
                      '⭐',
                      'Punti'),
                ],
              ),
            ),

          // Schedule blocks
          Expanded(
            child: p.scheduleBlocks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('📅',
                            style: TextStyle(fontSize: 48)),
                        const SizedBox(height: 12),
                        Text(
                          'Configura gli orari di lavoro\ntramite Impostazioni',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                              color: Colors.white.withOpacity(.4),
                              fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 8, 16, 40),
                    itemCount: p.scheduleBlocks.length,
                    itemBuilder: (context, i) =>
                        _ScheduleBlockCard(block: p.scheduleBlocks[i]),
                  ),
          ),
        ],
      );
    });
  }

  Widget _pill(String value, String emoji, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: BwColors.panel,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: BwColors.panelBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 14)),
            const SizedBox(width: 6),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
            const SizedBox(width: 4),
            Text(label,
                style: TextStyle(
                    color: Colors.white.withOpacity(.35),
                    fontSize: 10)),
          ],
        ),
      ),
    );
  }
}

class _ScheduleBlockCard extends StatelessWidget {
  final ScheduleBlock block;
  const _ScheduleBlockCard({required this.block});

  Color get _color {
    switch (block.type) {
      case 'focus': return BwColors.purple;
      case 'short_break': return BwColors.blue;
      case 'long_break': return BwColors.teal;
      case 'lunch': return BwColors.coral;
      default: return BwColors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color;

    return GestureDetector(
      onTap: () => _showDetail(context),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: c.withOpacity(.08),
          borderRadius: BorderRadius.circular(14),
          border: Border(left: BorderSide(color: c, width: 3)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              SizedBox(
                width: 56,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(block.startTime,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700)),
                    Text(block.endTime,
                        style: TextStyle(
                            color: Colors.white.withOpacity(.35),
                            fontSize: 11)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(block.emoji,
                  style: const TextStyle(fontSize: 20)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(block.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14)),
                    Text('${block.durationMinutes} min',
                        style: TextStyle(
                            color: Colors.white.withOpacity(.4),
                            fontSize: 11)),
                  ],
                ),
              ),
              if (block.points > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: BwColors.amberLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text('+${block.points} pt',
                      style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: BwColors.amber)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: BwColors.panel,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Text(block.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(block.title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _detail('⏰ Orario',
                '${block.startTime} — ${block.endTime}'),
            const SizedBox(height: 8),
            _detail('⌛ Durata', '${block.durationMinutes} minuti'),
            if (block.points > 0) ...[
              const SizedBox(height: 8),
              _detail('⭐ Punti', '+${block.points} pt'),
            ],
            if (block.activityIds.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text('Attività incluse',
                  style: TextStyle(
                      color: Colors.white.withOpacity(.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              ...block.activityIds.map((id) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('• $id',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13)),
                  )),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Chiudi',
                style: TextStyle(color: BwColors.teal)),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Row(
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(.5),
                fontSize: 12)),
        const SizedBox(width: 8),
        Text(value,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _ActivitiesTab extends StatelessWidget {
  const _ActivitiesTab();

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, p, _) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: [
          if (p.todayPlan.isEmpty)
            const Center(child: Padding(
              padding: EdgeInsets.all(40),
              child: Text('Nessuna attività', style: TextStyle(color: BwColors.textSecondary)),
            ))
          else
            ...p.todayPlan.map((a) {
              final done = p.completedToday.contains(a.id);
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: BwColors.panel,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: done
                        ? a.color.withOpacity(.3)
                        : BwColors.panelBorder,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: a.color.withOpacity(.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(a.emoji,
                            style: const TextStyle(fontSize: 18)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.name,
                              style: TextStyle(
                                  color: done
                                      ? Colors.white.withOpacity(.4)
                                      : Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  decoration:
                                      done ? TextDecoration.lineThrough : null)),
                          Text('${a.durationMinutes} min · +${a.points} pt',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(.35),
                                  fontSize: 11)),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: done ? null : () => p.completeActivity(a.id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: done ? BwColors.tealLight : Colors.transparent,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: done
                                ? BwColors.teal
                                : Colors.white.withOpacity(.15),
                          ),
                        ),
                        child: done
                            ? const Icon(Icons.check,
                                color: BwColors.teal, size: 14)
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      );
    });
  }
}

// Settings bottom sheet
class _PlannerSettingsSheet extends StatefulWidget {
  const _PlannerSettingsSheet();
  @override
  State<_PlannerSettingsSheet> createState() => _PlannerSettingsSheetState();
}

class _PlannerSettingsSheetState extends State<_PlannerSettingsSheet> {
  late PlannerSettings _s;

  @override
  void initState() {
    super.initState();
    _s = context.read<AppProvider>().plannerSettings;
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: .85,
      maxChildSize: .95,
      minChildSize: .5,
      expand: false,
      builder: (_, scrollCtrl) {
        return SingleChildScrollView(
          controller: scrollCtrl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text('⚙️ Impostazioni Piano',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 24),

                _sectionLabel('Orari di lavoro'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _timeField('Inizio', _s.workStart,
                        (v) => setState(() => _s = _s.copyWith(workStart: v)))),
                    const SizedBox(width: 12),
                    Expanded(child: _timeField('Fine', _s.workEnd,
                        (v) => setState(() => _s = _s.copyWith(workEnd: v)))),
                  ],
                ),
                const SizedBox(height: 20),

                _sectionLabel('Strategia pause'),
                const SizedBox(height: 10),
                Row(children: [
                  _stratBtn('intensive', '🚀', 'Intensivo'),
                  const SizedBox(width: 8),
                  _stratBtn('balanced', '⚖️', 'Bilanciato'),
                  const SizedBox(width: 8),
                  _stratBtn('gentle', '🌸', 'Leggero'),
                ]),
                const SizedBox(height: 20),

                _sectionLabel('Durata sessione focus'),
                Slider(
                  value: _s.focusSessionMinutes.toDouble(),
                  min: 25,
                  max: 90,
                  divisions: 13,
                  label: '${_s.focusSessionMinutes} min',
                  onChanged: (v) => setState(
                      () => _s = _s.copyWith(focusSessionMinutes: v.round())),
                ),
                Center(
                  child: Text('${_s.focusSessionMinutes} minuti',
                      style: const TextStyle(
                          color: BwColors.teal, fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 16),

                _sectionLabel('Pause corte / lunghe (min)'),
                const SizedBox(height: 10),
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Corta: ${_s.shortBreakMinutes} min',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(.6))),
                        Slider(
                          value: _s.shortBreakMinutes.toDouble(),
                          min: 3,
                          max: 15,
                          divisions: 12,
                          onChanged: (v) => setState(() =>
                              _s = _s.copyWith(shortBreakMinutes: v.round())),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Lunga: ${_s.longBreakMinutes} min',
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white.withOpacity(.6))),
                        Slider(
                          value: _s.longBreakMinutes.toDouble(),
                          min: 10,
                          max: 30,
                          divisions: 20,
                          onChanged: (v) => setState(() =>
                              _s = _s.copyWith(longBreakMinutes: v.round())),
                        ),
                      ],
                    ),
                  ),
                ]),
                const SizedBox(height: 16),

                // Lunch toggle
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BwColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: BwColors.panelBorder),
                  ),
                  child: Row(
                    children: [
                      const Text('🍽️',
                          style: TextStyle(fontSize: 20)),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text('Pausa pranzo',
                            style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 14)),
                      ),
                      Switch(
                        value: _s.lunchEnabled,
                        onChanged: (v) => setState(
                            () => _s = _s.copyWith(lunchEnabled: v)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                ElevatedButton(
                  onPressed: () {
                    context.read<AppProvider>().updatePlannerSettings(_s);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52)),
                  child: const Text('Salva e aggiorna piano'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sectionLabel(String t) => Text(t.toUpperCase(),
      style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: Colors.white.withOpacity(.35),
          letterSpacing: .5));

  Widget _timeField(String label, String value, ValueChanged<String> onChanged) {
    final ctrl = TextEditingController(text: value);
    return TextField(
      controller: ctrl,
      style: const TextStyle(color: Colors.white),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        hintText: 'HH:MM',
        hintStyle: TextStyle(color: Colors.white.withOpacity(.2)),
      ),
    );
  }

  Widget _stratBtn(String key, String emoji, String label) {
    final sel = _s.breakStrategy == key;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _s = _s.copyWith(breakStrategy: key)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: sel ? BwColors.tealLight : Colors.white.withOpacity(.04),
            border: Border.all(
                color: sel ? BwColors.teal : Colors.white.withOpacity(.1)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: sel ? BwColors.teal : Colors.white.withOpacity(.4))),
            ],
          ),
        ),
      ),
    );
  }
}

// Activity Library bottom sheet
class _ActivityLibrarySheet extends StatefulWidget {
  const _ActivityLibrarySheet();
  @override
  State<_ActivityLibrarySheet> createState() => _ActivityLibrarySheetState();
}

class _ActivityLibrarySheetState extends State<_ActivityLibrarySheet> {
  String _search = '';
  String _selectedCategory = 'Tutte';

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(builder: (context, p, _) {
      final cats = ['Tutte', ...p.categories];
      final filtered = p.allActivities.where((a) {
        final matchCat = _selectedCategory == 'Tutte' ||
            a.category == _selectedCategory;
        final matchSearch =
            _search.isEmpty ||
                a.name.toLowerCase().contains(_search.toLowerCase());
        return matchCat && matchSearch;
      }).toList();

      return DraggableScrollableSheet(
        initialChildSize: .9,
        maxChildSize: .95,
        expand: false,
        builder: (_, sc) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Column(
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(.2),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Expanded(
                          child: Text('📚 Libreria Attività',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700)),
                        ),
                        Text('${filtered.length} attività',
                            style: TextStyle(
                                color: Colors.white.withOpacity(.4),
                                fontSize: 12)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      onChanged: (v) => setState(() => _search = v),
                      style: const TextStyle(color: Colors.white),
                      decoration: const InputDecoration(
                        hintText: 'Cerca attività...',
                        prefixIcon:
                            Icon(Icons.search, color: BwColors.textMuted),
                        contentPadding: EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 34,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: cats.length,
                        itemBuilder: (_, i) {
                          final cat = cats[i];
                          final sel = cat == _selectedCategory;
                          return GestureDetector(
                            onTap: () =>
                                setState(() => _selectedCategory = cat),
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12),
                              decoration: BoxDecoration(
                                color: sel
                                    ? BwColors.teal
                                    : Colors.white.withOpacity(.07),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Center(
                                child: Text(
                                  cat.length > 12
                                      ? '${cat.substring(0, 12)}…'
                                      : cat,
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: sel
                                          ? Colors.white
                                          : Colors.white.withOpacity(.5)),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              const Divider(color: BwColors.panelBorder, height: 1),
              Expanded(
                child: ListView.builder(
                  controller: sc,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) {
                    final a = filtered[i];
                    final enabled = p.enabledActivities[a.id] ?? true;
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: BwColors.surface,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: BwColors.panelBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 38,
                            height: 38,
                            decoration: BoxDecoration(
                              color: a.color.withOpacity(.1),
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Center(
                              child: Text(a.emoji,
                                  style: const TextStyle(fontSize: 17)),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(a.name,
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600)),
                                Text(
                                    '${a.durationMinutes} min · +${a.points} pt · ${a.importance}',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(.35),
                                        fontSize: 10)),
                              ],
                            ),
                          ),
                          Switch(
                            value: enabled,
                            onChanged: (v) =>
                                p.toggleActivity(a.id, v),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      );
    });
  }
}
