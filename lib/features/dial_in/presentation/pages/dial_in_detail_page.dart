import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

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
            body: const Center(child: Text('Kayıt bulunamadı')),
          );
        }

        final d = dialIn;
        final date = DateFormat('d MMMM yyyy · HH:mm', 'tr').format(d.createdAt);

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
              OutlinedButton(
                onPressed: () async {
                  final copy = d.copyWith(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    createdAt: DateTime.now(),
                    isFavorite: false,
                  );
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => BlocProvider.value(
                        value: context.read<DialInCubit>(),
                        child: DialInEditorPage(existing: copy),
                      ),
                    ),
                  );
                },
                child: const Text('Bunu tekrar dene'),
              ),
            ],
          ),
        );
      },
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
      ('Öğütü', dialIn.grindSetting),
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
