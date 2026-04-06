import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/bw_scaffold.dart';

class PlannerScreen extends StatelessWidget {
  const PlannerScreen({super.key});

  static const _slots = [
    _Slot('09:00', 'Sessione focus', 'Focus', true, false),
    _Slot('10:30', 'Pausa acqua', 'Acqua', true, false),
    _Slot('12:00', 'Pausa pranzo', 'Pausa', false, true),
    _Slot('14:00', 'Focus pomeridiano', 'Focus', false, false),
    _Slot('16:00', 'Stretching attivo', 'Salute', false, false),
    _Slot('18:30', 'Routine pre-sonno', 'Benessere', false, false),
  ];

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        final p = theme.paletteData;
        final isAmb = theme.isAmbient;

        return BwScaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                SizedBox(height: isAmb ? 80 : 0),

                // ── Header ───────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isAmb ? 'oggi, 5 aprile' : 'Oggi, 5 aprile',
                      style: TextStyle(
                        fontSize: isAmb ? 22 : 20,
                        fontWeight:
                            isAmb ? FontWeight.w300 : FontWeight.w600,
                        fontFamily: isAmb ? 'CormorantGaramond' : null,
                        color: p.text,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(
                        color: p.primaryLight,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('4 / 6 completati',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: p.primaryText)),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Slot ────────────────────────────────────────────────
                ..._slots.map((slot) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _SlotCard(slot: slot, p: p, ambient: isAmb),
                    )),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Slot {
  final String time, label, tag;
  final bool done, current;
  const _Slot(this.time, this.label, this.tag, this.done, this.current);
}

class _SlotCard extends StatelessWidget {
  final _Slot slot;
  final BwPaletteData p;
  final bool ambient;

  const _SlotCard(
      {required this.slot, required this.p, required this.ambient});

  @override
  Widget build(BuildContext context) {
    final bg = slot.current
        ? p.primaryLight
        : slot.done
            ? Colors.transparent
            : p.card;
    final border = slot.current
        ? p.primary
        : slot.done
            ? p.cardBorder.withValues(alpha: 0.3)
            : p.cardBorder;

    return Opacity(
      opacity: slot.done ? 0.45 : 1.0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border, width: slot.current ? 1 : 0.5),
        ),
        child: Row(
          children: [
            // Orario
            SizedBox(
              width: 44,
              child: Text(slot.time,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: p.textSec,
                    fontFamily: ambient ? 'CormorantGaramond' : null,
                  )),
            ),
            const SizedBox(width: 10),
            // Titolo
            Expanded(
              child: Text(slot.label,
                  style: TextStyle(
                    fontSize: ambient ? 15 : 14,
                    fontWeight:
                        slot.current ? FontWeight.w600 : FontWeight.w400,
                    fontFamily: ambient ? 'CormorantGaramond' : null,
                    color: p.text,
                    decoration:
                        slot.done ? TextDecoration.lineThrough : null,
                  )),
            ),
            const SizedBox(width: 8),
            // Tag
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: p.bg2,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(slot.tag,
                  style: TextStyle(fontSize: 10, color: p.textSec)),
            ),
            const SizedBox(width: 8),
            // Indicatore
            if (slot.done)
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                    color: p.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check,
                    color: Colors.white, size: 12),
              )
            else if (slot.current)
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      color: p.primary, shape: BoxShape.circle))
            else
              const SizedBox(width: 20),
          ],
        ),
      ),
    );
  }
}
