import 'brew_method.dart';
import 'dial_in.dart';

/// Yerel içgörü ve hafıza — cihaz verisinden türetilir.
class DialInInsights {
  DialInInsights._();

  static bool _sameBeanMethod(DialIn a, String bean, BrewMethod method) {
    return a.beanName.trim().toLowerCase() == bean.trim().toLowerCase() &&
        a.method == method;
  }

  /// Aynı çekirdek + yöntem için en yüksek skorlu kayıt (isteğe bağlı hariç tut).
  static DialIn? bestForBeanMethod(
    List<DialIn> all, {
    required String beanName,
    required BrewMethod method,
    String? excludeId,
  }) {
    final bean = beanName.trim();
    if (bean.isEmpty) return null;
    DialIn? best;
    for (final item in all) {
      if (excludeId != null && item.id == excludeId) continue;
      if (!_sameBeanMethod(item, bean, method)) continue;
      if (best == null || item.score > best.score) best = item;
    }
    return best;
  }

  /// Aynı çekirdek + yöntem geçmişi (yeniden eskiye), en fazla [limit].
  static List<DialIn> historyForBeanMethod(
    List<DialIn> all, {
    required String beanName,
    required BrewMethod method,
    String? excludeId,
    int limit = 8,
  }) {
    final bean = beanName.trim();
    if (bean.isEmpty) return const [];
    final list = all
        .where(
          (e) =>
              (excludeId == null || e.id != excludeId) &&
              _sameBeanMethod(e, bean, method),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (list.length <= limit) return list;
    return list.sublist(0, limit);
  }

  /// Bir önceki denemeye göre tek değişken farkı (Türkçe cümle).
  static String? singleVariableNote(DialIn current, DialIn? previous) {
    if (previous == null) return null;
    if (!_sameBeanMethod(current, previous.beanName, previous.method)) {
      return null;
    }

    final changed = <String>[];
    if (current.grindSetting != previous.grindSetting) {
      changed.add('öğütü');
    }
    if (current.doseGrams != previous.doseGrams) changed.add('doz');
    if (current.yieldGrams != previous.yieldGrams) changed.add('verim');
    if (current.brewSeconds != previous.brewSeconds) changed.add('süre');
    if (current.waterTempC != previous.waterTempC) changed.add('sıcaklık');
    if (current.grinderName != previous.grinderName) {
      changed.add('öğütücü');
    }

    if (changed.isEmpty) {
      return 'Önceki denemeyle aynı parametreler — skor farkı tat/tekniğe bağlı olabilir.';
    }
    if (changed.length == 1) {
      return 'Önceki denemeye göre sadece ${changed.first} değişti — iyi tek değişken denemesi.';
    }
    return 'Önceki denemeye göre birden fazla şey değişti (${changed.join(', ')}).';
  }

  static List<String> recentDistinct(
    List<DialIn> all,
    String Function(DialIn) pick, {
    int limit = 8,
  }) {
    final seen = <String>{};
    final out = <String>[];
    for (final item in all) {
      final v = pick(item).trim();
      if (v.isEmpty) continue;
      final key = v.toLowerCase();
      if (seen.contains(key)) continue;
      seen.add(key);
      out.add(v);
      if (out.length >= limit) break;
    }
    return out;
  }

  static List<String> recentBeanNames(List<DialIn> all, {int limit = 8}) =>
      recentDistinct(all, (e) => e.beanName, limit: limit);

  static List<String> recentRoasters(List<DialIn> all, {int limit = 8}) =>
      recentDistinct(all, (e) => e.roaster, limit: limit);

  static List<String> recentGrinders(List<DialIn> all, {int limit = 8}) =>
      recentDistinct(all, (e) => e.grinderName, limit: limit);

  /// Öğütücü adı → son öğütüm ayarı.
  static String? lastGrindForGrinder(List<DialIn> all, String grinderName) {
    final key = grinderName.trim().toLowerCase();
    if (key.isEmpty) return null;
    for (final item in all) {
      if (item.grinderName.trim().toLowerCase() == key &&
          item.grindSetting.trim().isNotEmpty) {
        return item.grindSetting;
      }
    }
    return null;
  }

  /// Skor ≥ 9 veya favori — “efsane” geri dönüş listesi.
  static List<DialIn> legendaryShots(List<DialIn> all, {int limit = 5}) {
    final list = all.where((e) => e.isFavorite || e.score >= 9).toList()
      ..sort((a, b) {
        final byScore = b.score.compareTo(a.score);
        if (byScore != 0) return byScore;
        return b.createdAt.compareTo(a.createdAt);
      });
    if (list.length <= limit) return list;
    return list.sublist(0, limit);
  }
}
