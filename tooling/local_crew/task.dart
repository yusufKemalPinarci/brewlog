import 'agent.dart';
import 'tools/base_tool.dart';

/// Structured task result (CrewAI TaskOutput analog).
class TaskOutput {
  const TaskOutput({
    required this.taskName,
    required this.description,
    required this.raw,
    required this.agentRole,
    this.toolCalls = const [],
  });

  final String taskName;
  final String description;
  final AgentResult raw;
  final String agentRole;
  final List<String> toolCalls;

  String get summary => raw.summary;
  List<String> get suggestions => raw.suggestions;
}

/// Unit of work — optional context deps + tools (CrewAI Task).
class CrewTask {
  CrewTask({
    required this.name,
    required this.description,
    required this.expectedOutput,
    this.agent,
    this.context = const [],
    this.tools = const [],
  });

  final String name;
  final String description;
  final String expectedOutput;

  /// Fixed assignee (sequential). Hierarchical may override via manager.
  Agent? agent;

  /// Prior tasks whose outputs feed this task.
  final List<CrewTask> context;

  /// Task-scoped tools (override / add to agent tools).
  final List<CrewTool> tools;

  TaskOutput? output;
}
