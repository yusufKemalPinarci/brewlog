import '../agent.dart';
import '../crew_context.dart';
import '../tools/base_tool.dart';
import '../tools/brew_tools.dart';
import '../../features/dial_in/domain/entities/brew_method.dart';

class SensoryAgent extends Agent {
  @override
  String get role => 'Sensory Coach';

  @override
  String get goal =>
      'Tat notlarını eyleme çevrilebilir dial-in önerisine dönüştürmek';

  @override
  String get backstory =>
      'Q grader adayı; cupping dilini barista diline çevirir.';

  @override
  List<CrewTool> get tools => const [TasteMapTool()];

  @override
  bool get allowDelegation => true;

  @override
  Future<AgentResult> debate(CrewContext context, int round) async {
    final grind = context.ofRole('Grind Specialist');
    final extraction = context.ofRole('Extraction Analyst');
    final tags = context.current.tasteTags;
    final sour = tags.contains(TasteTag.sour);
    final bitter =
        tags.contains(TasteTag.bitter) || tags.contains(TasteTag.astringent);

    if (sour &&
        (extraction?.suggestions.any((s) => s.contains('Çıkışı artır')) ??
            false)) {
      return AgentResult(
        agentRole: role,
        summary:
            'Sensory → Extraction: Ekşi profilde sadece çıkış yetmez. Önce hafif ince öğütü; yoksa yine ekşi kalır.',
        suggestions: const ['Önce öğütüyü hafif incelterek dene'],
        stance: DebateStance.disagree,
        replyTo: 'Extraction Analyst',
        metrics: {'round': round},
      );
    }

    if (bitter &&
        (grind?.suggestions.any((s) => s.toLowerCase().contains('ince')) ??
            false)) {
      return AgentResult(
        agentRole: role,
        summary:
            'Sensory → Grind: Acı/buruk varken incelme yanlış yön. Kabalaştır veya −2°C.',
        suggestions: const ['Öğütüyü kabalaştır veya −2°C'],
        stance: DebateStance.disagree,
        replyTo: 'Grind Specialist',
        metrics: {'round': round},
      );
    }

    return AgentResult(
      agentRole: role,
      summary:
          'Sensory: Fincandaki his öncelikli. Sayısal hedef tadı bozuyorsa geri alın — uzlaşmaya açığım.',
      suggestions: sour
          ? const ['Sıcaklık +1°C veya biraz daha ince öğütü']
          : bitter
              ? const ['Sıcaklık −1°C veya biraz daha kaba öğütü']
              : const ['Tat dengeliyse tarifi kilitle'],
      stance: DebateStance.compromise,
      replyTo: grind?.agentRole ?? extraction?.agentRole,
      metrics: {'round': round},
    );
  }

  @override
  Future<AgentResult> execute(CrewContext context) async {
    final tags = context.current.tasteTags;
    final toolCalls = <String>[];
    final mapped = await useTool('taste_map', const {}, context);
    if (mapped != null) toolCalls.add('taste_map→${mapped.output}');

    final suggestions = <String>[];
    final parts = <String>[];

    if (tags.isEmpty) {
      return AgentResult(
        agentRole: role,
        summary: 'Tat etiketi yok — bir sonraki demlemede en az 2 tat seç.',
        suggestions: const [
          'Ekşi / acı / tatlı / tuzlu / incelik etiketlerinden seç',
        ],
        toolCalls: toolCalls,
      );
    }

    if (tags.contains(TasteTag.sour) || tags.contains(TasteTag.salty)) {
      parts.add('parlak asidite veya tuzluluk baskın');
      suggestions.addAll(const [
        'Sıcaklığı +1–2°C yükselt',
        'Temas süresini uzat veya öğütüyü incelterek ekstrakte et',
      ]);
    }
    if (tags.contains(TasteTag.bitter) ||
        tags.contains(TasteTag.astringent)) {
      parts.add('acı / buruk taraf öne çıkmış');
      suggestions.addAll(const [
        'Sıcaklığı −1–2°C düşür',
        'Öğütüyü kabalaştır veya oranı yükselt (daha fazla su / çıkış)',
      ]);
    }
    if (tags.contains(TasteTag.sweet) && tags.contains(TasteTag.balanced)) {
      parts.add('tatlılık ve denge iyi');
      suggestions
          .add('Bu tarifi favori olarak kilitle; tek değişkenle ince ayar yap');
    }
    if (tags.contains(TasteTag.thin)) {
      parts.add('gövde ince');
      suggestions.add('Doğu artır veya oranı düşür (daha yoğun demleme)');
    }
    if (tags.contains(TasteTag.heavy)) {
      parts.add('gövde ağır');
      suggestions.add('Oranı yükselt veya çıkışı biraz uzat');
    }
    if (tags.contains(TasteTag.muted)) {
      parts.add('aroma kapalı');
      suggestions.add('Taze öğüt; su sıcaklığını kontrol et; bypass’ı azalt');
    }

    final grind = context.ofRole('Grind Specialist');
    final extraction = context.ofRole('Extraction Analyst');
    if (grind != null && extraction != null) {
      parts.add('Grind + Extraction notları birleştirildi');
    }

    // Prior task context (CrewAI task.context)
    final bundle = context.shared['activeContext'] as String?;
    if (bundle != null && bundle.contains('Extraction')) {
      suggestions.add('Extraction çıktısını sensory ile hizala — tek değişken seç');
    }

    return AgentResult(
      agentRole: role,
      summary: parts.isEmpty
          ? 'Tat profili nötr — küçük adımlarla ilerle.'
          : 'Sensory okuma: ${parts.join('; ')}.',
      suggestions: suggestions.toSet().toList(),
      metrics: {'tags': tags.map((e) => e.name).toList()},
      toolCalls: toolCalls,
    );
  }
}
