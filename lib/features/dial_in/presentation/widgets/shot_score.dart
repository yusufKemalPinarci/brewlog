import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/brew_theme.dart';

/// Skor → kısa, eğlenceli unvan (XP/seviye yok).
String shotTitle(int score) {
  if (score >= 9) return 'Efsane';
  if (score >= 7) return 'Güzel shot';
  if (score >= 5) return 'İdare eder';
  return 'Bir daha dene';
}

Color shotAccent(int score) {
  if (score >= 9) return BrewTheme.chartreuse;
  if (score >= 7) return const Color(0xFFD4C46A);
  if (score >= 5) return BrewTheme.mute;
  return BrewTheme.cherry;
}

class ShotScoreBadge extends StatelessWidget {
  const ShotScoreBadge({
    super.key,
    required this.score,
    this.compact = false,
  });

  final int score;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final accent = shotAccent(score);
    final size = compact ? 48.0 : 64.0;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.18),
        border: Border.all(color: accent, width: 2),
      ),
      alignment: Alignment.center,
      child: Text(
        '$score',
        style: GoogleFonts.fraunces(
          fontSize: compact ? 20 : 26,
          fontWeight: FontWeight.w700,
          color: accent,
          height: 1,
        ),
      ),
    );
  }
}

class ShotScoreHero extends StatelessWidget {
  const ShotScoreHero({super.key, required this.score});

  final int score;

  @override
  Widget build(BuildContext context) {
    final accent = shotAccent(score);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$score / 10',
          style: GoogleFonts.fraunces(
            fontSize: 56,
            height: 1,
            color: accent,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          shotTitle(score),
          style: GoogleFonts.figtree(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: accent,
          ),
        ),
      ],
    );
  }
}
