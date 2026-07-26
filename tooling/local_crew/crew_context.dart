import '../features/dial_in/domain/entities/dial_in.dart';
import 'agent.dart';
import 'memory/crew_memory.dart';
import 'task.dart';
import 'tools/base_tool.dart';

/// Shared blackboard + short-term memory (CrewAI context).
class CrewContext {
  CrewContext({
    required this.current,
    this.history = const [],
    this.inputs = const {},
    this.longTerm,
    List<CrewTool>? availableTools,
  }) : availableTools = availableTools ?? const [];

  final DialIn current;
  final List<DialIn> history;
  final Map<String, Object?> inputs;
  final CrewMemory? longTerm;
  final List<CrewTool> availableTools;

  final List<AgentResult> shortTerm = [];
  final List<TaskOutput> taskOutputs = [];
  final Map<String, Object?> shared = {};
  final List<String> verboseLog = [];

  /// Legacy alias used by older agent code.
  List<AgentResult> get memory => shortTerm;

  void remember(AgentResult result) {
    shortTerm.add(result);
    shared[result.agentRole] = result.toJson();
    verboseLog.add('[${result.agentRole}] ${result.summary}');
  }

  void rememberTask(TaskOutput output) {
    taskOutputs.add(output);
    shared['task:${output.taskName}'] = {
      'summary': output.summary,
      'suggestions': output.suggestions,
      'agent': output.agentRole,
    };
  }

  AgentResult? ofRole(String role) {
    AgentResult? any;
    for (final item in shortTerm.reversed) {
      if (item.agentRole != role) continue;
      any ??= item;
      if (item.stance == null) return item; // analiz tezi öncelikli
    }
    return any;
  }

  TaskOutput? taskByName(String name) {
    for (final t in taskOutputs.reversed) {
      if (t.taskName == name) return t;
    }
    return null;
  }

  /// Context chain text for dependent tasks.
  String contextBundle(List<CrewTask> deps) {
    if (deps.isEmpty) return '';
    final buf = StringBuffer();
    for (final dep in deps) {
      final out = dep.output ?? taskByName(dep.name);
      if (out == null) continue;
      buf.writeln('## ${dep.name} (${out.agentRole})');
      buf.writeln(out.summary);
      for (final s in out.suggestions) {
        buf.writeln('- $s');
      }
    }
    return buf.toString().trim();
  }

  void logTool(String agentRole, String toolName, ToolResult result) {
    verboseLog.add('  ↳ tool:$toolName → ${result.output}');
    final key = 'tools:$agentRole';
    final prev = (shared[key] as List<dynamic>?) ?? [];
    shared[key] = [...prev, {'tool': toolName, 'output': result.output}];
  }
}
