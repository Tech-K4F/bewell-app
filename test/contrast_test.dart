import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bewell/providers/theme_provider.dart';

/// Rapporto di contrasto WCAG tra due colori (1:1 … 21:1).
double contrast(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final hi = la > lb ? la : lb;
  final lo = la > lb ? lb : la;
  return (hi + 0.05) / (lo + 0.05);
}

/// Il colore sopra una superficie semitrasparente si valuta composto.
Color over(Color fg, Color bg) => Color.alphaBlend(fg, bg);

void main() {
  // Soglie WCAG 2.1 AA: 4.5 per il testo normale, 3.0 per testo grande e
  // componenti dell'interfaccia (icone, bordi di controlli).
  const text = 4.5;
  const ui = 3.0;

  for (final entry in kPalettes.entries) {
    final p = entry.value;
    group('contrasto ${entry.key.name}', () {
      // Le superfici semitrasparenti (stile ambient) si valutano composte sullo sfondo.
      final card = Color.alphaBlend(p.card, p.bg);
      final nav = Color.alphaBlend(p.nav, p.bg);
      final primaryLight = Color.alphaBlend(p.primaryLight, p.bg);
      final btn = Color.alphaBlend(p.btn, p.bg);
      void check(String what, Color fg, Color bg, double min) {
        test(what, () {
          final r = contrast(over(fg, bg), bg);
          expect(r, greaterThanOrEqualTo(min),
              reason: '$what: ${r.toStringAsFixed(2)}:1, richiesto $min:1');
        });
      }

      check('testo su sfondo', p.text, p.bg, text);
      check('testo su card', p.text, card, text);
      check('testo secondario su sfondo', p.textSec, p.bg, text);
      check('testo secondario su card', p.textSec, card, text);
      check('testo tenue su sfondo', p.textMut, p.bg, text);
      check('testo tenue su card', p.textMut, card, text);
      check('accento su sfondo', p.accent, p.bg, text);
      check('accento su card', p.accent, card, text);
      check('colore primario su sfondo', p.primary, p.bg, ui);
      check('colore primario su card', p.primary, card, ui);
      check('testo primario su primario chiaro', p.primaryText, primaryLight,
          text);
      check(
          'testo sul colore primario (pillole)', p.onPrimary, p.primary, text);
      check('testo del pulsante su pulsante', p.btnText, btn, text);
      check('icone e testi nav su barra', p.textMut, nav, text);
    });
  }
}
