/// Durées de séjour proposées. Chaque créneau porte un nom de « séance »
/// qui donne le ton cinéma sans jamais être explicite.
enum StayType {
  threeHours(label: '3 heures', screening: 'Court-métrage'),
  night(label: 'Nuitée', screening: 'Séance de minuit'),
  day(label: 'Journée', screening: 'Plein jour'),
  twoDays(label: '2 jours', screening: 'Double programme'),
  threeDays(label: '3 jours', screening: 'Trilogie');

  const StayType({required this.label, required this.screening});

  final String label;
  final String screening;
}

/// Chambre telle qu'affichée au client. Les prix sont en FCFA entiers.
/// À migrer vers Freezed + json_serializable quand l'API sera branchée.
class Room {
  const Room({
    required this.id,
    required this.name,
    required this.category,
    required this.tagline,
    required this.synopsis,
    required this.amenities,
    required this.mood,
    required this.prices,
  });

  final String id;
  final String name;
  final String category;
  final String tagline;
  final String synopsis;
  final List<String> amenities;

  /// Index de palette d'affiche (voir `HPoster.moods`).
  final int mood;
  final Map<StayType, int> prices;

  int priceFor(StayType stay) => prices[stay]!;

  /// Graine stable de l'affiche générée (même rendu à chaque lancement).
  int get posterSeed => id.codeUnits.fold(7, (a, c) => (a * 31 + c) & 0x7fffffff);

  String get heroTag => 'poster-$id';
}
