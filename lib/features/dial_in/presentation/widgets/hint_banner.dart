import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/brew_theme.dart';

/// Kısa ipucu / içgörü şeridi.
class HintBanner extends StatelessWidget {
  const HintBanner({
    super.key,
    required this.label,
    required this.body,
    this.onTap,
    this.accent = BrewTheme.chartreuse,
  });

  final String label;
  final String body;
  final VoidCallback? onTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final child = Padding(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.figtree(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: accent,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: GoogleFonts.figtree(
              fontSize: 14,
              height: 1.4,
              color: BrewTheme.foam,
            ),
          ),
        ],
      ),
    );

    return Material(
      color: accent.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(14),
      child: onTap == null
          ? child
          : InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14),
              child: child,
            ),
    );
  }
}
