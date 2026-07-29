import 'package:brewcrew/features/dial_in/domain/entities/brew_method.dart';
import 'package:brewcrew/features/dial_in/domain/entities/dial_in.dart';
import 'package:brewcrew/features/dial_in/domain/entities/dial_in_hints.dart';
import 'package:brewcrew/features/dial_in/domain/entities/dial_in_insights.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DialInHints', () {
    test('espresso ratio band', () {
      expect(DialInHints.ratioHint(BrewMethod.espresso, 2.0), contains('Hedef'));
      expect(
        DialInHints.ratioHint(BrewMethod.espresso, 4.0),
        contains('dışında'),
      );
    });

    test('v60 defaults', () {
      final d = DialInHints.defaultsFor(BrewMethod.v60);
      expect(d.doseGrams, 15);
      expect(d.yieldGrams, 250);
    });

    test('taste tip prioritizes sour', () {
      final tip = DialInHints.tasteTip([TasteTag.balanced, TasteTag.sour]);
      expect(tip, contains('ince'));
    });

    test('freshness window', () {
      final roast = DateTime(2026, 7, 20);
      final now = DateTime(2026, 7, 29);
      expect(
        DialInHints.freshnessHint(roast, now: now),
        contains('Taze'),
      );
    });
  });

  group('DialInInsights', () {
    final samples = [
      DialIn(
        id: '1',
        createdAt: DateTime(2026, 7, 1),
        beanName: 'Ethiopia',
        roaster: 'Local',
        method: BrewMethod.espresso,
        grindSetting: '14',
        doseGrams: 18,
        yieldGrams: 36,
        brewSeconds: 30,
        waterTempC: 93,
        score: 8,
      ),
      DialIn(
        id: '2',
        createdAt: DateTime(2026, 7, 2),
        beanName: 'Ethiopia',
        roaster: 'Local',
        method: BrewMethod.espresso,
        grindSetting: '13',
        doseGrams: 18,
        yieldGrams: 36,
        brewSeconds: 28,
        waterTempC: 93,
        score: 9,
        isFavorite: true,
      ),
      DialIn(
        id: '3',
        createdAt: DateTime(2026, 7, 3),
        beanName: 'Brazil',
        roaster: 'Other',
        method: BrewMethod.v60,
        grindSetting: '20',
        doseGrams: 15,
        yieldGrams: 250,
        brewSeconds: 180,
        waterTempC: 94,
        score: 7,
      ),
    ];

    test('best for bean method', () {
      final best = DialInInsights.bestForBeanMethod(
        samples,
        beanName: 'Ethiopia',
        method: BrewMethod.espresso,
      );
      expect(best?.id, '2');
    });

    test('single variable note', () {
      final note = DialInInsights.singleVariableNote(samples[1], samples[0]);
      expect(note, contains('öğütü'));
    });

    test('recent beans and legendary', () {
      expect(DialInInsights.recentBeanNames(samples), ['Ethiopia', 'Brazil']);
      expect(DialInInsights.legendaryShots(samples).first.id, '2');
    });
  });

  group('DialIn json', () {
    test('round trip with new fields', () {
      final original = DialIn(
        id: 'x',
        createdAt: DateTime.parse('2026-07-29T10:00:00.000'),
        beanName: 'Kenya',
        roaster: 'Roast Co',
        method: BrewMethod.v60,
        grindSetting: '18',
        doseGrams: 15,
        yieldGrams: 250,
        brewSeconds: 200,
        waterTempC: 94,
        score: 8,
        roastDate: DateTime(2026, 7, 10),
        pourNotes: '40 bloom',
        waterNote: 'yumuşak',
      );
      final restored = DialIn.fromJson(original.toJson());
      expect(restored, original);
    });
  });
}
