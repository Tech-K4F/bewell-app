import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import 'package:bewell/utils/validators.dart';

// ── Palette colori auth ────────────────────────────────────────────────────
const _teal = Color(0xFF1E9E87);
const _tealLight = Color(0x1A1E9E87);
const _coral = Color(0xFFE05640);
const _coralLight = Color(0x1AE05640);
const _panel = Color(0xFF0F1F33);
const _panelBorder = Color(0xFF1A2E42);
const _darkPanel = Color(0xFF0B1929);
const _textSecondary = Color(0x99FFFFFF);
const _textMuted = Color(0x40FFFFFF);

// ═══════════════════════════════════════════════════════════════════════════
// BOTTONI SSO
// ═══════════════════════════════════════════════════════════════════════════

class SsoButtonRow extends StatelessWidget {
  final VoidCallback? onGoogle;
  final VoidCallback? onApple;
  final bool enabled;

  const SsoButtonRow({
    super.key,
    this.onGoogle,
    this.onApple,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SsoButton(
            label: 'Google',
            icon: _GoogleIcon(),
            onTap: enabled ? onGoogle : null,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _SsoButton(
            label: 'Apple',
            icon: Icon(Icons.apple, color: context.read<ThemeProvider>().paletteData.text, size: 20),
            onTap: enabled ? onApple : null,
          ),
        ),
      ],
    );
  }
}

class _SsoButton extends StatelessWidget {
  final String label;
  final Widget icon;
  final VoidCallback? onTap;

  const _SsoButton({required this.label, required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = context.read<ThemeProvider>().paletteData;
    final textColor = p.text;
    final bgColor = p.card;
    final borderColor = p.cardBorder;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: onTap == null ? 0.4 : 1.0,
        duration: const Duration(milliseconds: 200),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(width: 20, height: 20, child: icon),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// DIVIDER "oppure con email"
// ═══════════════════════════════════════════════════════════════════════════

class OrDivider extends StatelessWidget {
  const OrDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'oppure con email',
            style: TextStyle(color: Colors.black87.withValues(alpha: 0.3), fontSize: 12),
          ),
        ),
        Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CAMPO EMAIL
// ═══════════════════════════════════════════════════════════════════════════

class BwEmailField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final bool enabled;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;

  const BwEmailField({
    super.key,
    required this.controller,
    this.errorText,
    this.enabled = true,
    this.focusNode,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return _BwTextField(
      controller: controller,
      label: 'Indirizzo email',
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autocorrect: false,
      enabled: enabled,
      focusNode: focusNode,
      onEditingComplete: onEditingComplete,
      errorText: errorText,
      prefixIcon: Icons.email_outlined,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CAMPO PASSWORD
// ═══════════════════════════════════════════════════════════════════════════

class BwPasswordField extends StatefulWidget {
  final TextEditingController controller;
  final String? errorText;
  final bool enabled;
  final String label;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;
  final bool showStrengthBar;

  const BwPasswordField({
    super.key,
    required this.controller,
    this.errorText,
    this.enabled = true,
    this.label = 'Password',
    this.focusNode,
    this.onEditingComplete,
    this.showStrengthBar = false,
  });

  @override
  State<BwPasswordField> createState() => _BwPasswordFieldState();
}

class _BwPasswordFieldState extends State<BwPasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    final strength = widget.showStrengthBar
        ? PasswordStrength.of(widget.controller.text)
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BwTextField(
          controller: widget.controller,
          label: widget.label,
          obscureText: _obscure,
          enabled: widget.enabled,
          focusNode: widget.focusNode,
          onEditingComplete: widget.onEditingComplete,
          textInputAction: TextInputAction.done,
          errorText: widget.errorText,
          prefixIcon: Icons.lock_outline,
          suffixIcon: IconButton(
            icon: Icon(
              _obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
              color: Colors.white.withValues(alpha: 0.25),
              size: 20,
            ),
            onPressed: () => setState(() => _obscure = !_obscure),
          ),
          onChanged: widget.showStrengthBar ? (_) => setState(() {}) : null,
        ),
        if (widget.showStrengthBar && widget.controller.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          _PasswordStrengthBar(strength: strength!),
        ],
      ],
    );
  }
}

class _PasswordStrengthBar extends StatelessWidget {
  final PasswordStrength strength;
  const _PasswordStrengthBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    final color = Color(strength.colorHex);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(4, (i) {
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 3 ? 4 : 0),
                height: 3,
                decoration: BoxDecoration(
                  color: i < strength.score
                      ? color
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 4),
        Text(
          strength.label,
          style: TextStyle(
            fontSize: 11,
            color: color,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CAMPO NOME
// ═══════════════════════════════════════════════════════════════════════════

class BwNameField extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;
  final bool enabled;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;

  const BwNameField({
    super.key,
    required this.controller,
    this.errorText,
    this.enabled = true,
    this.focusNode,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return _BwTextField(
      controller: controller,
      label: 'Il tuo nome',
      keyboardType: TextInputType.name,
      textInputAction: TextInputAction.next,
      enabled: enabled,
      focusNode: focusNode,
      onEditingComplete: onEditingComplete,
      errorText: errorText,
      prefixIcon: Icons.person_outline,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CAMPO BASE CONDIVISO
// ═══════════════════════════════════════════════════════════════════════════

class _BwTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final bool obscureText;
  final bool autocorrect;
  final bool enabled;
  final FocusNode? focusNode;
  final VoidCallback? onEditingComplete;
  final ValueChanged<String>? onChanged;
  final String? errorText;
  final IconData? prefixIcon;
  final Widget? suffixIcon;

  const _BwTextField({
    required this.controller,
    required this.label,
    this.keyboardType,
    this.textInputAction,
    this.obscureText = false,
    this.autocorrect = true,
    this.enabled = true,
    this.focusNode,
    this.onEditingComplete,
    this.onChanged,
    this.errorText,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          obscureText: obscureText,
          autocorrect: autocorrect,
          enabled: enabled,
          focusNode: focusNode,
          onEditingComplete: onEditingComplete,
          onChanged: onChanged,
          style: const TextStyle(color: Colors.white, fontSize: 15),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: prefixIcon != null
                ? Icon(prefixIcon,
                    color: hasError ? _coral : _teal, size: 20)
                : null,
            suffixIcon: suffixIcon,
            labelStyle: TextStyle(
              color: hasError
                  ? _coral
                  : Colors.white.withValues(alpha: 0.5),
              fontSize: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError
                    ? _coral.withValues(alpha: 0.6)
                    : _panelBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: hasError ? _coral : _teal,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _coral),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _coral, width: 1.5),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: _panelBorder.withValues(alpha: 0.3)),
            ),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.04),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 16),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 5),
          Row(
            children: [
              const Icon(Icons.error_outline, color: _coral, size: 13),
              const SizedBox(width: 4),
              Text(
                errorText!,
                style: const TextStyle(color: _coral, fontSize: 11),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BOTTONE PRIMARIO AUTH
// ═══════════════════════════════════════════════════════════════════════════

class BwAuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const BwAuthButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: _teal,
          disabledBackgroundColor: _teal.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SCHERMATA BLOCCO ACCOUNT
// ═══════════════════════════════════════════════════════════════════════════

class AccountLockedWidget extends StatefulWidget {
  final int initialSecondsRemaining;
  final VoidCallback onUnlock;

  const AccountLockedWidget({
    super.key,
    required this.initialSecondsRemaining,
    required this.onUnlock,
  });

  @override
  State<AccountLockedWidget> createState() => _AccountLockedWidgetState();
}

class _AccountLockedWidgetState extends State<AccountLockedWidget> {
  late int _seconds;

  @override
  void initState() {
    super.initState();
    _seconds = widget.initialSecondsRemaining;
    _tick();
  }

  void _tick() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() => _seconds--);
      if (_seconds <= 0) {
        widget.onUnlock();
      } else {
        _tick();
      }
    });
  }

  String get _formatted {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _coralLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _coral.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          const Text('🔒', style: TextStyle(fontSize: 44)),
          const SizedBox(height: 12),
          const Text(
            'Account temporaneamente bloccato',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Troppi tentativi falliti.\nRiprova tra',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          Text(
            _formatted,
            style: const TextStyle(
              color: _coral,
              fontSize: 36,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Hai ricevuto un\'email con le istruzioni.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.4),
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// BANNER OFFLINE
// ═══════════════════════════════════════════════════════════════════════════

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withValues(alpha: 0.12),
        border: Border(
          bottom: BorderSide(color: Colors.orange.withValues(alpha: 0.3)),
        ),
      ),
      child: const Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange, size: 16),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Nessuna connessione — il login richiede internet',
              style: TextStyle(color: Colors.orange, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ICONA GOOGLE
// ═══════════════════════════════════════════════════════════════════════════

class _GoogleIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: const Size(20, 20), painter: _GooglePainter());
  }
}

class _GooglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;
    final paints = [
      Paint()..color = const Color(0xFF4285F4),
      Paint()..color = const Color(0xFF34A853),
      Paint()..color = const Color(0xFFFBBC05),
      Paint()..color = const Color(0xFFEA4335),
    ];
    double startAngle = -0.4;
    for (int i = 0; i < 4; i++) {
      canvas.drawArc(
        Rect.fromCircle(center: c, radius: r - 1),
        startAngle,
        1.57,
        false,
        paints[i]
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
      startAngle += 1.57;
    }
  }

  @override
  bool shouldRepaint(_) => false;
}


