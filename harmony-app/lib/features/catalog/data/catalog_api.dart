import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../domain/apartment.dart';
import '../domain/zone.dart';

typedef Json = Map<String, dynamic>;

/// Accès au catalogue de l'API (`/zones`, `/apartments`).
class CatalogApi {
  CatalogApi(this._dio);

  final Dio _dio;

  /// Réponses brutes, mises en cache telles quelles pour le mode hors-ligne.
  Future<({List<Json> zones, List<Json> apartments})> fetchRaw() async {
    final zones = await _dio.get<Json>('/zones');
    final apartments = await _dio.get<Json>('/apartments');
    return (
      zones: List<Json>.from(zones.data!['data'] as List),
      apartments: List<Json>.from(apartments.data!['data'] as List),
    );
  }
}

final catalogApiProvider = Provider<CatalogApi>((ref) => CatalogApi(ref.watch(apiClientProvider)));

/// Photo : chemin « demo/… » embarqué dans l'app, sinon fichier public de l'API.
String photoSource(String? path) {
  if (path == null || path.isEmpty) return '';
  if (path.startsWith('demo/')) return 'assets/images/$path';
  if (path.startsWith('http')) return path;
  return '${AppConfig.storageBaseUrl}/$path';
}

Zone zoneFromJson(Json j) => Zone(
      id: j['slug'] as String,
      name: j['name'] as String,
      city: j['city'] as String,
      country: j['country'] as String,
      cover: photoSource(j['cover'] as String?),
    );

Apartment apartmentFromJson(Json j) {
  final location = j['location'] as Json;
  final shortStays = j['short_stays'] as Json?;
  return Apartment(
    id: j['slug'] as String,
    title: j['title'] as String,
    description: j['description'] as String,
    type: ApartmentType.fromCode(j['type'] as String),
    zoneId: (j['zone'] as Json)['slug'] as String,
    bedrooms: j['bedrooms'] as int,
    bathrooms: j['bathrooms'] as int,
    capacity: j['capacity'] as int,
    surfaceM2: j['surface_m2'] as int,
    amenities: (j['amenities'] as List)
        .map((a) => Amenity.fromCode((a as Json)['code'] as String))
        .whereType<Amenity>()
        .toSet(),
    pricePerNight: j['price_per_night'] as int,
    deposit: j['deposit'] as int,
    photos: (j['photos'] as List? ?? const [])
        .map((p) => photoSource((p as Json)['path'] as String?))
        .where((p) => p.isNotEmpty)
        .toList(),
    status: ApartmentStatus.fromCode(j['status'] as String),
    latitude: (location['latitude'] as num).toDouble(),
    longitude: (location['longitude'] as num).toDouble(),
    address: location['area'] as String,
    rules: List<String>.from(j['rules'] as List? ?? const []),
    rating: (j['rating'] as num).toDouble(),
    reviewCount: j['review_count'] as int,
    listedAt: DateTime.parse(j['listed_at'] as String),
    featured: j['featured'] as bool? ?? false,
    shortStays: shortStays == null
        ? null
        : ShortStayOffer(threeHours: shortStays['three_hours'] as int?, day: shortStays['day'] as int?),
  );
}
