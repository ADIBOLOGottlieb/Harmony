import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/apartment.dart';
import '../domain/zone.dart';

/// Catalogue de démonstration (Lomé) en attendant `GET /api/v1/zones` et
/// `GET /api/v1/apartments`. Les écrans ne lisent que ces providers : brancher
/// l'API ne changera que ce fichier.
final zonesProvider = Provider<List<Zone>>((ref) => _zones);

final apartmentsProvider = Provider<List<Apartment>>((ref) => _apartments);

final zoneByIdProvider = Provider.family<Zone?, String>((ref, id) {
  for (final z in ref.watch(zonesProvider)) {
    if (z.id == id) return z;
  }
  return null;
});

final apartmentByIdProvider = Provider.family<Apartment?, String>((ref, id) {
  for (final a in ref.watch(apartmentsProvider)) {
    if (a.id == id) return a;
  }
  return null;
});

final featuredApartmentsProvider = Provider<List<Apartment>>(
  (ref) => ref.watch(apartmentsProvider).where((a) => a.featured).toList(),
);

final newestApartmentsProvider = Provider<List<Apartment>>((ref) {
  final list = [...ref.watch(apartmentsProvider)]..sort((a, b) => b.listedAt.compareTo(a.listedAt));
  return list.take(4).toList();
});

final apartmentCountByZoneProvider = Provider<Map<String, int>>((ref) {
  final counts = <String, int>{};
  for (final a in ref.watch(apartmentsProvider)) {
    counts[a.zoneId] = (counts[a.zoneId] ?? 0) + 1;
  }
  return counts;
});

const _photo = 'assets/images/demo';

const _zones = [
  Zone(id: 'kodjoviakope', name: 'Kodjoviakopé', city: 'Lomé', country: 'Togo', cover: '$_photo/p02.webp'),
  Zone(id: 'baguida', name: 'Baguida', city: 'Lomé', country: 'Togo', cover: '$_photo/p01.webp'),
  Zone(id: 'tokoin', name: 'Tokoin', city: 'Lomé', country: 'Togo', cover: '$_photo/p04.webp'),
  Zone(id: 'avedji', name: 'Avédji', city: 'Lomé', country: 'Togo', cover: '$_photo/p07.webp'),
  Zone(id: 'agoe', name: 'Agoè', city: 'Lomé', country: 'Togo', cover: '$_photo/p11.webp'),
];

const _standardRules = [
  'Arrivée à partir de 14 h, départ avant 11 h',
  'Non-fumeur à l’intérieur',
  'Pas de fêtes ni d’événements sans accord',
  'Animaux non admis',
];

final _apartments = <Apartment>[
  Apartment(
    id: 'villa-lagune',
    title: 'Villa Lagune',
    description:
        'Villa contemporaine en bord de mer, entièrement climatisée, avec piscine privée, jardin et terrasse ombragée. '
        'Idéale pour les familles et les séjours d’affaires prolongés, à 20 minutes du centre.',
    type: ApartmentType.villa,
    zoneId: 'baguida',
    bedrooms: 4,
    bathrooms: 3,
    capacity: 8,
    surfaceM2: 280,
    amenities: Amenity.values.toSet(),
    pricePerNight: 150000,
    deposit: 300000,
    photos: ['$_photo/p01.webp', '$_photo/p05.webp', '$_photo/p13.webp', '$_photo/p03.webp'],
    status: ApartmentStatus.available,
    latitude: 6.1630,
    longitude: 1.3220,
    address: 'Route d’Aného, Baguida',
    rules: _standardRules,
    rating: 4.9,
    reviewCount: 38,
    listedAt: DateTime.utc(2026, 8, 12),
    featured: true,
    shortStays: const ShortStayOffer(day: 90000),
  ),
  Apartment(
    id: 'duplex-horizon',
    title: 'Duplex Horizon',
    description:
        'Duplex lumineux avec vue dégagée sur la ville, salon double hauteur et suite parentale. '
        'À deux pas de la plage et des restaurants du centre.',
    type: ApartmentType.duplex,
    zoneId: 'kodjoviakope',
    bedrooms: 3,
    bathrooms: 2,
    capacity: 6,
    surfaceM2: 160,
    amenities: const {
      Amenity.wifi, Amenity.airConditioning, Amenity.parking, Amenity.hotWater, Amenity.generator,
      Amenity.kitchen, Amenity.tv, Amenity.security, Amenity.washer,
    },
    pricePerNight: 95000,
    deposit: 150000,
    photos: ['$_photo/p02.webp', '$_photo/p06.webp', '$_photo/p04.webp', '$_photo/p14.webp'],
    status: ApartmentStatus.available,
    latitude: 6.1255,
    longitude: 1.2050,
    address: 'Boulevard du Mono, Kodjoviakopé',
    rules: _standardRules,
    rating: 4.8,
    reviewCount: 52,
    listedAt: DateTime.utc(2026, 9, 20),
    featured: true,
  ),
  Apartment(
    id: 'les-cocotiers',
    title: 'Appartement Les Cocotiers',
    description:
        'Trois pièces calme et bien agencé, au cœur de Tokoin. Cuisine équipée, groupe électrogène et '
        'connexion fibre pour télétravailler sereinement.',
    type: ApartmentType.threeRooms,
    zoneId: 'tokoin',
    bedrooms: 2,
    bathrooms: 1,
    capacity: 4,
    surfaceM2: 95,
    amenities: const {Amenity.wifi, Amenity.airConditioning, Amenity.hotWater, Amenity.kitchen, Amenity.tv, Amenity.generator},
    pricePerNight: 45000,
    deposit: 60000,
    photos: ['$_photo/p04.webp', '$_photo/p03.webp', '$_photo/p12.webp'],
    status: ApartmentStatus.available,
    latitude: 6.1450,
    longitude: 1.2160,
    address: 'Tokoin Hôpital, Lomé',
    rules: _standardRules,
    rating: 4.7,
    reviewCount: 64,
    listedAt: DateTime.utc(2026, 7, 2),
    shortStays: const ShortStayOffer(threeHours: 15000, day: 30000),
  ),
  Apartment(
    id: 'studio-atlantique',
    title: 'Studio Atlantique',
    description: 'Studio design et fonctionnel, à 5 minutes à pied de la plage. Parfait pour un voyageur ou un couple.',
    type: ApartmentType.studio,
    zoneId: 'kodjoviakope',
    bedrooms: 1,
    bathrooms: 1,
    capacity: 2,
    surfaceM2: 38,
    amenities: const {Amenity.wifi, Amenity.airConditioning, Amenity.hotWater, Amenity.kitchen, Amenity.tv},
    pricePerNight: 25000,
    deposit: 30000,
    photos: ['$_photo/p09.webp', '$_photo/p13.webp'],
    status: ApartmentStatus.available,
    latitude: 6.1240,
    longitude: 1.2090,
    address: 'Rue de la Plage, Kodjoviakopé',
    rules: _standardRules,
    rating: 4.6,
    reviewCount: 21,
    listedAt: DateTime.utc(2026, 10, 2),
    shortStays: const ShortStayOffer(threeHours: 10000, day: 18000),
  ),
  Apartment(
    id: 'jardin-avedji',
    title: 'Deux-pièces Jardin',
    description: 'Rez-de-jardin au calme, baigné de lumière, avec parking privé et lave-linge.',
    type: ApartmentType.twoRooms,
    zoneId: 'avedji',
    bedrooms: 1,
    bathrooms: 1,
    capacity: 3,
    surfaceM2: 60,
    amenities: const {Amenity.wifi, Amenity.airConditioning, Amenity.parking, Amenity.hotWater, Amenity.kitchen, Amenity.washer},
    pricePerNight: 30000,
    deposit: 40000,
    photos: ['$_photo/p07.webp', '$_photo/p12.webp'],
    status: ApartmentStatus.available,
    latitude: 6.1800,
    longitude: 1.1700,
    address: 'Avédji, Lomé',
    rules: _standardRules,
    rating: 4.5,
    reviewCount: 17,
    listedAt: DateTime.utc(2026, 9, 28),
  ),
  Apartment(
    id: 'appartement-indigo',
    title: 'Appartement Indigo',
    description: 'Deux-pièces au caractère affirmé, mur indigo et mobilier contemporain. Rénovation en cours.',
    type: ApartmentType.twoRooms,
    zoneId: 'agoe',
    bedrooms: 1,
    bathrooms: 1,
    capacity: 2,
    surfaceM2: 55,
    amenities: const {Amenity.wifi, Amenity.airConditioning, Amenity.hotWater, Amenity.tv},
    pricePerNight: 28000,
    deposit: 35000,
    photos: ['$_photo/p11.webp', '$_photo/p14.webp'],
    status: ApartmentStatus.maintenance,
    latitude: 6.2100,
    longitude: 1.2000,
    address: 'Agoè Nyivé, Lomé',
    rules: _standardRules,
    rating: 4.4,
    reviewCount: 9,
    listedAt: DateTime.utc(2026, 6, 10),
  ),
  Apartment(
    id: 'residence-lumiere',
    title: 'Résidence Lumière',
    description: 'Grand trois-pièces aux finitions soignées, deux salles d’eau et un séjour ouvert sur balcon.',
    type: ApartmentType.threeRooms,
    zoneId: 'tokoin',
    bedrooms: 2,
    bathrooms: 2,
    capacity: 5,
    surfaceM2: 110,
    amenities: const {
      Amenity.wifi, Amenity.airConditioning, Amenity.parking, Amenity.hotWater, Amenity.generator, Amenity.kitchen, Amenity.tv,
    },
    pricePerNight: 55000,
    deposit: 80000,
    photos: ['$_photo/p08.webp', '$_photo/p10.webp', '$_photo/p13.webp'],
    status: ApartmentStatus.occupied,
    latitude: 6.1480,
    longitude: 1.2210,
    address: 'Tokoin Wuiti, Lomé',
    rules: _standardRules,
    rating: 4.8,
    reviewCount: 40,
    listedAt: DateTime.utc(2026, 5, 15),
    featured: true,
    shortStays: const ShortStayOffer(day: 40000),
  ),
  Apartment(
    id: 'villa-baobab',
    title: 'Villa Baobab',
    description: 'Villa familiale avec grand jardin arboré, gardiennage et groupe électrogène. Calme absolu.',
    type: ApartmentType.villa,
    zoneId: 'agoe',
    bedrooms: 3,
    bathrooms: 3,
    capacity: 6,
    surfaceM2: 200,
    amenities: const {
      Amenity.wifi, Amenity.airConditioning, Amenity.parking, Amenity.hotWater, Amenity.generator,
      Amenity.kitchen, Amenity.tv, Amenity.security, Amenity.washer,
    },
    pricePerNight: 110000,
    deposit: 200000,
    photos: ['$_photo/p03.webp', '$_photo/p05.webp', '$_photo/p12.webp'],
    status: ApartmentStatus.available,
    latitude: 6.2150,
    longitude: 1.1950,
    address: 'Agoè Assiyéyé, Lomé',
    rules: _standardRules,
    rating: 4.7,
    reviewCount: 12,
    listedAt: DateTime.utc(2026, 9, 30),
  ),
];
