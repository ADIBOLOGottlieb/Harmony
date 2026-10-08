import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/room.dart';

/// Catalogue de démonstration (8 chambres, Lomé) en attendant `GET /api/v1/rooms`.
final roomsProvider = Provider<List<Room>>((ref) => _demoRooms);

final roomByIdProvider = Provider.family<Room?, String>((ref, id) {
  for (final room in ref.watch(roomsProvider)) {
    if (room.id == id) return room;
  }
  return null;
});

/// Créneau choisi sur l'affiche : pilote les prix affichés partout.
final selectedStayProvider = NotifierProvider<SelectedStay, StayType>(SelectedStay.new);

class SelectedStay extends Notifier<StayType> {
  @override
  StayType build() => StayType.night;

  void select(StayType stay) => state = stay;
}

Map<StayType, int> _tariff(int threeHours, int night) => {
      StayType.threeHours: threeHours,
      StayType.night: night,
      StayType.day: (night * .8).round() ~/ 500 * 500,
      StayType.twoDays: (night * 1.85).round() ~/ 500 * 500,
      StayType.threeDays: (night * 2.6).round() ~/ 500 * 500,
    };

final _demoRooms = <Room>[
  Room(
    id: 'lagune',
    name: 'Suite Lagune',
    category: 'Suite signature',
    tagline: 'Quand la ville s’éteint, la lagune s’allume.',
    synopsis: 'Une suite aux tons d’eau profonde, baignée d’une lumière tamisée. Baignoire îlot, lit king size et rideaux occultants pour suspendre le temps.',
    amenities: ['Lit king size', 'Baignoire îlot', 'Éclairage d’ambiance', 'Enceinte Bluetooth', 'Climatisation silencieuse'],
    mood: 1,
    prices: _tariff(25000, 55000),
  ),
  Room(
    id: 'velours',
    name: 'Chambre Velours',
    category: 'Chambre deluxe',
    tagline: 'Le rouge du rideau, juste avant le premier rôle.',
    synopsis: 'Velours bordeaux, laiton patiné et lumière dorée : l’intimité d’une loge de théâtre, à deux pas du centre.',
    amenities: ['Lit queen size', 'Douche à l’italienne', 'Mini-bar', 'Peignoirs', 'Wi-Fi'],
    mood: 0,
    prices: _tariff(15000, 35000),
  ),
  Room(
    id: 'indigo',
    name: 'Atelier Indigo',
    category: 'Chambre design',
    tagline: 'Bleu nuit, tissé à la main.',
    synopsis: 'Hommage aux teinturiers d’indigo : textiles artisanaux, bois sombre et une grande fenêtre sur les toits de Lomé.',
    amenities: ['Lit queen size', 'Coin salon', 'Projecteur mural', 'Climatisation', 'Wi-Fi'],
    mood: 2,
    prices: _tariff(18000, 40000),
  ),
  Room(
    id: 'ambre',
    name: 'Suite Ambre',
    category: 'Suite',
    tagline: 'Une heure dorée qui dure toute la nuit.',
    synopsis: 'Lumière chaude, terrasse privée et parfum de bois précieux. La suite des longues conversations.',
    amenities: ['Lit king size', 'Terrasse privée', 'Jacuzzi', 'Machine à café', 'Enceinte Bluetooth'],
    mood: 3,
    prices: _tariff(28000, 60000),
  ),
  Room(
    id: 'baobab',
    name: 'Chambre Baobab',
    category: 'Chambre classique',
    tagline: 'Racines profondes, nuit paisible.',
    synopsis: 'Une chambre apaisante aux verts profonds, pensée pour le calme : matelas premium, linge en coton égyptien.',
    amenities: ['Lit queen size', 'Douche', 'Climatisation', 'Wi-Fi'],
    mood: 4,
    prices: _tariff(12000, 28000),
  ),
  Room(
    id: 'orchidee',
    name: 'Suite Orchidée',
    category: 'Suite romantique',
    tagline: 'Rare, délicate, et rien qu’à vous.',
    synopsis: 'Pétales, bougies LED et ciel de lit : la suite pensée pour les grandes occasions.',
    amenities: ['Lit king size à baldaquin', 'Baignoire balnéo', 'Éclairage d’ambiance', 'Champagne en option'],
    mood: 5,
    prices: _tariff(30000, 65000),
  ),
  Room(
    id: 'terracotta',
    name: 'Chambre Terre Cuite',
    category: 'Chambre deluxe',
    tagline: 'La chaleur du sable après le coucher du soleil.',
    synopsis: 'Murs en terre cuite, mobilier en rotin et douche ouverte sur un patio végétal.',
    amenities: ['Lit queen size', 'Patio privé', 'Douche extérieure', 'Climatisation'],
    mood: 6,
    prices: _tariff(16000, 36000),
  ),
  Room(
    id: 'minuit',
    name: 'Penthouse Minuit',
    category: 'Penthouse',
    tagline: 'Toute la ville à vos pieds, personne pour vous voir.',
    synopsis: 'Le dernier étage, une baie vitrée panoramique et un salon privé. La séance la plus exclusive de la maison.',
    amenities: ['Lit king size', 'Vue panoramique', 'Salon privé', 'Jacuzzi', 'Accès prioritaire'],
    mood: 7,
    prices: _tariff(40000, 90000),
  ),
];
