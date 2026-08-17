import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';

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
    final p = context.read<ThemeProvider>().paletteData;
    return Column(
      children: [
        Row(
          children: [
            Text(
              context.sL.qOfTotal(current, total),
              style: TextStyle(
                color: p.textMut,
                fontSize: 11,
              ),
            ),
            const Spacer(),
            if (timeRemaining != null)
              Text(
                timeRemaining!,
                style: TextStyle(color: p.primary, fontSize: 11),
              ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: current / total,
            backgroundColor: p.cardBorder,
            valueColor: AlwaysStoppedAnimation(p.primary),
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
    final p = context.read<ThemeProvider>().paletteData;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: p.text,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (optional) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: p.cardBorder,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                context.sL.qOptional,
                style: TextStyle(
                  color: p.textMut,
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
    final p = context.read<ThemeProvider>().paletteData;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? p.primaryLight : p.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? p.primary : p.cardBorder,
            width: selected ? 1.5 : 1,
          ),
        ),
        // mainAxisSize.min + Flexible sull'emoji: nelle griglie più strette
        // (4 colonne, aspect ratio 1.0 — Q8, Q21) il budget verticale della
        // cella è al millimetro e bastava un font leggermente più alto per
        // sforare di una frazione di pixel (RenderFlex overflow).
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? p.primary : p.textSec,
              ),
            ),
            if (sublabel != null)
              Text(
                sublabel!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  color: p.textMut,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

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
    final p = context.read<ThemeProvider>().paletteData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                color: p.textSec,
                fontSize: 13,
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: p.primaryLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: p.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                valueLabel(value),
                style: TextStyle(
                    color: p.primary, fontSize: 12, fontWeight: FontWeight.w700),
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
          activeColor: p.primary,
          inactiveColor: p.cardBorder,
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              valueLabel(min),
              style: TextStyle(color: p.textMut, fontSize: 10),
            ),
            Text(
              valueLabel(max),
              style: TextStyle(color: p.textMut, fontSize: 10),
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
    final p = context.read<ThemeProvider>().paletteData;
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: value ? p.primaryLight : p.card,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: value ? p.primary.withValues(alpha: 0.5) : p.cardBorder,
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
                    style: TextStyle(
                        color: p.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                  Text(
                    sublabel,
                    style: TextStyle(color: p.textMut, fontSize: 11),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: p.primary,
              trackColor: WidgetStateProperty.resolveWith((states) =>
                  states.contains(WidgetState.selected)
                      ? p.primary.withValues(alpha: 0.4)
                      : p.cardBorder),
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
    required this.nextLabel,
    this.nextEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    final s = context.sL;
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: nextEnabled ? onNext : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: p.btn,
              disabledBackgroundColor: p.btn.withValues(alpha: 0.3),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              nextLabel,
              style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: p.btnText),
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
                  s.qBack,
                  style: TextStyle(color: p.textMut, fontSize: 13),
                ),
              )
            else
              const SizedBox(),
            if (onSkipAll != null)
              TextButton(
                onPressed: onSkipAll,
                child: Text(
                  s.qSkipAll,
                  style: TextStyle(color: p.primary, fontSize: 13),
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
    final p = context.read<ThemeProvider>().paletteData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(color: p.textSec, fontSize: 12)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: p.cardBorder),
          ),
          child: DropdownButton<String>(
            value: value,
            onChanged: (v) => v != null ? onChanged(v) : null,
            items: options
                .map((o) => DropdownMenuItem(value: o, child: Text(o)))
                .toList(),
            style: TextStyle(color: p.text, fontSize: 14),
            dropdownColor: p.card,
            underline: const SizedBox(),
            icon: Icon(Icons.expand_more, color: p.primary),
            isExpanded: true,
          ),
        ),
      ],
    );
  }
}
