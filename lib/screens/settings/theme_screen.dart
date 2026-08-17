import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../widgets/bw_scaffold.dart';

class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, theme, _) {
        final p = theme.paletteData;
        final s = context.sL;
        return BwScaffold(
          appBar: AppBar(
            backgroundColor: p.bg,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: p.text, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              s.appearance,
              style: TextStyle(
                color: p.text,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [

              // ── Sezione stile ─────────────────────────────────────────────
              _SectionLabel(label: s.themeTitle, color: p.textSec),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _StyleCard(
                      label: s.themeCard,
                      description: s.styleCardDesc,
                      selected: theme.style == BwStyle.card,
                      palette: theme.palette,
                      style: BwStyle.card,
                      onTap: () => theme.setStyle(BwStyle.card),
                      currentPaletteData: p,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _StyleCard(
                      label: s.themeAmbient,
                      description: s.styleAmbientDesc,
                      selected: theme.style == BwStyle.ambient,
                      palette: theme.palette,
                      style: BwStyle.ambient,
                      onTap: () => theme.setStyle(BwStyle.ambient),
                      currentPaletteData: p,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // ── Sezione palette ───────────────────────────────────────────
              _SectionLabel(label: s.toneSection, color: p.textSec),
              const SizedBox(height: 12),
              ...BwPalette.values.map((pal) {
                final pd = kPalettes[pal]!;
                final isSelected = theme.palette == pal;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _PaletteRow(
                    data: pd,
                    selected: isSelected,
                    currentP: p,
                    onTap: () => theme.setPalette(pal),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }
}

// ── Style Card con miniatura preview ────────────────────────────────────────
class _StyleCard extends StatelessWidget {
  final String label;
  final String description;
  final bool selected;
  final BwPalette palette;
  final BwStyle style;
  final VoidCallback onTap;
  final BwPaletteData currentPaletteData;

  const _StyleCard({
    required this.label,
    required this.description,
    required this.selected,
    required this.palette,
    required this.style,
    required this.onTap,
    required this.currentPaletteData,
  });

  @override
  Widget build(BuildContext context) {
    final p = currentPaletteData;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? p.primary : p.cardBorder,
            width: selected ? 2 : 0.5,
          ),
          boxShadow: selected
              ? [BoxShadow(color: p.primary.withValues(alpha: 0.15), blurRadius: 12, spreadRadius: 2)]
              : [],
        ),
        child: Column(
          children: [
            // Preview miniatura
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: SizedBox(
                height: 160,
                child: style == BwStyle.card
                    ? _CardPreview(p: kPalettes[palette]!)
                    : _AmbientPreview(p: kPalettes[palette]!),
              ),
            ),
            // Label e check
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: TextStyle(
                              color: p.text,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            )),
                        const SizedBox(height: 2),
                        Text(description,
                            style: TextStyle(
                              color: p.textSec,
                              fontSize: 10,
                              height: 1.4,
                            )),
                      ],
                    ),
                  ),
                  if (selected)
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: p.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check, color: Colors.white, size: 14),
                    )
                  else
                    Container(
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: p.cardBorder, width: 1.5),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Palette Row ──────────────────────────────────────────────────────────────
class _PaletteRow extends StatelessWidget {
  final BwPaletteData data;
  final bool selected;
  final BwPaletteData currentP;
  final VoidCallback onTap;

  const _PaletteRow({
    required this.data,
    required this.selected,
    required this.currentP,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? currentP.primaryLight : currentP.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? currentP.primary : currentP.cardBorder,
            width: selected ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // Swatch colori palette
            Row(
              children: [
                _Swatch(color: data.bg, size: 20),
                const SizedBox(width: 4),
                _Swatch(color: data.primary, size: 20),
                const SizedBox(width: 4),
                _Swatch(color: data.accent, size: 20),
              ],
            ),
            const SizedBox(width: 14),
            // Nome
            Expanded(
              child: Text(
                data.name,
                style: TextStyle(
                  color: currentP.text,
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            // Check
            if (selected)
              Icon(Icons.check_circle_rounded, color: currentP.primary, size: 20)
            else
              Icon(Icons.circle_outlined, color: currentP.textMut, size: 20),
          ],
        ),
      ),
    );
  }
}

class _Swatch extends StatelessWidget {
  final Color color;
  final double size;
  const _Swatch({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12, width: 0.5),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionLabel({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
        color: color,
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.5,
      ),
    );
  }
}

// ── Preview miniature ────────────────────────────────────────────────────────

class _CardPreview extends StatelessWidget {
  final BwPaletteData p;
  const _CardPreview({required this.p});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: p.bg,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Buongiorno,', style: TextStyle(fontSize: 7, color: p.textSec)),
                  Text('Marco', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: p.text)),
                ],
              ),
              const Spacer(),
              CircleAvatar(radius: 10, backgroundColor: p.primaryLight,
                  child: Text('M', style: TextStyle(fontSize: 8, color: p.primaryText, fontWeight: FontWeight.w600))),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.cardBorder, width: 0.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sessione focus', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: p.text)),
                Text('25 min · Pomodoro', style: TextStyle(fontSize: 7, color: p.textSec)),
                const SizedBox(height: 5),
                Container(
                  height: 22,
                  decoration: BoxDecoration(
                    color: p.btn,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Center(child: Text('Inizia sessione',
                      style: TextStyle(fontSize: 7, color: p.btnText, fontWeight: FontWeight.w600))),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: p.cardBorder, width: 0.5),
            ),
            child: Row(
              children: [
                Text('Acqua', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: p.text)),
                const Spacer(),
                Text('50%', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: p.accent)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AmbientPreview extends StatelessWidget {
  final BwPaletteData p;
  const _AmbientPreview({required this.p});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _AmbientPainter(p: p),
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 44, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('buongiorno,',
                style: TextStyle(
                  fontSize: 7,
                  fontStyle: FontStyle.italic,
                  color: p.textSec,
                  fontFamily: 'serif',
                )),
            Text('Marco',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: p.text,
                )),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 56,
                height: 56,
                child: CustomPaint(painter: _RingPainter(p: p)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AmbientPainter extends CustomPainter {
  final BwPaletteData p;
  const _AmbientPainter({required this.p});

  @override
  void paint(Canvas canvas, Size size) {
    // Sfondo
    canvas.drawRect(Offset.zero & size, Paint()..color = p.bg);

    if (p.isDark) {
      // Cielo notturno
      final paint = Paint()..color = const Color(0xFF0D1520);
      canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 40), paint);
      // Stelle
      final starPaint = Paint()..color = const Color(0xFFC8E0D8);
      for (int i = 0; i < 12; i++) {
        final x = (i * 47.3) % size.width;
        final y = (i * 13.1) % 36;
        canvas.drawCircle(Offset(x, y), 0.8, starPaint..color = const Color(0xFFC8E0D8));
      }
      // Luna
      canvas.drawCircle(const Offset(110, 14), 8, Paint()..color = const Color(0xFF1A3048));
      canvas.drawCircle(const Offset(112, 12), 7, Paint()..color = const Color(0xFFC4D8E8));
      canvas.drawCircle(const Offset(115, 10), 6, Paint()..color = const Color(0xFF0D1520));
      // Montagne
      final path = Path()
        ..moveTo(0, 32)
        ..quadraticBezierTo(size.width * 0.3, 14, size.width * 0.5, 24)
        ..quadraticBezierTo(size.width * 0.7, 10, size.width, 22)
        ..lineTo(size.width, 40)
        ..lineTo(0, 40);
      canvas.drawPath(path, Paint()..color = const Color(0xFF162238));
    } else {
      // Cielo alba
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, 40),
        Paint()..color = const Color(0xFFEDE5D8),
      );
      // Sole
      canvas.drawCircle(Offset(size.width / 2, -4), 16, Paint()..color = const Color(0x4DF0C870));
      canvas.drawCircle(Offset(size.width / 2, -4), 9, Paint()..color = const Color(0x80EAB840));
      // Colline
      final path = Path()
        ..moveTo(0, 28)
        ..quadraticBezierTo(size.width * 0.25, 12, size.width * 0.45, 22)
        ..quadraticBezierTo(size.width * 0.65, 10, size.width, 20)
        ..lineTo(size.width, 40)
        ..lineTo(0, 40);
      canvas.drawPath(path, Paint()..color = const Color(0x80C4B498));
    }

    // Sfumatura verso il basso
    final grad = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [p.bg.withValues(alpha: 0), p.bg],
        stops: const [0.3, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, 40));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, 40), grad);
  }

  @override
  bool shouldRepaint(_AmbientPainter old) => old.p != p;
}

class _RingPainter extends CustomPainter {
  final BwPaletteData p;
  const _RingPainter({required this.p});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    canvas.drawCircle(center, radius,
        Paint()
          ..color = p.ringTrack
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3);

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -1.5708, // -90°
      1.884,   // ~108° = 30% del cerchio
      false,
      Paint()
        ..color = p.ring
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: '25',
        style: TextStyle(color: p.text, fontSize: 14, fontWeight: FontWeight.w300),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.p != p;
}




