import 'package:flutter/material.dart';

// ── Palette ────────────────────────────────────────────────────────────────
const _teal = Color(0xFF1E9E87);
const _tealLight = Color(0x1A1E9E87);
const _panel = Color(0xFF0F1F33);
const _panelBorder = Color(0xFF1A2E42);
const _darkPanel = Color(0xFF0B1929);
const _amber = Color(0xFFD99820);
const _amberLight = Color(0x1FD99820);

// ═══════════════════════════════════════════════════════════════════════════
// PROGRESS BAR QUESTIONARIO (1/5 … 5/5)
// ═══════════════════════════════════════════════════════════════════════════

class QuestionnaireProgressBar extends StatelessWidget {
  final int current;   // 1-based
  final int total;
  final String? timeRemaining;

  const QuestionnaireProgressBar({
    super.key,
    required this.current,
    required this.total,
    this.timeRemaining,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              '$current di $total',
              style: TextStyle(
                color: Colors.white.withOpacity(0.4),
                fontSize: 11,
              ),
            ),
            const Spacer(),
            if (timeRemaining != null)
              Text(
                timeRemaining!,
                style: const TextStyle(color: _teal, fontSize: 11),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: current / total,
            backgroundColor: Colors.white.withOpacity(0.07),
            valueColor: const AlwaysStoppedAnimation(_teal),
            minHeight: 3,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// INTESTAZIONE DOMANDA
// ═══════════════════════════════════════════════════════════════════════════

class QuestionLabel extends StatelessWidget {
  final String label;
  final bool optional;

  const QuestionLabel({super.key, required this.label, this.optional = true});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (optional) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'opzionale',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 9,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CARD OPZIONE (single o multi-select)
// ═══════════════════════════════════════════════════════════════════════════

class OptionCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String? sublabel;
  final bool selected;
  final VoidCallback onTap;

  const OptionCard({
    super.key,
    required this.emoji,
    required this.label,
    this.sublabel,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _tealLight : Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? _teal : _panelBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(height: 5),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? _teal : Colors.white.withOpacity(0.7),
              ),
            ),
            if (sublabel != null)
              Text(
                sublabel!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withOpacity(0.3),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// GRID DI OPZIONI (2 colonne di default)
// ═══════════════════════════════════════════════════════════════════════════

class OptionGrid extends StatelessWidget {
  final List<_OptionData> options;
  final String? selected;
  final List<String>? multiSelected;
  final ValueChanged<String> onSelect;
  final int crossAxisCount;

  const OptionGrid({
    super.key,
    required this.options,
    this.selected,
    this.multiSelected,
    required this.onSelect,
    this.crossAxisCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: crossAxisCount,
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 1.1,
      children: options.map((opt) {
        final isSelected = multiSelected != null
            ? multiSelected!.contains(opt.value)
            : selected == opt.value;
        return OptionCard(
          emoji: opt.emoji,
          label: opt.label,
          sublabel: opt.sublabel,
          selected: isSelected,
          onTap: () => onSelect(opt.value),
        );
      }).toList(),
    );
  }
}

class _OptionData {
  final String value;
  final String emoji;
  final String label;
  final String? sublabel;
  const _OptionData(this.value, this.emoji, this.label, [this.sublabel]);
}

// Helper per creare le opzioni
List<_OptionData> options(List<List<String>> data) =>
    data.map((d) => _OptionData(d[0], d[1], d[2], d.length > 3 ? d[3] : null)).toList();

// ═══════════════════════════════════════════════════════════════════════════
// SLIDER CON LABEL
// ═══════════════════════════════════════════════════════════════════════════

class LabeledSlider extends StatelessWidget {
  final String label;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final String Function(double) valueLabel;
  final ValueChanged<double> onChanged;

  const LabeledSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.valueLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: Colors.white.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: _tealLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _teal.withOpacity(0.3)),
              ),
              child: Text(
                valueLabel(value),
                style: const TextStyle(
                    color: _teal, fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
          activeColor: _teal,
          inactiveColor: Colors.white.withOpacity(0.1),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              valueLabel(min),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.25), fontSize: 10),
            ),
            Text(
              valueLabel(max),
              style: TextStyle(
                  color: Colors.white.withOpacity(0.25), fontSize: 10),
            ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TOGGLE CON LABEL (per Q11-Q14 risorse fisiche)
// ═══════════════════════════════════════════════════════════════════════════

class ResourceToggle extends StatelessWidget {
  final String emoji;
  final String label;
  final String sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const ResourceToggle({
    super.key,
    required this.emoji,
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value ? _tealLight : Colors.white.withOpacity(0.03),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? _teal.withOpacity(0.5) : _panelBorder,
          ),
        ),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.35), fontSize: 11),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: _teal,
              trackColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? _teal.withOpacity(0.4)
                      : Colors.white.withOpacity(0.1)),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTTONE NAVIGAZIONE QUESTIONARIO (Next/Back/Skip)
// ═══════════════════════════════════════════════════════════════════════════

class QuestionnaireNavRow extends StatelessWidget {
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkipAll;
  final String nextLabel;
  final bool nextEnabled;

  const QuestionnaireNavRow({
    super.key,
    required this.onNext,
    this.onBack,
    this.onSkipAll,
    this.nextLabel = 'Avanti →',
    this.nextEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: nextEnabled ? onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _teal,
              disabledBackgroundColor: _teal.withOpacity(0.3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              nextLabel,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            if (onBack != null)
              TextButton(
                onPressed: onBack,
                child: Text(
                  '← Indietro',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.35), fontSize: 13),
                ),
              )
            else
              const SizedBox(),
            if (onSkipAll != null)
              TextButton(
                onPressed: onSkipAll,
                child: const Text(
                  'Salta tutto',
                  style: TextStyle(color: _teal, fontSize: 13),
                ),
              ),
          ],
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TIME PICKER COMPATTO (per Q9 orario pranzo)
// ═══════════════════════════════════════════════════════════════════════════

class CompactTimePicker extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final List<String> options;

  const CompactTimePicker({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    required this.options,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                color: Colors.white.withOpacity(0.6), fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _panelBorder),
          ),
          child: DropdownButton<String>(
            value: value,
            onChanged: (v) => v != null ? onChanged(v) : null,
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            style: const TextStyle(color: Colors.white, fontSize: 14),
            dropdownColor: const Color(0xFF0F1F33),
            underline: const SizedBox(),
            icon: const Icon(Icons.expand_more, color: Color(0xFF1E9E87)),
            isExpanded: true,
          ),
        ),
      ],
    );
  }
}
