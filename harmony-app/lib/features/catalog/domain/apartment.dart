import '../../../core/i18n/i18n.dart';

/// Types de biens proposés à la location. `code` : valeur échangée avec l'API.
enum ApartmentType {
  studio('Studio', 'studio'),
  twoRooms('2 pièces', 'two_rooms'),
  threeRooms('3 pièces', 'three_rooms'),
  fourRooms('4 pièces', 'four_rooms'),
  duplex('Duplex', 'duplex'),
  villa('Villa', 'villa');

  const ApartmentType(this._label, this.code);
  final String _label;
  String get label => t(_label);
  final String code;

  static ApartmentType fromCode(String code) => values.firstWhere((t) => t.code == code, orElse: () => twoRooms);
}

/// Équipements, avec un libellé prêt pour l'i18n.
enum Amenity {
  wifi('Wi-Fi', 'wifi'),
  airConditioning('Climatisation', 'air_conditioning'),
  parking('Parking', 'parking'),
  hotWater('Eau chaude', 'hot_water'),
  generator('Groupe électrogène', 'generator'),
  pool('Piscine', 'pool'),
  kitchen('Cuisine équipée', 'kitchen'),
  tv('Télévision', 'tv'),
  security('Gardiennage 24 h/24', 'security'),
  washer('Lave-linge', 'washer');

  const Amenity(this._label, this.code);
  final String _label;
  String get label => t(_label);
  final String code;

  static Amenity? fromCode(String code) {
    for (final a in values) {
      if (a.code == code) return a;
    }
    return null;
  }
}

enum ApartmentStatus {
  available('Disponible', 'available'),
  occupied('Réservé', 'occupied'),
  maintenance('En maintenance', 'maintenance');

  const ApartmentStatus(this._label, this.code);
  final String _label;
  String get label => t(_label);
  final String code;

  static ApartmentStatus fromCode(String code) => values.firstWhere((s) => s.code == code, orElse: () => available);
}

/// Séjours courts proposés en option par le propriétaire (prix FCFA).
class ShortStayOffer {
  const ShortStayOffer({this.threeHours, this.day});

  final int? threeHours;
  final int? day;
}

/// Appartement du parc géré par la conciergerie.
/// À migrer vers Freezed + json_serializable quand l'API catalogue sera branchée.
class Apartment {
  const Apartment({
    required this.id,
    required this.title,
    required this.description,
    required this.type,
    required this.zoneId,
    required this.bedrooms,
    required this.bathrooms,
    required this.capacity,
    required this.surfaceM2,
    required this.amenities,
    required this.pricePerNight,
    required this.deposit,
    required this.photos,
    required this.status,
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.rules,
    required this.rating,
    required this.reviewCount,
    required this.listedAt,
    this.featured = false,
    this.shortStays,
  });

  final String id;
  final String title;
  final String description;
  final ApartmentType type;
  final String zoneId;
  final int bedrooms;
  final int bathrooms;
  final int capacity;
  final int surfaceM2;
  final Set<Amenity> amenities;

  /// Prix par nuit en FCFA (entier).
  final int pricePerNight;

  /// Caution en FCFA (entier), restituée après l'état des lieux.
  final int deposit;
  final List<String> photos;
  final ApartmentStatus status;
  final double latitude;
  final double longitude;
  final String address;
  final List<String> rules;
  final double rating;
  final int reviewCount;

  /// Date de mise en ligne (UTC), pour la section « Nouveautés ».
  final DateTime listedAt;
  final bool featured;
  final ShortStayOffer? shortStays;

  String get cover => photos.first;
  bool get isBookable => status == ApartmentStatus.available;
  String get heroTag => 'apartment-$id';
}
