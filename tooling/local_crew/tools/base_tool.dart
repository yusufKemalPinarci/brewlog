import '../crew_context.dart';

/// CrewAI-style tool — agents call these; no network / API keys.
abstract class CrewTool {
  String get name;
  String get description;

  Future<ToolResult> run(Map<String, Object?> args, CrewContext context);
}

class ToolResult {
  const ToolResult({
    required this.ok,
    required this.output,
    this.data = const {},
  });

  final bool ok;
  final String output;
  final Map<String, Object?> data;
}
