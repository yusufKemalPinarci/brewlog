import 'agent.dart';
import 'agents/extraction_agent.dart';
import 'agents/grind_agent.dart';
import 'agents/history_agent.dart';
import 'agents/sensory_agent.dart';
import 'crew.dart';
import 'crew_context.dart';
import 'crew_process.dart';
import 'task.dart';
import 'tools/brew_tools.dart';

/// BrewCrew dial-in analizi için hazır crew fabrikası.
class BrewCrewFactory {
  const BrewCrewFactory();

  /// Sıralı süreç + task.context zinciri (CrewAI sequential).
  Crew sequentialDialInCrew({bool verbose = true}) {
    final grind = GrindAgent();
    final extraction = ExtractionAgent();
    final sensory = SensoryAgent();
    final history = HistoryAgent();

    final grindTask = CrewTask(
      name: 'grind_audit',
      description: 'Öğütücü ayarını yöntem ve tada göre değerlendir',
      expectedOutput: 'Öğütü yönü ve net aksiyon',
      agent: grind,
      tools: const [TasteMapTool()],
    );
    final extractionTask = CrewTask(
      name: 'extraction_audit',
      description: 'Oran ve süre üzerinden ekstraksiyonu analiz et',
      expectedOutput: 'Oran/süre bandı ve EY yönü',
      agent: extraction,
      context: [grindTask],
      tools: const [RatioCalculatorTool(), EyEstimatorTool()],
    );
    final sensoryTask = CrewTask(
      name: 'sensory_brief',
      description: 'Tat etiketlerini dial-in aksiyonuna çevir',
      expectedOutput: 'Sensory öncelikli aksiyon listesi',
      agent: sensory,
      context: [grindTask, extractionTask],
      tools: const [TasteMapTool()],
    );
    final historyTask = CrewTask(
      name: 'history_synthesis',
      description: 'Aynı çekirdek geçmişiyle karşılaştır ve sentezle',
      expectedOutput: 'En iyi geçmiş tarif + sonraki adım',
      agent: history,
      context: [grindTask, extractionTask, sensoryTask],
      tools: const [HistoryLookupTool()],
    );

    return Crew(
      process: CrewProcess.sequential,
      verbose: verbose,
      memoryEnabled: true,
      agents: [grind, extraction, sensory, history],
      tasks: [grindTask, extractionTask, sensoryTask, historyTask],
    );
  }

  /// Analiz + 2 tur tartışma + manager kararı.
  Crew debateDialInCrew({bool verbose = true, int rounds = 2}) {
    final manager = ConsensusModerator();
    final base = sequentialDialInCrew(verbose: verbose);
    return Crew(
      process: CrewProcess.debate,
      manager: manager,
      verbose: verbose,
      memoryEnabled: true,
      debateRoundCount: rounds,
      agents: [manager, ...base.agents],
      tasks: base.tasks,
    );
  }

  /// Hiyerarşik: Manager planlar, delege eder, validate eder + tartışma.
  Crew hierarchicalDialInCrew({bool verbose = true}) {
    final manager = CrewManagerAgent();
    final grind = GrindAgent();
    final extraction = ExtractionAgent();
    final sensory = SensoryAgent();
    final history = HistoryAgent();

    final grindTask = CrewTask(
      name: 'grind_audit',
      description: 'Öğütü değerlendirmesi',
      expectedOutput: 'Öğütü aksiyonu',
    );
    final extractionTask = CrewTask(
      name: 'extraction_audit',
      description: 'Ekstraksiyon / oran değerlendirmesi',
      expectedOutput: 'Oran/süre aksiyonu',
      context: [grindTask],
    );
    final sensoryTask = CrewTask(
      name: 'sensory_brief',
      description: 'Sensory / tat sentezi',
      expectedOutput: 'Tat bazlı aksiyon',
      context: [grindTask, extractionTask],
    );
    final historyTask = CrewTask(
      name: 'history_synthesis',
      description: 'Geçmişle karşılaştır',
      expectedOutput: 'Arşiv önerisi',
      context: [sensoryTask],
    );

    return Crew(
      process: CrewProcess.hierarchical,
      manager: manager,
      verbose: verbose,
      memoryEnabled: true,
      debateRoundCount: 2,
      agents: [manager, grind, extraction, sensory, history],
      tasks: [grindTask, extractionTask, sensoryTask, historyTask],
    );
  }
}

class CrewManagerAgent extends Agent {
  @override
  String get role => 'Crew Manager';

  @override
  String get goal => 'Dial-in analizini planlamak, tartışmayı yönetmek, karar vermek';

  @override
  String get backstory =>
      'Kafe şefi; her demlemeyi tek değişken kuralıyla yönetir.';

  @override
  bool get allowDelegation => true;

  @override
  bool get participatesInDebate => false;

  @override
  Future<AgentResult> execute(CrewContext context) async {
    final d = context.current;
    final memoryNotes = context.longTerm?.recall(d.beanName, d.method.name) ??
        const <String>[];
    final plan = StringBuffer(
      'Plan: ${d.beanName} / ${d.method.label} — analiz → tartışma → tek karar.',
    );
    if (memoryNotes.isNotEmpty) {
      plan.write(' Uzun bellek notu: ${memoryNotes.first}.');
    }
    return AgentResult(
      agentRole: role,
      summary: plan.toString(),
      suggestions: const [
        'Tek seferde yalnızca bir değişken değiştir',
        'Delegate: Grind → Extraction → Sensory → History → Debate',
      ],
      metrics: {
        'bean': d.beanName,
        'method': d.method.name,
        'memoryHits': memoryNotes.length,
      },
    );
  }

  @override
  Future<AgentResult> debate(CrewContext context, int round) {
    return ConsensusModerator().debate(context, round);
  }
}
