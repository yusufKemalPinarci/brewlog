import 'agent.dart';
import 'crew_context.dart';
import 'crew_process.dart';
import 'task.dart';

enum CrewStepKind {
  planning,
  taskStart,
  taskDone,
  validation,
  debate,
  consensus,
  complete,
}

/// Live event while crew runs (CrewAI verbose analog).
class CrewStepEvent {
  const CrewStepEvent({
    required this.kind,
    required this.message,
    this.agentRole,
    this.taskName,
    this.result,
  });

  final CrewStepKind kind;
  final String message;
  final String? agentRole;
  final String? taskName;
  final AgentResult? result;
}

typedef CrewStepListener = void Function(CrewStepEvent event);

/// Final crew report.
class CrewOutput {
  const CrewOutput({
    required this.headline,
    required this.steps,
    required this.nextActions,
    required this.taskOutputs,
    this.verboseLog = const [],
    this.process = CrewProcess.sequential,
    this.consensus,
    this.debateRounds = const [],
  });

  final String headline;
  final List<AgentResult> steps;
  final List<String> nextActions;
  final List<TaskOutput> taskOutputs;
  final List<String> verboseLog;
  final CrewProcess process;
  final AgentResult? consensus;
  final List<AgentResult> debateRounds;
}

/// Orchestrates agents like CrewAI — sequential / hierarchical / debate.
class Crew {
  Crew({
    required this.agents,
    required this.tasks,
    this.process = CrewProcess.sequential,
    this.manager,
    this.verbose = true,
    this.memoryEnabled = true,
    this.debateRoundCount = 2,
    this.stepDelay = const Duration(milliseconds: 280),
  });

  final List<Agent> agents;
  final List<CrewTask> tasks;
  final CrewProcess process;
  final Agent? manager;
  final bool verbose;
  final bool memoryEnabled;
  final int debateRoundCount;
  final Duration stepDelay;

  bool get _wantsDebate =>
      process == CrewProcess.debate || process == CrewProcess.hierarchical;

  Future<CrewOutput> kickoff(
    CrewContext context, {
    CrewStepListener? onStep,
  }) async {
    for (final task in tasks) {
      task.output = null;
    }

    void emit(CrewStepEvent e) {
      if (verbose) context.verboseLog.add('${e.kind.name}: ${e.message}');
      onStep?.call(e);
    }

    final runHierarchical = process == CrewProcess.hierarchical;
    final mgr = manager ?? (runHierarchical ? _fallbackManager() : null);

    if (runHierarchical && mgr != null) {
      emit(CrewStepEvent(
        kind: CrewStepKind.planning,
        message: '${mgr.role} planlıyor…',
        agentRole: mgr.role,
      ));
      await Future<void>.delayed(stepDelay);
      final plan = await mgr.execute(context);
      context.remember(plan);
      emit(CrewStepEvent(
        kind: CrewStepKind.taskDone,
        message: plan.summary,
        agentRole: mgr.role,
        result: plan,
      ));

      for (final task in tasks) {
        task.agent ??= _delegate(mgr, task, context);
      }
    }

    for (final task in tasks) {
      final agent = task.agent;
      if (agent == null) {
        throw StateError('Task "${task.name}" has no agent');
      }

      final bundle = context.contextBundle(task.context);
      if (bundle.isNotEmpty) {
        context.shared['activeContext'] = bundle;
      }
      context.shared['activeTask'] = task.description;
      context.shared['expectedOutput'] = task.expectedOutput;
      context.shared['taskName'] = task.name;

      emit(CrewStepEvent(
        kind: CrewStepKind.taskStart,
        message: '${agent.role}: ${task.description}',
        agentRole: agent.role,
        taskName: task.name,
      ));
      await Future<void>.delayed(stepDelay);

      final result = await agent.execute(context);
      context.remember(result);

      final output = TaskOutput(
        taskName: task.name,
        description: task.description,
        raw: result,
        agentRole: agent.role,
        toolCalls: result.toolCalls,
      );
      task.output = output;
      context.rememberTask(output);

      emit(CrewStepEvent(
        kind: CrewStepKind.taskDone,
        message: result.summary,
        agentRole: agent.role,
        taskName: task.name,
        result: result,
      ));

      if (runHierarchical && mgr != null) {
        final ok = _validate(result, task);
        emit(CrewStepEvent(
          kind: CrewStepKind.validation,
          message: ok
              ? 'Manager onayladı: ${task.name}'
              : 'Manager uyarı: ${task.name} çıktısı zayıf — yine de devam',
          agentRole: mgr.role,
          taskName: task.name,
        ));
        await Future<void>.delayed(stepDelay ~/ 2);
      }
    }

    final debateResults = <AgentResult>[];
    AgentResult? consensus;

    if (_wantsDebate || process == CrewProcess.debate) {
      // Snapshot analysis theses (pre-debate)
      final theses = List<AgentResult>.from(
        context.shortTerm.where((e) => e.stance == null),
      );
      context.shared['debateTheses'] =
          theses.map((e) => e.toJson()).toList();

      emit(CrewStepEvent(
        kind: CrewStepKind.debate,
        message: 'Tartışma masası açıldı — $debateRoundCount tur',
      ));
      await Future<void>.delayed(stepDelay);

      final debaters = agents
          .where((a) => a.participatesInDebate && a.role != mgr?.role)
          .toList();

      for (var round = 1; round <= debateRoundCount; round++) {
        emit(CrewStepEvent(
          kind: CrewStepKind.debate,
          message: 'Tur $round / $debateRoundCount',
        ));
        for (final agent in debaters) {
          await Future<void>.delayed(stepDelay);
          final reply = await agent.debate(context, round);
          debateResults.add(reply);
          context.remember(reply);
          emit(CrewStepEvent(
            kind: CrewStepKind.debate,
            message: reply.summary,
            agentRole: agent.role,
            result: reply,
          ));
        }
      }

      final moderator = mgr ?? ConsensusModerator();
      emit(CrewStepEvent(
        kind: CrewStepKind.consensus,
        message: '${moderator.role} karar veriyor…',
        agentRole: moderator.role,
      ));
      await Future<void>.delayed(stepDelay);
      consensus = await moderator.debate(context, debateRoundCount + 1);
      // Force consensus stance labeling
      consensus = AgentResult(
        agentRole: consensus.agentRole,
        summary: consensus.summary,
        suggestions: consensus.suggestions,
        metrics: {...consensus.metrics, 'final': true},
        stance: DebateStance.agree,
        replyTo: 'crew',
      );
      context.remember(consensus);
      emit(CrewStepEvent(
        kind: CrewStepKind.consensus,
        message: consensus.summary,
        agentRole: consensus.agentRole,
        result: consensus,
      ));
    }

    if (memoryEnabled && context.longTerm != null) {
      final top = consensus?.suggestions.firstOrNull ??
          context.shortTerm.lastOrNull?.suggestions.firstOrNull;
      if (top != null) {
        context.longTerm!.remember(
          context.current.beanName,
          context.current.method.name,
          top,
        );
      }
    }

    final actions = <String>{};
    if (consensus != null) {
      actions.addAll(consensus.suggestions);
    }
    for (final step in debateResults.reversed) {
      actions.addAll(step.suggestions);
    }
    if (actions.isEmpty) {
      for (final step in context.shortTerm) {
        actions.addAll(step.suggestions);
      }
    }

    final headline = consensus?.summary ??
        (context.shortTerm.isEmpty
            ? 'Crew tamamlandı'
            : context.shortTerm.last.summary);

    final output = CrewOutput(
      headline: headline,
      steps: List.unmodifiable(context.shortTerm),
      nextActions: actions.take(8).toList(growable: false),
      taskOutputs: List.unmodifiable(context.taskOutputs),
      verboseLog: List.unmodifiable(context.verboseLog),
      process: process,
      consensus: consensus,
      debateRounds: List.unmodifiable(debateResults),
    );

    emit(CrewStepEvent(
      kind: CrewStepKind.complete,
      message: headline,
      result: consensus,
    ));

    return output;
  }

  Future<List<CrewOutput>> kickoffForEach(
    List<CrewContext> contexts, {
    CrewStepListener? onStep,
  }) async {
    final results = <CrewOutput>[];
    for (final ctx in contexts) {
      results.add(await kickoff(ctx, onStep: onStep));
    }
    return results;
  }

  Agent _delegate(Agent mgr, CrewTask task, CrewContext context) {
    if (task.agent != null) return task.agent!;
    final desc = '${task.description} ${task.name}'.toLowerCase();
    Agent? pick;
    for (final a in agents) {
      if (a.role == mgr.role) continue;
      final role = a.role.toLowerCase();
      if (desc.contains('öğüt') && role.contains('grind')) pick = a;
      if (desc.contains('ekstrak') || desc.contains('oran')) {
        if (role.contains('extraction')) pick = a;
      }
      if (desc.contains('tat') || desc.contains('sensory')) {
        if (role.contains('sensory')) pick = a;
      }
      if (desc.contains('geçmiş') || desc.contains('history')) {
        if (role.contains('history')) pick = a;
      }
    }
    return pick ?? agents.firstWhere((a) => a.role != mgr.role);
  }

  bool _validate(AgentResult result, CrewTask task) {
    if (result.summary.trim().isEmpty) return false;
    if (result.suggestions.isEmpty && task.expectedOutput.isNotEmpty) {
      return false;
    }
    return true;
  }

  Agent _fallbackManager() => ConsensusModerator();
}

/// Tartışma sonrası nihai karar — tek değişken kuralı.
class ConsensusModerator extends Agent {
  @override
  String get role => 'Crew Manager';

  @override
  String get goal => 'Tartışmayı dinleyip tek net aksiyon seçmek';

  @override
  String get backstory => 'Kafe şefi; tartışmayı keser, karar verir.';

  @override
  bool get participatesInDebate => false;

  @override
  Future<AgentResult> execute(CrewContext context) async {
    final d = context.current;
    return AgentResult(
      agentRole: role,
      summary:
          'Plan: ${d.beanName} / ${d.method.label} — analiz, sonra tartışma, sonra tek karar.',
      suggestions: const ['Tek seferde yalnızca bir değişken değiştir'],
    );
  }

  @override
  Future<AgentResult> debate(CrewContext context, int round) async {
    final debates = context.shortTerm.where((e) => e.stance != null).toList();
    final votes = <String, int>{};

    void vote(String action, [int weight = 1]) {
      votes[action] = (votes[action] ?? 0) + weight;
    }

    for (final d in debates) {
      for (final s in d.suggestions) {
        final weight = switch (d.stance) {
          DebateStance.agree => 2,
          DebateStance.compromise => 1,
          DebateStance.disagree => 2,
          null => 1,
        };
        vote(s, weight);
      }
    }

    // Analysis theses as weak votes
    for (final t in context.shortTerm.where((e) => e.stance == null)) {
      if (t.suggestions.isNotEmpty) vote(t.suggestions.first, 1);
    }

    String? winner;
    var best = -1;
    for (final e in votes.entries) {
      if (e.value > best) {
        best = e.value;
        winner = e.key;
      }
    }

    winner ??= 'Öğütüyü 1 kademe ayarla, diğer her şeyi sabitle';

    final disagrees = debates
        .where((e) => e.stance == DebateStance.disagree)
        .map((e) => e.agentRole)
        .toSet()
        .join(', ');

    final summary = disagrees.isEmpty
        ? 'Karar: $winner'
        : 'Tartışma ($disagrees karşı çıktı). Nihai karar — tek değişken: $winner';

    return AgentResult(
      agentRole: role,
      summary: summary,
      suggestions: [winner, 'Bu aksiyonu 1–2 shot tekrarla, sonra yeniden ölç'],
      metrics: {'votes': votes, 'round': round},
      stance: DebateStance.agree,
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }

  E? get lastOrNull {
    E? value;
    for (final e in this) {
      value = e;
    }
    return value;
  }
}
