import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/catalog_repository.dart';
import '../domain/apartment.dart';

/// Critères saisis dans le bandeau de recherche et l'écran Explorer.
@immutable
class SearchCriteria {
  const SearchCriteria({this.zoneId, this.dates, this.guests = 1, this.type});

  final String? zoneId;
  final DateTimeRange? dates;
  final int guests;
  final ApartmentType? type;

  bool get isEmpty => zoneId == null && dates == null && guests <= 1 && type == null;
}

final searchCriteriaProvider = NotifierProvider<SearchCriteriaController, SearchCriteria>(SearchCriteriaController.new);

class SearchCriteriaController extends Notifier<SearchCriteria> {
  @override
  SearchCriteria build() => const SearchCriteria();

  void setZone(String? zoneId) => state = SearchCriteria(zoneId: zoneId, dates: state.dates, guests: state.guests, type: state.type);

  void setDates(DateTimeRange? dates) => state = SearchCriteria(zoneId: state.zoneId, dates: dates, guests: state.guests, type: state.type);

  void setGuests(int guests) =>
      state = SearchCriteria(zoneId: state.zoneId, dates: state.dates, guests: guests.clamp(1, 16), type: state.type);

  void setType(ApartmentType? type) => state = SearchCriteria(zoneId: state.zoneId, dates: state.dates, guests: state.guests, type: type);

  void reset() => state = const SearchCriteria();
}

/// Résultats filtrés. Les biens disponibles passent en premier.
/// La disponibilité réelle sur les dates sera vérifiée par l'API (étape calendrier).
final searchResultsProvider = Provider<List<Apartment>>((ref) {
  final c = ref.watch(searchCriteriaProvider);
  final results = ref.watch(apartmentsProvider).where((a) {
    if (c.zoneId != null && a.zoneId != c.zoneId) return false;
    if (a.capacity < c.guests) return false;
    if (c.type != null && a.type != c.type) return false;
    return true;
  }).toList()
    ..sort((a, b) => (b.isBookable ? 1 : 0).compareTo(a.isBookable ? 1 : 0));
  return results;
});
