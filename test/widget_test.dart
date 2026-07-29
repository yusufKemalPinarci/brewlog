import 'package:flutter_test/flutter_test.dart';

import 'package:brewcrew/features/dial_in/data/repositories/local_dial_in_repository.dart';
import 'package:brewcrew/features/dial_in/domain/entities/brew_method.dart';
import 'package:brewcrew/features/dial_in/domain/entities/dial_in.dart';
import 'package:brewcrew/features/dial_in/presentation/bloc/dial_in_cubit.dart';
import 'package:brewcrew/main.dart';

class _MemoryRepo implements DialInRepository {
  final items = <DialIn>[];

  @override
  Future<void> delete(String id) async => items.removeWhere((e) => e.id == id);

  @override
  Future<List<DialIn>> getAll() async => List.of(items);

  @override
  Future<void> upsert(DialIn dialIn) async {
    items.removeWhere((e) => e.id == dialIn.id);
    items.add(dialIn);
  }
}

void main() {
  testWidgets('BrewLog ana marka görünür', (tester) async {
    await tester.pumpWidget(BrewLogApp(repository: _MemoryRepo()));
    await tester.pumpAndSettle();
    expect(find.text('BrewLog'), findsOneWidget);
    expect(find.text('Yeni deneme'), findsOneWidget);
    expect(find.text('İlk denemeyi başlat'), findsOneWidget);
    expect(find.textContaining('Crew'), findsNothing);
  });

  test('DialInCubit filtre ve favori', () async {
    final repo = _MemoryRepo();
    final cubit = DialInCubit(repo);
    await cubit.save(
      DialIn(
        id: '1',
        createdAt: DateTime(2026, 7, 24),
        beanName: 'Yirgacheffe',
        roaster: 'Demo',
        method: BrewMethod.espresso,
        grindSetting: '12',
        doseGrams: 18,
        yieldGrams: 36,
        brewSeconds: 30,
        waterTempC: 93,
        score: 8,
        isFavorite: true,
      ),
    );
    await cubit.save(
      DialIn(
        id: '2',
        createdAt: DateTime(2026, 7, 23),
        beanName: 'Gesha',
        roaster: 'Demo',
        method: BrewMethod.v60,
        grindSetting: '20',
        doseGrams: 15,
        yieldGrams: 250,
        brewSeconds: 180,
        waterTempC: 94,
        score: 9,
      ),
    );

    cubit.setFavoritesOnly(true);
    expect(cubit.state.visible.length, 1);
    expect(cubit.state.visible.first.beanName, 'Yirgacheffe');
    expect(cubit.state.loading, isFalse);

    cubit.setFavoritesOnly(false);
    cubit.setMethodFilter(BrewMethod.v60);
    expect(cubit.state.visible.length, 1);
    expect(cubit.state.bestShot?.score, 9);

    cubit.clearFilters();
    expect(cubit.state.hasActiveFilters, isFalse);
    expect(cubit.state.visible.length, 2);

    await cubit.close();
  });

  test('asNewAttempt favoriyi kapatır ve id değiştirir', () {
    final original = DialIn(
      id: 'old',
      createdAt: DateTime(2026, 1, 1),
      beanName: 'Test',
      roaster: 'R',
      method: BrewMethod.espresso,
      grindSetting: '10',
      doseGrams: 18,
      yieldGrams: 36,
      brewSeconds: 28,
      waterTempC: 93,
      score: 9,
      isFavorite: true,
    );
    final next = original.asNewAttempt(newId: 'new');
    expect(next.id, 'new');
    expect(next.isFavorite, isFalse);
    expect(next.beanName, 'Test');
    expect(next.score, 9);
  });
}
