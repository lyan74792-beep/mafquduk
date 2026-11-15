import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../theme/app_colors.dart';

/// AppBar action displaying a globe icon in [AppColors.govGoldBronze] and the
/// current language name, opening a popup menu of [L10n.supported].
class LanguageMenu extends StatelessWidget {
  const LanguageMenu({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: L10n.instance,
      builder: (context, _) {
        final current = L10n.instance.lang;
        final currentName = L10n.names[current] ?? current;

        return PopupMenuButton<String>(
          tooltip: t('authLanguageSection'),
          initialValue: current,
          onSelected: (code) => L10n.instance.setLanguage(code),
          itemBuilder: (context) => [
            for (final code in L10n.supported)
              PopupMenuItem<String>(
                value: code,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      L10n.names[code] ?? code,
                      style: TextStyle(
                        color: code == current ? AppColors.govGreen : AppColors.textColor,
                        fontWeight: code == current ? FontWeight.w700 : FontWeight.w500,
                      ),
                    ),
                    if (code == current)
                      const Icon(Icons.check_rounded, size: 18, color: AppColors.govGreen),
                  ],
                ),
              ),
          ],
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, color: AppColors.govGoldBronze, size: 20),
                const SizedBox(width: 6),
                Text(
                  currentName,
                  style: const TextStyle(
                    color: AppColors.govGreen,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Icon(Icons.arrow_drop_down, color: AppColors.govGreen, size: 18),
              ],
            ),
          ),
        );
      },
    );
  }
}
