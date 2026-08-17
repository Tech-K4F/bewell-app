import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../services/feedback_service.dart';
import '../l10n/app_localizations.dart';

String _categoryLabel(BwStrings s, FeedbackCategory c) {
  switch (c) {
    case FeedbackCategory.bug:     return s.feedbackCategoryBug;
    case FeedbackCategory.idea:    return s.feedbackCategoryIdea;
    case FeedbackCategory.feature: return s.feedbackCategoryFeature;
    case FeedbackCategory.other:   return s.feedbackCategoryOther;
  }
}

/// Bottom sheet per l'invio di feedback: categoria + testo libero.
class FeedbackSheet extends StatefulWidget {
  const FeedbackSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FeedbackSheet(),
    );
  }

  @override
  State<FeedbackSheet> createState() => _FeedbackSheetState();
}

class _FeedbackSheetState extends State<FeedbackSheet> {
  FeedbackCategory _category = FeedbackCategory.bug;
  final _textCtrl = TextEditingController();
  bool _sending = false;
  bool _sent = false;

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    final s = context.sL;
    try {
      await FeedbackService.instance.submit(category: _category, text: text);
      if (mounted) setState(() { _sending = false; _sent = true; });
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        setState(() => _sending = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(s.feedbackError),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.read<ThemeProvider>();
    final p = theme.paletteData;
    final isAmb = theme.isAmbient;
    final s = context.sL;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: p.bg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: p.textMut.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            if (_sent)
              _SentState(p: p, isAmb: isAmb, s: s)
            else ...[
              Text(
                s.feedbackTitle,
                style: TextStyle(
                  fontSize: isAmb ? 22 : 18,
                  fontWeight: isAmb ? FontWeight.w300 : FontWeight.w600,
                  fontFamily: isAmb ? 'CormorantGaramond' : null,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                s.feedbackSubtitle,
                style: TextStyle(fontSize: 13, color: p.textSec),
              ),
              const SizedBox(height: 18),

              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: FeedbackCategory.values.map((c) {
                  final selected = c == _category;
                  return GestureDetector(
                    onTap: () => setState(() => _category = c),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: selected ? p.primary : p.card,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: selected ? p.primary : p.cardBorder,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        '${c.emoji} ${_categoryLabel(s, c)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected ? p.btnText : p.textSec,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _textCtrl,
                maxLines: 5,
                minLines: 4,
                maxLength: 500,
                style: TextStyle(fontSize: 14, color: p.text),
                decoration: InputDecoration(
                  hintText: s.feedbackHint,
                  hintStyle: TextStyle(color: p.textMut),
                  filled: true,
                  fillColor: p.card,
                  counterStyle: TextStyle(color: p.textMut, fontSize: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: p.cardBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: p.cardBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: p.primary),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: GestureDetector(
                  onTap: _submit,
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: p.btn,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: _sending
                          ? SizedBox(
                              width: 18, height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2, color: p.btnText),
                            )
                          : Text(
                              s.feedbackSubmit,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: p.btnText,
                              ),
                            ),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SentState extends StatelessWidget {
  final BwPaletteData p;
  final bool isAmb;
  final BwStrings s;
  const _SentState({required this.p, required this.isAmb, required this.s});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Icon(Icons.check_circle_rounded, color: p.primary, size: 40),
          const SizedBox(height: 12),
          Text(
            s.feedbackThanks,
            style: TextStyle(
              fontSize: isAmb ? 18 : 16,
              fontWeight: isAmb ? FontWeight.w300 : FontWeight.w600,
              fontFamily: isAmb ? 'CormorantGaramond' : null,
              color: p.text,
            ),
          ),
        ],
      ),
    );
  }
}
