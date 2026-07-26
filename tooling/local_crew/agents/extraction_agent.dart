import '../agent.dart';
import '../crew_context.dart';
import '../tools/base_tool.dart';
import '../tools/brew_tools.dart';
import '../../features/dial_in/domain/entities/brew_method.dart';

class ExtractionAgent extends Agent {
  @override
  String get role => 'Extraction Analyst';

  @override
  String get goal => 'Brew ratio ve süre üzerinden ekstraksiyonu okumak';

  @override
  String get backstory =>
      'SCA eğitimli demleme antrenörü; sayısal hedef aralıklarıyla çalışır.';

  @override
  List<CrewTool> get tools => const [RatioCalculatorTool(), EyEstimatorTool()];

  @override
  Future<AgentResult> debate(CrewContext context, int round) async {
    final grind = context.ofRole('Grind Specialist');
    final sensory = context.ofRole('Sensory Coach');
    final d = context.current;
    final grindInsists = grind?.suggestions.any(
          (s) => s.toLowerCase().contains('öğüt'),
        ) ??
        false;

    if (grindInsists &&
        d.method == BrewMethod.espresso &&
        d.ratio > 2.5) {
      return AgentResult(
        agentRole: role,
        summary:
            'Extraction → Grind: Oran 1:${d.ratio.toStringAsFixed(1)} zaten lungo. Öğütüden önce çıkışı 1:2’ye çek — daha ucuz deneme.',
        suggestions: const ['Çıkışı kıs: hedef ~1:2'],
        stance: DebateStance.disagree,
        replyTo: 'Grind Specialist',
        metrics: {'round': round},
      );
    }

    if (sensory?.suggestions.any((s) => s.contains('Sıcaklık')) ?? false) {
      return AgentResult(
        agentRole: role,
        summary:
            'Extraction → Sensory: Sıcaklık EY’yi kaydırır. Önce oran/süre, sıcaklık ikinci tur.',
        suggestions: const ['Oran veya süreyi sabitle, sıcaklığı sonra dene'],
        stance: DebateStance.compromise,
        replyTo: 'Sensory Coach',
        metrics: {'round': round},
      );
    }

    return AgentResult(
      agentRole: role,
      summary:
          'Extraction: 1:${d.ratio.toStringAsFixed(1)} / ${d.brewSeconds}s — tek sayısal aksiyon seçilsin.',
      suggestions: const ['Oranı sabitle; tek değişkenle (öğütü veya süre) ilerle'],
      stance: DebateStance.agree,
      replyTo: grind?.agentRole,
      metrics: {'round': round},
    );
  }

  @override
  Future<AgentResult> execute(CrewContext context) async {
    final d = context.current;
    final toolCalls = <String>[];
    final suggestions = <String>[];

    final ratioTool = await useTool('ratio_calculator', const {}, context);
    final eyTool = await useTool('ey_estimator', const {}, context);
    if (ratioTool != null) toolCalls.add('ratio_calculator→${ratioTool.output}');
    if (eyTool != null) toolCalls.add('ey_estimator→${eyTool.output}');

    final ratio =
        (ratioTool?.data['ratio'] as num?)?.toDouble() ?? d.ratio;
    var summary = 'Oran 1:${ratio.toStringAsFixed(1)} — kayıt alındı.';

    final grind = context.ofRole('Grind Specialist');
    if (grind != null) {
      context.shared['grindAdvice'] = grind.summary;
    }

    switch (d.method) {
      case BrewMethod.espresso:
        if (ratio < 1.5) {
          suggestions.add('Çıkışı artır: hedef ~1:2 (örn. 18g in → 36g out)');
          summary =
              'Espresso oranı çok düşük (ristretto bandı); gövde ağır, şeker eksik kalabilir.';
        } else if (ratio > 2.7) {
          suggestions.add('Çıkışı kıs: hedef ~1:2–1:2.3');
          summary = 'Espresso oranı yüksek (lungo); incelme ve acılık riski.';
        } else {
          summary = 'Espresso oranı dengeli bandda (≈1:2).';
        }
        if (d.brewSeconds < 20) {
          suggestions.add('Süreyi 25–32 sn bandına taşı (öğütü/ince doz)');
        } else if (d.brewSeconds > 40) {
          suggestions.add('Süreyi 25–32 sn’ye indir (daha kaba veya daha az doz)');
        }
      case BrewMethod.v60:
      case BrewMethod.kalita:
      case BrewMethod.origami:
      case BrewMethod.other:
        if (ratio < 14) {
          suggestions.add('Daha fazla su: 1:15–1:17 bandını dene');
          summary = 'Filtre oranı yoğun; tat sıkışık kalabilir.';
        } else if (ratio > 18) {
          suggestions.add('Suyu azalt: 1:15–1:16.5 bandı');
          summary = 'Filtre oranı seyrek; gövde zayıf kalabilir.';
        } else {
          summary = 'Filtre oranı sağlıklı aralıkta.';
        }
      case BrewMethod.aeropress:
        if (ratio < 10 || ratio > 16) {
          suggestions.add('AeroPress için 1:12–1:15 aralığını hedefle');
        }
      case BrewMethod.frenchPress:
        if (ratio < 12 || ratio > 17) {
          suggestions.add('French Press için 1:14–1:16 dene');
        }
      case BrewMethod.moka:
        suggestions
            .add('Moka’da suyu hazne çizgisine kadar doldur; oranı sabit tut');
    }

    final approxEy = (eyTool?.data['approxEy'] as num?)?.toDouble();
    final band = eyTool?.data['band'] as String?;
    if (approxEy != null) {
      context.shared['approxEy'] = approxEy;
      if (band == 'düşük') {
        suggestions
            .add('Ekstraksiyon düşük görünüyor — incel / uzat / sıcaklığı +2°C');
      } else if (band == 'yüksek') {
        suggestions.add(
            'Ekstraksiyon yüksek görünüyor — kabalaştır / kısalt / −2°C');
      }
    }

    if (suggestions.isEmpty) {
      suggestions.add('Oranı sabitle; tek değişkenle (öğütü veya süre) ilerle');
    }

    return AgentResult(
      agentRole: role,
      summary: summary,
      suggestions: suggestions,
      metrics: {
        'ratio': ratio,
        'brewSeconds': d.brewSeconds,
        'approxEy': approxEy,
      },
      toolCalls: toolCalls,
    );
  }
}
