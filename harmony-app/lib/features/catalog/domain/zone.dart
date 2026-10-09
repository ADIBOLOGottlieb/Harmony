/// Quartier ou ville où se trouvent des biens.
class Zone {
  const Zone({
    required this.id,
    required this.name,
    required this.city,
    required this.country,
    required this.cover,
  });

  final String id;
  final String name;
  final String city;
  final String country;

  /// Chemin de l'image de couverture.
  final String cover;
}
