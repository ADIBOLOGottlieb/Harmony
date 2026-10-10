import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/catalog_repository.dart';
import '../domain/apartment.dart';

/// Bornes du filtre de budget (prix par nuit, FCFA).
const budgetFloor = 0;
const budgetCeiling = 200000;

/// Critères saisis dans le bandeau de recherche et l'écran Explorer.
@immutable
class SearchCriteria {
  const SearchCriteria({
    this.zoneId,
    this.dates,
    this.guests = 1,
    this.type,
    this.minPrice,
    this.maxPrice,
    this.amenities = const {},
  });

  final String? zoneId;
  final DateTimeRange? dates;
  final int guests;
  final ApartmentType? type;
  final int? minPrice;
  final int? maxPrice;
  final Set<Amenity> amenities;

  bool get isEmpty => zoneId == null && dates == null && guests <= 1 && type == null && advancedCount == 0;

  /// Nombre de filtres de la feuille « Filtres » (budget, équipements).
  int get advancedCount => (minPrice != null || maxPrice != null ? 1 : 0) + amenities.length;

  SearchCriteria copyWith({
    Object? zoneId = _keep,
    Object? dates = _keep,
    int? guests,
    Object? type = _keep,
    Object? minPrice = _keep,
    Object? maxPrice = _keep,
    Set<Amenity>? amenities,
  }) {
    return SearchCriteria(
      zoneId: identical(zoneId, _keep) ? this.zoneId : zoneId as String?,
      dates: identical(dates, _keep) ? this.dates : dates as DateTimeRange?,
      guests: guests ?? this.guests,
      type: identical(type, _keep) ? this.type : type as ApartmentType?,
      minPrice: identical(minPrice, _keep) ? this.minPrice : minPrice as int?,
      maxPrice: identical(maxPrice, _keep) ? this.maxPrice : maxPrice as int?,
      amenities: amenities ?? this.amenities,
    );
  }
}

const _keep = Object();

final searchCriteriaProvider = NotifierProvider<SearchCriteriaController, SearchCriteria>(SearchCriteriaController.new);

class SearchCriteriaController extends Notifier<SearchCriteria> {
  @override
  SearchCriteria build() => const SearchCriteria();

  void setZone(String? zoneId) => state = state.copyWith(zoneId: zoneId);

  void setDates(DateTimeRange? dates) => state = state.copyWith(dates: dates);

  void setGuests(int guests) => state = state.copyWith(guests: guests.clamp(1, 16));

  void setType(ApartmentType? type) => state = state.copyWith(type: type);

  void setAdvanced({int? minPrice, int? maxPrice, required Set<Amenity> amenities}) => state = state.copyWith(
        minPrice: minPrice == null || minPrice <= budgetFloor ? null : minPrice,
        maxPrice: maxPrice == null || maxPrice >= budgetCeiling ? null : maxPrice,
        amenities: amenities,
      );

  void reset() => state = const SearchCriteria();
}

/// Applique les critères à une liste de biens (biens disponibles en premier).
/// La disponibilité réelle sur les dates est vérifiée par l'API au moment de réserver.
List<Apartment> applyCriteria(List<Apartment> apartments, SearchCriteria c) {
  return apartments.where((a) {
    if (c.zoneId != null && a.zoneId != c.zoneId) return false;
    if (a.capacity < c.guests) return false;
    if (c.type != null && a.type != c.type) return false;
    if (c.minPrice != null && a.pricePerNight < c.minPrice!) return false;
    if (c.maxPrice != null && a.pricePerNight > c.maxPrice!) return false;
    if (!a.amenities.containsAll(c.amenities)) return false;
    return true;
  }).toList()
    ..sort((a, b) => (b.isBookable ? 1 : 0).compareTo(a.isBookable ? 1 : 0));
}

final searchResultsProvider = Provider<List<Apartment>>(
  (ref) => applyCriteria(ref.watch(apartmentsProvider), ref.watch(searchCriteriaProvider)),
);
