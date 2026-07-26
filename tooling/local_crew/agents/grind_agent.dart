import '../agent.dart';
import '../crew_context.dart';
import '../tools/base_tool.dart';
import '../tools/brew_tools.dart';
import '../../features/dial_in/domain/entities/brew_method.dart';

class GrindAgent extends Agent {
  @override
  String get role => 'Grind Specialist';

  @override
  String get goal =>
      'Öğütücü ayarını demleme yöntemine ve tadıma göre netleştirmek';

  @override
  String get backstory =>
      'On yıllık barista; öğütücü kalibrasyonu ve parçacık boyutu uzmanı.';

  @override
  List<CrewTool> get tools => const [TasteMapTool()];

  @override
  Future<AgentResult> debate(CrewContext context, int round) async {
    final extraction = context.ofRole('Extraction Analyst');
    final sensory = context.ofRole('Sensory Coach');
    final d = context.current;

    final extWantsRatio = extraction?.suggestions.any(
          (s) =>
              s.toLowerCase().contains('oran') ||
              s.toLowerCase().contains('çıkış'),
        ) ??
        false;
    final sensoryWantsGrind = sensory?.suggestions.any(
          (s) =>
              s.toLowerCase().contains('öğüt') ||
              s.toLowerCase().contains('ince') ||
              s.toLowerCase().contains('kaba'),
        ) ??
        false;

    if (sensoryWantsGrind && extWantsRatio) {
      return AgentResult(
        agentRole: role,
        summary:
            'Grind → Extraction: İkiniz birden oynayamazsınız. Önce öğütü 1 tık; oran sonraki shot.',
        suggestions: const ['Önce öğütü (tek değişken), oranı sabitle'],
        stance: DebateStance.disagree,
        replyTo: 'Extraction Analyst',
        metrics: {'round': round},
      );
    }

    if (d.tasteTags.contains(TasteTag.bitter) &&
        (sensory?.suggestions.any((s) => s.contains('ince')) ?? false)) {
      return AgentResult(
        agentRole: role,
        summary:
            'Grind → Sensory: Acıyken incelme olmaz. Kabalaştırıyorum — itirazım var.',
        suggestions: const ['Öğütüyü 1–2 tık kabalaştır'],
        stance: DebateStance.disagree,
        replyTo: 'Sensory Coach',
        metrics: {'round': round},
      );
    }

    return AgentResult(
      agentRole: role,
      summary:
          'Grind: Parçacık boyutu en temiz sinyal. ${d.method.label} için öğütü öncelikli kalsın.',
      suggestions: const ['Öğütüyü 1 kademe ayarla, diğer her şeyi sabitle'],
      stance: DebateStance.agree,
      replyTo: sensory?.agentRole,
      metrics: {'round': round},
    );
  }

  @override
  Future<AgentResult> execute(CrewContext context) async {
    final d = context.current;
    final toolCalls = <String>[];
    final taste = await useTool('taste_map', const {}, context);
    if (taste != null) toolCalls.add('taste_map→${taste.output}');

    final suggestions = <String>[];
    var summary = 'Öğütücü ayarı ${d.grindSetting} makul görünüyor.';

    final prior = context.shared['activeContext'] as String?;
    if (prior != null && prior.isNotEmpty) {
      context.shared['grindSawContext'] = true;
    }

    switch (d.method) {
      case BrewMethod.espresso:
        if (d.tasteTags.contains(TasteTag.sour) &&
            d.tasteTags.contains(TasteTag.thin)) {
          suggestions.add('Öğütüyü 1–2 tık incelterek asiditeyi dengele');
          summary =
              'Espresso için öğütü biraz kaba; ekstraksiyon kısa kalmış olabilir.';
        } else if (d.tasteTags.contains(TasteTag.bitter) ||
            d.tasteTags.contains(TasteTag.astringent)) {
          suggestions.add('Öğütüyü 1–2 tık kabalaştır');
          summary =
              'Espresso aşırı ince öğütüye kaymış; acılık/burukluk baskın.';
        }
      case BrewMethod.v60:
      case BrewMethod.kalita:
      case BrewMethod.origami:
        if (d.brewSeconds < 150) {
          suggestions
              .add('Öğütüyü incelterek total süreyi ~2:30–3:30 bandına çek');
          summary = 'Filtre demlemesi hızlı bitmiş; öğütü kaba olabilir.';
        } else if (d.brewSeconds > 240) {
          suggestions.add('Öğütüyü kabalaştırarak tıkanmayı azalt');
          summary = 'Filtre süresi uzun; ince öğütü veya ince yatak şüphesi.';
        }
      case BrewMethod.aeropress:
      case BrewMethod.frenchPress:
      case BrewMethod.moka:
      case BrewMethod.other:
        if (d.tasteTags.contains(TasteTag.sour)) {
          suggestions.add('Bir kademe daha ince öğüt');
        } else if (d.tasteTags.contains(TasteTag.bitter)) {
          suggestions.add('Bir kademe daha kaba öğüt');
        }
    }

    final actions = (taste?.data['actions'] as List<dynamic>?) ?? [];
    if (actions.contains('finer_or_longer') &&
        !suggestions.any((s) => s.contains('ince'))) {
      suggestions.add('Taste map: incelterek veya süreyi uzatarak ilerle');
    }
    if (actions.contains('coarser_or_higher_ratio') &&
        !suggestions.any((s) => s.contains('kaba'))) {
      suggestions.add('Taste map: kabalaştır veya oranı yükselt');
    }

    if (suggestions.isEmpty) {
      suggestions
          .add('Öğütüyü sabitleyip bir sonraki shot’ta sadece oranı değiştir');
    }

    return AgentResult(
      agentRole: role,
      summary: summary,
      suggestions: suggestions,
      metrics: {'grindSetting': d.grindSetting},
      toolCalls: toolCalls,
    );
  }
}
