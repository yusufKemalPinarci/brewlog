import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../../domain/entities/dial_in.dart';

abstract class DialInRepository {
  Future<List<DialIn>> getAll();
  Future<void> upsert(DialIn dialIn);
  Future<void> delete(String id);

  /// Tüm kayıtları JSON dizesi olarak dışa aktar.
  Future<String> exportJson();

  /// JSON içe al. [replace] true ise mevcut listeyi tamamen değiştirir.
  /// Dönüş: eklenen/güncellenen kayıt sayısı.
  Future<int> importJson(String raw, {bool replace = false});

  /// Yedek dosyasını uygulama belgelerine yazar; yol döner.
  Future<String> writeBackupFile();
}

class LocalDialInRepository implements DialInRepository {
  LocalDialInRepository();

  static const _fileName = 'dial_ins.json';
  static const _backupName = 'brewlog_backup.json';
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

  @override
  Future<String> exportJson() async {
    final items = await _load();
    return const JsonEncoder.withIndent('  ')
        .convert(items.map((e) => e.toJson()).toList());
  }

  @override
  Future<int> importJson(String raw, {bool replace = false}) async {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw const FormatException('Yedek bir liste olmalı.');
    }
    final imported = decoded
        .map((e) => DialIn.fromJson(e as Map<String, dynamic>))
        .toList();
    if (replace) {
      _cache = [...imported]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      await _persist();
      return imported.length;
    }
    final items = await _load();
    var count = 0;
    for (final item in imported) {
      final index = items.indexWhere((e) => e.id == item.id);
      if (index >= 0) {
        items[index] = item;
      } else {
        items.add(item);
      }
      count++;
    }
    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    _cache = items;
    await _persist();
    return count;
  }

  @override
  Future<String> writeBackupFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/$_backupName';
    final json = await exportJson();
    await File(path).writeAsString(json);
    return path;
  }
}
