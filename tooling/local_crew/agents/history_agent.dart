import '../agent.dart';
import '../crew_context.dart';
import '../tools/base_tool.dart';
import '../tools/brew_tools.dart';

class HistoryAgent extends Agent {
  @override
  String get role => 'History Curator';

  @override
  String get goal =>
      'Geçmiş dial-in’lerden en yüksek skorlu tarifi hatırlatmak';

  @override
  String get backstory =>
      'Kafe lab defteri tutan demleme arşivcisi; tekrarlanabilirliği sever.';

  @override
  List<CrewTool> get tools => const [HistoryLookupTool()];

  @override
  Future<AgentResult> debate(CrewContext context, int round) async {
    final sensory = context.ofRole('Sensory Coach');
    final extraction = context.ofRole('Extraction Analyst');
    final lookup = await useTool('history_lookup', const {}, context);
    final peerCount = (lookup?.data['peerCount'] as num?)?.toInt() ?? 0;

    if (peerCount == 0) {
      return AgentResult(
        agentRole: role,
        summary:
            'History → herkes: Arşiv boş. Kazanan aksiyonu 2 shot tekrarlamanız lazım — yoksa veri yok.',
        suggestions: const ['Kazanan aksiyonu 2 shot tekrarla, sonra değiştir'],
        stance: DebateStance.agree,
        metrics: {'round': round, 'peerCount': 0},
        toolCalls: lookup != null ? ['history_lookup→${lookup.output}'] : const [],
      );
    }

    return AgentResult(
      agentRole: role,
      summary:
          'History: Sensory ile Extraction çatışırsa yüksek skorlu kayıttaki değişkeni seçin. Kör inovasyona veto.',
      suggestions: const [
        'En yüksek skorlu kayıttaki öğütü/oranı referans al',
      ],
      stance: DebateStance.compromise,
      replyTo: sensory?.agentRole ?? extraction?.agentRole,
      metrics: {'round': round, 'peerCount': peerCount},
      toolCalls: lookup != null ? ['history_lookup→${lookup.output}'] : const [],
    );
  }

  @override
  Future<AgentResult> execute(CrewContext context) async {
    final current = context.current;
    final toolCalls = <String>[];
    final lookup = await useTool('history_lookup', const {}, context);
    if (lookup != null) toolCalls.add('history_lookup→${lookup.output}');

    final peerCount = (lookup?.data['peerCount'] as num?)?.toInt() ?? 0;
    final longTerm = context.longTerm?.recall(
          current.beanName,
          current.method.name,
        ) ??
        const <String>[];

    if (peerCount == 0) {
      final suggestions = <String>[
        'Aynı tarifi 2–3 kez tekrarla; sonra tek değişken değiştir',
        ...longTerm.take(2),
      ];
      return AgentResult(
        agentRole: role,
        summary:
            '"${current.beanName}" için bu yöntemde geçmiş kayıt yok — bu ilk referansın.',
        suggestions: suggestions,
        metrics: {'peerCount': 0, 'longTermNotes': longTerm.length},
        toolCalls: toolCalls,
      );
    }

    final bestScore = (lookup!.data['bestScore'] as num).toInt();
    final suggestions = <String>[
      'En iyi skor $bestScore/10 — ${lookup.output}',
    ];

    if (bestScore >= current.score + 2) {
      suggestions.add(
        'Mevcut skordan yüksek geçmiş var; o tarife yaklaşmayı dene',
      );
    } else if (current.score >= bestScore) {
      suggestions.add('Bu kayıt kişisel rekor bandında — favorilere ekle');
    }

    final sensory = context.ofRole('Sensory Coach');
    if (sensory != null && sensory.suggestions.isNotEmpty) {
      suggestions.add('Sensory önceliği: ${sensory.suggestions.first}');
    }

    for (final note in longTerm.take(2)) {
      suggestions.add('Uzun bellek: $note');
    }

    return AgentResult(
      agentRole: role,
      summary:
          '$peerCount benzer kayıt. ${lookup.output}.',
      suggestions: suggestions,
      metrics: {
        'peerCount': peerCount,
        'bestScore': bestScore,
        'bestId': lookup.data['bestId'],
        'longTermNotes': longTerm.length,
      },
      toolCalls: toolCalls,
    );
  }
}
