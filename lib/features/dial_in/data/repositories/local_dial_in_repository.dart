import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/dial_in.dart';

abstract class DialInRepository {
  Future<List<DialIn>> getAll();
  Future<void> upsert(DialIn dialIn);
  Future<void> delete(String id);
}

class LocalDialInRepository implements DialInRepository {
  LocalDialInRepository();

  static const _fileName = 'dial_ins.json';
  List<DialIn>? _cache;

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  Future<List<DialIn>> _load() async {
    if (_cache != null) return _cache!;
    final file = await _file();
    if (!await file.exists()) {
      _cache = [];
      return _cache!;
    }
    final raw = await file.readAsString();
    if (raw.trim().isEmpty) {
      _cache = [];
      return _cache!;
    }
    final list = jsonDecode(raw) as List<dynamic>;
    _cache = list
        .map((e) => DialIn.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return _cache!;
  }

  Future<void> _persist() async {
    final file = await _file();
    final encoded = jsonEncode(_cache!.map((e) => e.toJson()).toList());
    await file.writeAsString(encoded);
  }

  @override
  Future<List<DialIn>> getAll() => _load();

  @override
  Future<void> upsert(DialIn dialIn) async {
    final items = await _load();
    final index = items.indexWhere((e) => e.id == dialIn.id);
    if (index >= 0) {
      items[index] = dialIn;
    } else {
      items.insert(0, dialIn);
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _cache = items;
    await _persist();
  }

  @override
  Future<void> delete(String id) async {
    final items = await _load();
    items.removeWhere((e) => e.id == id);
    _cache = items;
    await _persist();
  }
}
