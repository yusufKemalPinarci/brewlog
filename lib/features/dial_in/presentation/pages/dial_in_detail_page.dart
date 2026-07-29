import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/brew_theme.dart';
import '../../domain/entities/dial_in.dart';
import '../../domain/entities/dial_in_insights.dart';
import '../bloc/dial_in_cubit.dart';
import '../widgets/hint_banner.dart';
import '../widgets/shot_score.dart';
import 'dial_in_editor_page.dart';

class DialInDetailPage extends StatelessWidget {
  const DialInDetailPage({super.key, required this.dialInId});

  final String dialInId;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<DialInCubit, DialInState>(
      builder: (context, state) {
        DialIn? dialIn;
        for (final item in state.items) {
          if (item.id == dialInId) {
            dialIn = item;
            break;
          }
        }

        if (dialIn == null) {
          return Scaffold(
            backgroundColor: BrewTheme.espresso,
            appBar: AppBar(),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Kayıt bulunamadı'),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Geri'),
                  ),
                ],
              ),
            ),
          );
        }

        final d = dialIn;
        final date =
            DateFormat('d MMMM yyyy · HH:mm', 'tr').format(d.createdAt);
        final best = state.bestFor(d);
        final history = state.historyFor(d);
        final previous = state.previousSibling(d);
        final singleVar =
            DialInInsights.singleVariableNote(d, previous);
        final tip = d.tasteActionTip;
        final freshness = d.freshnessTip;

        return Scaffold(
          backgroundColor: BrewTheme.espresso,
          appBar: AppBar(
            title: Text(
              d.beanName,
              style: GoogleFonts.fraunces(fontWeight: FontWeight.w600),
            ),
            actions: [
              IconButton(
                tooltip: 'Favori',
                onPressed: () => context.read<DialInCubit>().toggleFavorite(d),
                icon: Icon(
                  d.isFavorite ? Icons.star : Icons.star_border,
                  color: BrewTheme.chartreuse,
                ),
              ),
              IconButton(
                tooltip: 'Düzenle',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: context.read<DialInCubit>(),
                        child: DialInEditorPage(existing: d),
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.edit_outlined),
              ),
              IconButton(
                tooltip: 'Sil',
                onPressed: () => _confirmDelete(context, d),
                icon: const Icon(Icons.delete_outline),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
            children: [
              Text(date, style: const TextStyle(color: BrewTheme.mute)),
              if (d.roaster.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  d.roaster,
                  style: GoogleFonts.figtree(
                    fontSize: 16,
                    color: BrewTheme.mute,
                  ),
                ),
              ],
              if (d.roastDate != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Kavrum ${DateFormat('d MMM yyyy', 'tr').format(d.roastDate!)}'
                  '${freshness != null ? ' · $freshness' : ''}',
                  style: const TextStyle(
                    color: BrewTheme.mute,
                    fontSize: 13,
                  ),
                ),
              ],
              const SizedBox(height: 24),
              ShotScoreHero(score: d.score),
              const SizedBox(height: 10),
              Text(
                d.method.label,
                style: GoogleFonts.fraunces(fontSize: 22),
              ),
              if (best != null && best.id != d.id) ...[
                const SizedBox(height: 16),
                HintBanner(
                  label: 'Bu çekirdek + yöntemde zirve',
                  body:
                      '${best.score}/10 · ${best.formattedRatio} · öğütü ${best.grindSetting}'
                      '${best.score > d.score ? ' · bu kayıttan yüksek' : ''}',
                  onTap: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => BlocProvider.value(
                          value: context.read<DialInCubit>(),
                          child: DialInDetailPage(dialInId: best.id),
                        ),
                      ),
                    );
                  },
                ),
              ],
              if (singleVar != null) ...[
                const SizedBox(height: 10),
                HintBanner(
                  label: 'Karşılaştırma',
                  body: singleVar,
                  accent: BrewTheme.mute,
                ),
              ],
              if (previous != null) ...[
                const SizedBox(height: 16),
                _SideBySideCompare(current: d, previous: previous),
              ],
              if (history.length >= 2) ...[
                const SizedBox(height: 20),
                Text(
                  'Skor trendi',
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                _ScoreTrend(history: [d, ...history].take(8).toList()),
              ],
              const SizedBox(height: 28),
              _MetricGrid(dialIn: d),
              if (d.ratioBandHint != null) ...[
                const SizedBox(height: 12),
                Text(
                  d.ratioBandHint!,
                  style: GoogleFonts.figtree(
                    fontSize: 13,
                    color: d.ratioBandHint!.contains('dışında')
                        ? BrewTheme.cherry
                        : BrewTheme.mute,
                  ),
                ),
              ],
              if (d.tasteTags.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Tat',
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: d.tasteTags
                      .map(
                        (t) => Chip(
                          label: Text(t.label),
                          backgroundColor: BrewTheme.roast,
                        ),
                      )
                      .toList(),
                ),
              ],
              if (tip != null) ...[
                const SizedBox(height: 12),
                HintBanner(
                  label: 'Sonraki tek değişken',
                  body: tip,
                ),
              ],
              if (d.pourNotes.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Pour',
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(d.pourNotes, style: const TextStyle(height: 1.45)),
              ],
              if (d.waterNote.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Su',
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(d.waterNote, style: const TextStyle(height: 1.45)),
              ],
              if (d.notes.isNotEmpty) ...[
                const SizedBox(height: 24),
                Text(
                  'Notlar',
                  style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(d.notes, style: const TextStyle(height: 1.45)),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () async {
                  final seed = d.asNewAttempt(newId: const Uuid().v4());
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: context.read<DialInCubit>(),
                        child: DialInEditorPage(seed: seed),
                      ),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: BrewTheme.chartreuse,
                  foregroundColor: BrewTheme.espresso,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Bunu tekrar dene'),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmDelete(BuildContext context, DialIn item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: BrewTheme.roast,
        title: Text(
          'Silinsin mi?',
          style: GoogleFonts.fraunces(color: BrewTheme.foam),
        ),
        content: Text(
          '${item.beanName} kaydı gidecek.',
          style: const TextStyle(color: BrewTheme.mute),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: BrewTheme.cherry),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await context.read<DialInCubit>().remove(item.id);
      if (context.mounted) Navigator.of(context).pop();
    }
  }
}

class _SideBySideCompare extends StatelessWidget {
  const _SideBySideCompare({
    required this.current,
    required this.previous,
  });

  final DialIn current;
  final DialIn previous;

  @override
  Widget build(BuildContext context) {
    final rows = [
      (
        'Skor',
        '${current.score}/10',
        '${previous.score}/10',
        current.score != previous.score,
      ),
      (
        'Öğütü',
        current.grindSetting,
        previous.grindSetting,
        current.grindSetting != previous.grindSetting,
      ),
      (
        'Doz',
        '${current.doseGrams} g',
        '${previous.doseGrams} g',
        current.doseGrams != previous.doseGrams,
      ),
      (
        'Oran',
        current.formattedRatio,
        previous.formattedRatio,
        current.formattedRatio != previous.formattedRatio,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Önceki denemeyle',
          style: GoogleFonts.fraunces(
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            color: BrewTheme.roast,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Column(
              children: [
                Row(
                  children: [
                    const Expanded(
                      flex: 2,
                      child: SizedBox.shrink(),
                    ),
                    Expanded(
                      child: Text(
                        'Bu',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.figtree(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BrewTheme.chartreuse,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        'Önceki',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.figtree(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: BrewTheme.mute,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                for (final row in rows) ...[
                  _CompareRow(
                    label: row.$1,
                    current: row.$2,
                    previous: row.$3,
                    changed: row.$4,
                  ),
                  if (row != rows.last) const SizedBox(height: 8),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _CompareRow extends StatelessWidget {
  const _CompareRow({
    required this.label,
    required this.current,
    required this.previous,
    required this.changed,
  });

  final String label;
  final String current;
  final String previous;
  final bool changed;

  @override
  Widget build(BuildContext context) {
    final accent = changed ? BrewTheme.chartreuse : BrewTheme.foam;
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              color: BrewTheme.mute,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            current,
            textAlign: TextAlign.center,
            style: GoogleFonts.fraunces(
              fontSize: 16,
              color: accent,
              fontWeight: changed ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            previous,
            textAlign: TextAlign.center,
            style: GoogleFonts.fraunces(
              fontSize: 16,
              color: changed ? BrewTheme.mute : BrewTheme.foam,
            ),
          ),
        ),
      ],
    );
  }
}

class _ScoreTrend extends StatelessWidget {
  const _ScoreTrend({required this.history});

  final List<DialIn> history;

  @override
  Widget build(BuildContext context) {
    // Yeniden eskiye gösterim için ters çevirmeden: ilk = güncel.
    final items = history;
    return SizedBox(
      height: 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Tooltip(
                message: '${items[i].score}/10',
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: FractionallySizedBox(
                          heightFactor: items[i].score / 10,
                          widthFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: shotAccent(items[i].score)
                                  .withValues(alpha: i == 0 ? 1 : 0.55),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${items[i].score}',
                      style: const TextStyle(
                        fontSize: 10,
                        color: BrewTheme.mute,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.dialIn});

  final DialIn dialIn;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Oran', dialIn.formattedRatio),
      ('Doz', '${dialIn.doseGrams} g'),
      ('Verim', '${dialIn.yieldGrams} g'),
      ('Süre', '${dialIn.brewSeconds} sn'),
      ('Su', '${dialIn.waterTempC} °C'),
      ('Öğütüm', dialIn.grindSetting),
      if (dialIn.grinderName.isNotEmpty) ('Öğütücü', dialIn.grinderName),
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: items
          .map(
            (e) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - 52) / 2,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: BrewTheme.roast,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        e.$1,
                        style: const TextStyle(
                          color: BrewTheme.mute,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        e.$2,
                        style: GoogleFonts.fraunces(fontSize: 20),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}
