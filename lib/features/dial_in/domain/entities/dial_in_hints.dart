import 'brew_method.dart';

/// Yöntem bazlı başlangıç değerleri (şablon; bulut tarif değil).
class MethodDefaults {
  const MethodDefaults({
    required this.doseGrams,
    required this.yieldGrams,
    required this.brewSeconds,
    required this.waterTempC,
  });

  final double doseGrams;
  final double yieldGrams;
  final int brewSeconds;
  final double waterTempC;
}

/// Hedef oran bandı (statik, offline).
class RatioBand {
  const RatioBand({required this.min, required this.max});

  final double min;
  final double max;

  String get label =>
      '1:${min.toStringAsFixed(1)}–1:${max.toStringAsFixed(1)}';

  bool contains(double ratio) => ratio >= min && ratio <= max;
}

/// Kural tabanlı dial-in ipuçları — crew/AI yok.
class DialInHints {
  DialInHints._();

  static MethodDefaults defaultsFor(BrewMethod method) => switch (method) {
        BrewMethod.espresso => const MethodDefaults(
            doseGrams: 18,
            yieldGrams: 36,
            brewSeconds: 30,
            waterTempC: 93,
          ),
        BrewMethod.v60 ||
        BrewMethod.kalita ||
        BrewMethod.origami =>
          const MethodDefaults(
            doseGrams: 15,
            yieldGrams: 250,
            brewSeconds: 180,
            waterTempC: 94,
          ),
        BrewMethod.aeropress => const MethodDefaults(
            doseGrams: 15,
            yieldGrams: 220,
            brewSeconds: 90,
            waterTempC: 88,
          ),
        BrewMethod.frenchPress => const MethodDefaults(
            doseGrams: 18,
            yieldGrams: 300,
            brewSeconds: 240,
            waterTempC: 94,
          ),
        BrewMethod.moka => const MethodDefaults(
            doseGrams: 16,
            yieldGrams: 60,
            brewSeconds: 90,
            waterTempC: 96,
          ),
        BrewMethod.other => const MethodDefaults(
            doseGrams: 18,
            yieldGrams: 36,
            brewSeconds: 30,
            waterTempC: 93,
          ),
      };

  static RatioBand? ratioBandFor(BrewMethod method) => switch (method) {
        BrewMethod.espresso => const RatioBand(min: 1.8, max: 2.5),
        BrewMethod.v60 ||
        BrewMethod.kalita ||
        BrewMethod.origami =>
          const RatioBand(min: 14.0, max: 17.0),
        BrewMethod.aeropress => const RatioBand(min: 12.0, max: 16.0),
        BrewMethod.frenchPress => const RatioBand(min: 14.0, max: 17.0),
        BrewMethod.moka => const RatioBand(min: 3.0, max: 5.0),
        BrewMethod.other => null,
      };

  /// Oran bandı dışıysa kısa uyarı; içindeyse hedef bandı metni.
  static String? ratioHint(BrewMethod method, double ratio) {
    final band = ratioBandFor(method);
    if (band == null || ratio <= 0) return null;
    if (band.contains(ratio)) {
      return 'Hedef bandı ${band.label}';
    }
    return 'Oran hedef bandın dışında (${band.label})';
  }

  /// Tat etiketinden tek değişken önerisi (öncelik sırası sabit).
  static String? tasteTip(List<TasteTag> tags) {
    if (tags.isEmpty) return null;
    const order = [
      TasteTag.sour,
      TasteTag.bitter,
      TasteTag.astringent,
      TasteTag.thin,
      TasteTag.heavy,
      TasteTag.salty,
      TasteTag.muted,
      TasteTag.sweet,
      TasteTag.balanced,
    ];
    for (final tag in order) {
      if (!tags.contains(tag)) continue;
      final tip = switch (tag) {
        TasteTag.sour =>
          'Sonraki denemede tek değişken: öğütüyü biraz ince veya suyu +1–2 °C.',
        TasteTag.bitter =>
          'Sonraki denemede tek değişken: öğütüyü biraz kaba veya suyu −1–2 °C.',
        TasteTag.astringent =>
          'Sonraki denemede tek değişken: öğütüyü kaba veya demlemeyi kısalt.',
        TasteTag.thin =>
          'Sonraki denemede tek değişken: dozu artır veya verimi düşür (daha sıkı oran).',
        TasteTag.heavy =>
          'Sonraki denemede tek değişken: verimi artır veya dozu azalt (daha açık oran).',
        TasteTag.salty =>
          'Sonraki denemede tek değişken: suyu biraz soğut veya demlemeyi kısalt.',
        TasteTag.muted =>
          'Sonraki denemede tek değişken: suyu +1–2 °C veya öğütüyü ince.',
        TasteTag.sweet =>
          'Tatlılık güzel — bir sonraki shot’ta tek bir şeyi değiştir.',
        TasteTag.balanced =>
          'Dengeli — kilitlemek için favoriye al, sonra tek değişken dene.',
      };
      return tip;
    }
    return null;
  }

  /// Kavurma tarihinden taze penceresi (gün sayısı).
  static String? freshnessHint(DateTime? roastDate, {DateTime? now}) {
    if (roastDate == null) return null;
    final today = now ?? DateTime.now();
    final roastDay = DateTime(roastDate.year, roastDate.month, roastDate.day);
    final todayDay = DateTime(today.year, today.month, today.day);
    final days = todayDay.difference(roastDay).inDays;
    if (days < 0) return 'Kavurma tarihi gelecekte görünüyor.';
    if (days <= 3) return 'Çok taze ($days gün) — gazı yüksek olabilir.';
    if (days <= 21) return 'Taze penceresinde ($days gün).';
    if (days <= 45) return 'Olgunlaşmış ($days gün) — hâlâ demlenebilir.';
    return 'Eski kavrum ($days gün) — aroma solmuş olabilir.';
  }
}
