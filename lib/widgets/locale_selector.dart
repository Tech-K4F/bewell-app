import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/theme_provider.dart';
import '../../l10n/app_localizations.dart';

class LocaleSelector extends StatelessWidget {
  const LocaleSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LocaleProvider>(
      builder: (context, localeProvider, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: BwLocale.values.map((locale) {
            final isSelected = localeProvider.locale == locale;
            return GestureDetector(
              onTap: () => localeProvider.setLocale(locale),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: 36,
                height: 26,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(5),
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [BoxShadow(
                          color: Colors.white.withValues(alpha: 0.2),
                          blurRadius: 6,
                        )]
                      : [],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Center(
                    child: Text(
                      locale.flag,
                      style: TextStyle(
                        fontSize: isSelected ? 18 : 16,
                      ),
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
