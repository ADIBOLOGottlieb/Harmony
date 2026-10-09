/// Types de biens proposés à la location.
enum ApartmentType {
  studio('Studio'),
  twoRooms('2 pièces'),
  threeRooms('3 pièces'),
  fourRooms('4 pièces'),
  duplex('Duplex'),
  villa('Villa');

  const ApartmentType(this.label);
  final String label;
}

/// Équipements, avec un libellé prêt pour l'i18n.
enum Amenity {
  wifi('Wi-Fi'),
  airConditioning('Climatisation'),
  parking('Parking'),
  hotWater('Eau chaude'),
  generator('Groupe électrogène'),
  pool('Piscine'),
  kitchen('Cuisine équipée'),
  tv('Télévision'),
  security('Gardiennage 24 h/24'),
  washer('Lave-linge');

  const Amenity(this.label);
  final String label;
}

enum ApartmentStatus {
  available('Disponible'),
  occupied('Réservé'),
  maintenance('En maintenance');

  const ApartmentStatus(this.label);
  final String label;
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
