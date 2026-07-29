import 'package:equatable/equatable.dart';

import 'brew_method.dart';

class DialIn extends Equatable {
  const DialIn({
    required this.id,
    required this.createdAt,
    required this.beanName,
    required this.roaster,
    required this.method,
    required this.grindSetting,
    required this.doseGrams,
    required this.yieldGrams,
    required this.brewSeconds,
    required this.waterTempC,
    required this.score,
    this.notes = '',
    this.tasteTags = const [],
    this.grinderName = '',
    this.isFavorite = false,
  });

  final String id;
  final DateTime createdAt;
  final String beanName;
  final String roaster;
  final BrewMethod method;
  final String grindSetting;
  final double doseGrams;
  final double yieldGrams;
  final int brewSeconds;
  final double waterTempC;
  final int score;
  final String notes;
  final List<TasteTag> tasteTags;
  final String grinderName;
  final bool isFavorite;

  double get ratio => doseGrams <= 0 ? 0 : yieldGrams / doseGrams;

  String get formattedRatio => '1:${ratio.toStringAsFixed(1)}';

  static int clampScore(int score) => score.clamp(1, 10);

  /// Aynı tarif parametreleriyle yeni deneme (favori kapalı, yeni id/tarih).
  DialIn asNewAttempt({required String newId, DateTime? at}) {
    return copyWith(
      id: newId,
      createdAt: at ?? DateTime.now(),
      isFavorite: false,
    );
  }

  DialIn copyWith({
    String? id,
    DateTime? createdAt,
    String? beanName,
    String? roaster,
    BrewMethod? method,
    String? grindSetting,
    double? doseGrams,
    double? yieldGrams,
    int? brewSeconds,
    double? waterTempC,
    int? score,
    String? notes,
    List<TasteTag>? tasteTags,
    String? grinderName,
    bool? isFavorite,
  }) {
    return DialIn(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      beanName: beanName ?? this.beanName,
      roaster: roaster ?? this.roaster,
      method: method ?? this.method,
      grindSetting: grindSetting ?? this.grindSetting,
      doseGrams: doseGrams ?? this.doseGrams,
      yieldGrams: yieldGrams ?? this.yieldGrams,
      brewSeconds: brewSeconds ?? this.brewSeconds,
      waterTempC: waterTempC ?? this.waterTempC,
      score: score ?? this.score,
      notes: notes ?? this.notes,
      tasteTags: tasteTags ?? this.tasteTags,
      grinderName: grinderName ?? this.grinderName,
      isFavorite: isFavorite ?? this.isFavorite,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'createdAt': createdAt.toIso8601String(),
        'beanName': beanName,
        'roaster': roaster,
        'method': method.name,
        'grindSetting': grindSetting,
        'doseGrams': doseGrams,
        'yieldGrams': yieldGrams,
        'brewSeconds': brewSeconds,
        'waterTempC': waterTempC,
        'score': score,
        'notes': notes,
        'tasteTags': tasteTags.map((e) => e.name).toList(),
        'grinderName': grinderName,
        'isFavorite': isFavorite,
      };

  factory DialIn.fromJson(Map<String, dynamic> json) {
    return DialIn(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      beanName: json['beanName'] as String,
      roaster: json['roaster'] as String? ?? '',
      method: BrewMethod.values.firstWhere(
        (m) => m.name == json['method'],
        orElse: () => BrewMethod.other,
      ),
      grindSetting: json['grindSetting'] as String? ?? '',
      doseGrams: (json['doseGrams'] as num?)?.toDouble() ?? 0,
      yieldGrams: (json['yieldGrams'] as num?)?.toDouble() ?? 0,
      brewSeconds: (json['brewSeconds'] as num?)?.toInt() ?? 0,
      waterTempC: (json['waterTempC'] as num?)?.toDouble() ?? 0,
      score: clampScore((json['score'] as num?)?.toInt() ?? 5),
      notes: json['notes'] as String? ?? '',
      tasteTags: (json['tasteTags'] as List<dynamic>? ?? [])
          .map(
            (e) => TasteTag.values.firstWhere(
              (t) => t.name == e,
              orElse: () => TasteTag.balanced,
            ),
          )
          .toList(),
      grinderName: json['grinderName'] as String? ?? '',
      isFavorite: json['isFavorite'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        id,
        createdAt,
        beanName,
        roaster,
        method,
        grindSetting,
        doseGrams,
        yieldGrams,
        brewSeconds,
        waterTempC,
        score,
        notes,
        tasteTags,
        grinderName,
        isFavorite,
      ];
}
