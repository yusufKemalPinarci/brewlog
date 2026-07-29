import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/theme/brew_theme.dart';
import '../../domain/entities/dial_in.dart';
import '../bloc/dial_in_cubit.dart';
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
              const SizedBox(height: 24),
              ShotScoreHero(score: d.score),
              const SizedBox(height: 10),
              Text(
                d.method.label,
                style: GoogleFonts.fraunces(fontSize: 22),
              ),
              const SizedBox(height: 28),
              _MetricGrid(dialIn: d),
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
