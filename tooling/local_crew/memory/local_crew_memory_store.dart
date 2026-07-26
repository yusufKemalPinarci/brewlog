import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../crew/memory/crew_memory.dart';

class LocalCrewMemoryStore {
  static const _fileName = 'crew_memory.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<CrewMemory> load() async {
    final file = await _file();
    if (!await file.exists()) return CrewMemory();
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) return CrewMemory();
    return CrewMemory.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> save(CrewMemory memory) async {
    final file = await _file();
    await file.writeAsString(jsonEncode(memory.toJson()));
  }
}
