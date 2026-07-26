import '../crew_context.dart';
import 'base_tool.dart';

class RatioCalculatorTool implements CrewTool {
  const RatioCalculatorTool();

  @override
  String get name => 'ratio_calculator';

  @override
  String get description => 'Doz ve verimden brew ratio hesaplar';

  @override
  Future<ToolResult> run(Map<String, Object?> args, CrewContext context) async {
    final dose = (args['dose'] as num?)?.toDouble() ?? context.current.doseGrams;
    final yieldG =
        (args['yield'] as num?)?.toDouble() ?? context.current.yieldGrams;
    if (dose <= 0) {
      return const ToolResult(ok: false, output: 'Doz sıfır olamaz');
    }
    final ratio = yieldG / dose;
    return ToolResult(
      ok: true,
      output: '1:${ratio.toStringAsFixed(2)}',
      data: {'ratio': ratio, 'dose': dose, 'yield': yieldG},
    );
  }
}

class EyEstimatorTool implements CrewTool {
  const EyEstimatorTool();

  @override
  String get name => 'ey_estimator';

  @override
  String get description => 'Yaklaşık ekstraksiyon verimi (EY%) tahmini';

  @override
  Future<ToolResult> run(Map<String, Object?> args, CrewContext context) async {
    final d = context.current;
    if (d.doseGrams <= 0 || d.yieldGrams <= 0) {
      return const ToolResult(ok: false, output: 'Doz/verim eksik');
    }
    final tdsGuess = switch (d.method.name) {
      'espresso' => 9.5,
      'moka' => 6.0,
      'aeropress' => 2.2,
      'frenchPress' => 1.8,
      _ => 1.5,
    };
    final ey = (d.yieldGrams * tdsGuess) / d.doseGrams;
    final band = ey < 18
        ? 'düşük'
        : ey > 22
            ? 'yüksek'
            : 'hedef';
    return ToolResult(
      ok: true,
      output: '≈${ey.toStringAsFixed(1)}% EY ($band)',
      data: {'approxEy': ey, 'band': band, 'tdsGuess': tdsGuess},
    );
  }
}

class HistoryLookupTool implements CrewTool {
  const HistoryLookupTool();

  @override
  String get name => 'history_lookup';

  @override
  String get description => 'Aynı çekirdek+yöntem için en iyi geçmiş kaydı bulur';

  @override
  Future<ToolResult> run(Map<String, Object?> args, CrewContext context) async {
    final current = context.current;
    final peers = context.history
        .where(
          (h) =>
              h.id != current.id &&
              h.beanName.toLowerCase() == current.beanName.toLowerCase() &&
              h.method == current.method,
        )
        .toList()
      ..sort((a, b) => b.score.compareTo(a.score));

    if (peers.isEmpty) {
      return const ToolResult(
        ok: true,
        output: 'Benzer kayıt yok',
        data: {'peerCount': 0},
      );
    }

    final best = peers.first;
    return ToolResult(
      ok: true,
      output:
          'Zirve ${best.score}/10 · ${best.formattedRatio} · ${best.brewSeconds}s · öğütü ${best.grindSetting}',
      data: {
        'peerCount': peers.length,
        'bestScore': best.score,
        'bestId': best.id,
        'bestRatio': best.ratio,
        'bestGrind': best.grindSetting,
        'bestSeconds': best.brewSeconds,
      },
    );
  }
}

class TasteMapTool implements CrewTool {
  const TasteMapTool();

  @override
  String get name => 'taste_map';

  @override
  String get description => 'Tat etiketlerini dial-in aksiyonlarına mapler';

  @override
  Future<ToolResult> run(Map<String, Object?> args, CrewContext context) async {
    final tags = context.current.tasteTags.map((e) => e.name).toSet();
    final actions = <String>[];
    if (tags.contains('sour') || tags.contains('salty')) {
      actions.addAll(['temp+1-2C', 'finer_or_longer']);
    }
    if (tags.contains('bitter') || tags.contains('astringent')) {
      actions.addAll(['temp-1-2C', 'coarser_or_higher_ratio']);
    }
    if (tags.contains('thin')) actions.add('lower_ratio_or_more_dose');
    if (tags.contains('heavy')) actions.add('higher_ratio');
    if (tags.contains('muted')) actions.add('fresher_grind_check_temp');
    if (tags.contains('sweet') && tags.contains('balanced')) {
      actions.add('lock_recipe');
    }
    return ToolResult(
      ok: true,
      output: actions.isEmpty ? 'nötr' : actions.join(', '),
      data: {'actions': actions, 'tags': tags.toList()},
    );
  }
}
