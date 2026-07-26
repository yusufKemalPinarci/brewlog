import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/repositories/local_dial_in_repository.dart';
import '../../domain/entities/brew_method.dart';
import '../../domain/entities/dial_in.dart';

enum DialInSort { newest, score, bean }

class DialInState extends Equatable {
  const DialInState({
    this.items = const [],
    this.loading = true,
    this.error,
    this.methodFilter,
    this.favoritesOnly = false,
    this.sort = DialInSort.newest,
    this.query = '',
  });

  final List<DialIn> items;
  final bool loading;
  final String? error;
  final BrewMethod? methodFilter;
  final bool favoritesOnly;
  final DialInSort sort;
  final String query;

  List<DialIn> get visible {
    var list = List<DialIn>.from(items);
    if (methodFilter != null) {
      list = list.where((e) => e.method == methodFilter).toList();
    }
    if (favoritesOnly) {
      list = list.where((e) => e.isFavorite).toList();
    }
    final q = query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list
          .where(
            (e) =>
                e.beanName.toLowerCase().contains(q) ||
                e.roaster.toLowerCase().contains(q) ||
                e.grinderName.toLowerCase().contains(q),
          )
          .toList();
    }
    switch (sort) {
      case DialInSort.newest:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case DialInSort.score:
        list.sort((a, b) => b.score.compareTo(a.score));
      case DialInSort.bean:
        list.sort((a, b) => a.beanName.compareTo(b.beanName));
    }
    return list;
  }

  DialIn? get bestShot {
    if (items.isEmpty) return null;
    final copy = [...items]..sort((a, b) => b.score.compareTo(a.score));
    return copy.first;
  }

  DialInState copyWith({
    List<DialIn>? items,
    bool? loading,
    String? error,
    BrewMethod? methodFilter,
    bool clearMethodFilter = false,
    bool? favoritesOnly,
    DialInSort? sort,
    String? query,
  }) {
    return DialInState(
      items: items ?? this.items,
      loading: loading ?? this.loading,
      error: error,
      methodFilter:
          clearMethodFilter ? null : (methodFilter ?? this.methodFilter),
      favoritesOnly: favoritesOnly ?? this.favoritesOnly,
      sort: sort ?? this.sort,
      query: query ?? this.query,
    );
  }

  @override
  List<Object?> get props =>
      [items, loading, error, methodFilter, favoritesOnly, sort, query];
}

class DialInCubit extends Cubit<DialInState> {
  DialInCubit(this._repository) : super(const DialInState());

  final DialInRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(loading: true, error: null));
    try {
      final items = await _repository.getAll();
      emit(state.copyWith(items: items, loading: false));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> save(DialIn dialIn) async {
    await _repository.upsert(dialIn);
    await load();
  }

  Future<void> remove(String id) async {
    await _repository.delete(id);
    await load();
  }

  Future<void> toggleFavorite(DialIn dialIn) async {
    await _repository.upsert(dialIn.copyWith(isFavorite: !dialIn.isFavorite));
    await load();
  }

  void setMethodFilter(BrewMethod? method) {
    if (method == null || state.methodFilter == method) {
      emit(state.copyWith(clearMethodFilter: true));
    } else {
      emit(state.copyWith(methodFilter: method));
    }
  }

  void setFavoritesOnly(bool value) {
    emit(state.copyWith(favoritesOnly: value));
  }

  void setSort(DialInSort sort) {
    emit(state.copyWith(sort: sort));
  }

  void setQuery(String query) {
    emit(state.copyWith(query: query));
  }
}
