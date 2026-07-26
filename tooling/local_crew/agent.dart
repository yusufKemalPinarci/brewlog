import 'crew_context.dart';
import 'tools/base_tool.dart';

enum DebateStance { agree, disagree, compromise }

/// Single agent output, appended to shared crew memory.
class AgentResult {
  const AgentResult({
    required this.agentRole,
    required this.summary,
    this.suggestions = const [],
    this.metrics = const {},
    this.toolCalls = const [],
    this.stance,
    this.replyTo,
  });

  final String agentRole;
  final String summary;
  final List<String> suggestions;
  final Map<String, Object?> metrics;
  final List<String> toolCalls;
  final DebateStance? stance;
  final String? replyTo;

  Map<String, dynamic> toJson() => {
        'agentRole': agentRole,
        'summary': summary,
        'suggestions': suggestions,
        'metrics': metrics,
        'toolCalls': toolCalls,
        'stance': stance?.name,
        'replyTo': replyTo,
      };
}

/// Role-playing agent with tools + optional debate turn.
abstract class Agent {
  String get role;
  String get goal;
  String get backstory;

  List<CrewTool> get tools => const [];

  bool get allowDelegation => false;

  /// Katılır mı tartışmaya? Manager genelde dinler / sentezler.
  bool get participatesInDebate => true;

  Future<AgentResult> execute(CrewContext context);

  /// Diğer agent çıktılarına cevap — varsayılan nötr uzlaşma.
  Future<AgentResult> debate(CrewContext context, int round) async {
    final others = context.shortTerm
        .where((e) => e.agentRole != role && e.stance == null)
        .toList();
    if (others.isEmpty) {
      return AgentResult(
        agentRole: role,
        summary: '$role: Henüz tartışılacak tez yok.',
        stance: DebateStance.agree,
      );
    }

    final target = others[(round + role.hashCode).abs() % others.length];
    final tip = target.suggestions.isNotEmpty
        ? target.suggestions.first
        : target.summary;

    return AgentResult(
      agentRole: role,
      summary: '$role → ${target.agentRole}: “$tip” notunu gördüm; tek değişken kuralına uyar.',
      suggestions: target.suggestions.take(1).toList(),
      stance: DebateStance.compromise,
      replyTo: target.agentRole,
      metrics: {'round': round},
    );
  }

  Future<ToolResult?> useTool(
    String toolName,
    Map<String, Object?> args,
    CrewContext context, {
    List<CrewTool> extraTools = const [],
  }) async {
    final all = <CrewTool>[...tools, ...extraTools, ...context.availableTools];
    CrewTool? tool;
    for (final t in all) {
      if (t.name == toolName) {
        tool = t;
        break;
      }
    }
    if (tool == null) return null;
    final result = await tool.run(args, context);
    context.logTool(role, toolName, result);
    return result;
  }
}
