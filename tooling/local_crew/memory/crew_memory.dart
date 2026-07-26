/// Long-term crew memory — bean/method learnings, fully local.
class CrewMemory {
  CrewMemory({Map<String, List<String>>? store}) : _store = store ?? {};

  final Map<String, List<String>> _store;

  String _key(String bean, String method) =>
      '${bean.trim().toLowerCase()}|$method';

  List<String> recall(String bean, String method) =>
      List.unmodifiable(_store[_key(bean, method)] ?? const []);

  void remember(String bean, String method, String note) {
    final key = _key(bean, method);
    final list = [...(_store[key] ?? const <String>[])];
    if (!list.contains(note)) {
      list.add(note);
      if (list.length > 12) list.removeAt(0);
      _store[key] = list;
    }
  }

  Map<String, dynamic> toJson() => {
        for (final e in _store.entries) e.key: e.value,
      };

  factory CrewMemory.fromJson(Map<String, dynamic> json) {
    final map = <String, List<String>>{};
    for (final e in json.entries) {
      map[e.key] = (e.value as List<dynamic>).map((v) => '$v').toList();
    }
    return CrewMemory(store: map);
  }
}
