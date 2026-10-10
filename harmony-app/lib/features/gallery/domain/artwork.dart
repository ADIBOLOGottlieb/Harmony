import '../../../core/i18n/i18n.dart';
import '../../catalog/data/catalog_api.dart';

/// Montant FCFA : tolère un nombre décimal ou absent (0).
int _int(Object? value) => (value as num?)?.toInt() ?? 0;

class Artist {
  const Artist({required this.slug, required this.name, this.bio, this.country, this.portrait});

  final String slug;
  final String name;
  final String? bio;
  final String? country;
  final String? portrait;

  factory Artist.fromJson(Json j) => Artist(
        slug: j['slug'] as String,
        name: j['name'] as String,
        bio: j['bio'] as String?,
        country: j['country'] as String?,
        portrait: photoSource(j['portrait'] as String?),
      );
}

enum ArtworkStatus {
  available('available', 'Disponible'),
  reserved('reserved', 'Réservée'),
  sold('sold', 'Vendue');

  const ArtworkStatus(this.code, this._label);
  final String code;
  final String _label;

  String get label => t(_label);

  static ArtworkStatus fromCode(String? code) => values.firstWhere((s) => s.code == code, orElse: () => sold);
}

class Artwork {
  const Artwork({
    required this.slug,
    required this.title,
    required this.description,
    required this.medium,
    required this.dimensions,
    required this.price,
    required this.status,
    required this.artist,
    required this.photos,
    this.year,
    this.featured = false,
    this.deliveryFee = 0,
  });

  final String slug;
  final String title;
  final String description;
  final String medium;
  final String dimensions;
  final int? year;
  final int price;
  final ArtworkStatus status;
  final bool featured;
  final Artist? artist;
  final List<String> photos;

  /// Frais de livraison à Lomé appliqués si le client choisit la livraison.
  final int deliveryFee;

  String get cover => photos.isEmpty ? '' : photos.first;
  String get heroTag => 'artwork-$slug';
  bool get isAvailable => status == ArtworkStatus.available;

  factory Artwork.fromJson(Json j) => Artwork(
        slug: j['slug'] as String,
        title: j['title'] as String,
        description: j['description'] as String? ?? '',
        medium: j['medium'] as String? ?? '',
        dimensions: j['dimensions'] as String? ?? '',
        year: (j['year'] as num?)?.toInt(),
        price: _int(j['price']),
        status: ArtworkStatus.fromCode(j['status'] as String?),
        featured: j['featured'] as bool? ?? false,
        artist: j['artist'] is Map ? Artist.fromJson(j['artist'] as Json) : null,
        photos: [for (final p in (j['photos'] as List? ?? const [])) photoSource(p as String?)]..removeWhere((p) => p.isEmpty),
        deliveryFee: _int(j['delivery_fee']),
      );
}

enum DeliveryMethod {
  pickup('pickup', 'Retrait à la galerie'),
  delivery('delivery', 'Livraison à Lomé');

  const DeliveryMethod(this.code, this._label);
  final String code;
  final String _label;

  String get label => t(_label);

  static DeliveryMethod fromCode(String? code) => values.firstWhere((d) => d.code == code, orElse: () => pickup);
}

/// Demande d'acquisition d'une œuvre (réservée au client le temps du règlement).
class ArtworkOrder {
  const ArtworkOrder({
    required this.reference,
    required this.status,
    required this.artworkSlug,
    required this.artworkTitle,
    required this.price,
    required this.deliveryMethod,
    required this.deliveryFee,
    required this.total,
    this.artistName,
    this.cover,
    this.deliveryAddress,
    this.expiresAt,
    this.paymentInstructions,
  });

  final String reference;

  /// pending, paid, cancelled.
  final String status;
  final String artworkSlug;
  final String artworkTitle;
  final String? artistName;
  final String? cover;
  final int price;
  final DeliveryMethod deliveryMethod;
  final int deliveryFee;
  final int total;
  final String? deliveryAddress;
  final DateTime? expiresAt;
  final String? paymentInstructions;

  bool get isPending => status == 'pending';

  String get statusLabel => switch (status) {
        'pending' => t('En attente de règlement'),
        'paid' => t('Réglée'),
        _ => t('Annulée'),
      };

  factory ArtworkOrder.fromJson(Json j) {
    final artwork = j['artwork'] as Json? ?? const {};
    final expires = j['expires_at'] as String?;
    return ArtworkOrder(
      reference: j['reference'] as String,
      status: j['status'] as String,
      artworkSlug: artwork['slug'] as String? ?? '',
      artworkTitle: artwork['title'] as String? ?? '',
      artistName: artwork['artist'] as String?,
      cover: photoSource(artwork['cover'] as String?),
      price: _int(j['price']),
      deliveryMethod: DeliveryMethod.fromCode(j['delivery_method'] as String?),
      deliveryFee: _int(j['delivery_fee']),
      total: _int(j['total']),
      deliveryAddress: j['delivery_address'] as String?,
      expiresAt: expires == null ? null : DateTime.parse(expires),
      paymentInstructions: j['payment_instructions'] as String?,
    );
  }
}
