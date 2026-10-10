import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../catalog/data/catalog_api.dart';
import '../domain/artwork.dart';

/// Galerie d'art : œuvres publiées, artistes, acquisitions du client.
class GalleryApi {
  GalleryApi(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<List<Artist>> artists() => _call(() async {
        final r = await _dio.get<Json>('/gallery/artists');
        return [for (final a in r.data!['data'] as List) Artist.fromJson(a as Json)];
      });

  Future<List<Artwork>> artworks() => _call(() async {
        final r = await _dio.get<Json>('/gallery/artworks');
        return [for (final a in r.data!['data'] as List) Artwork.fromJson(a as Json)];
      });

  Future<Artwork> artwork(String slug) => _call(() async {
        final r = await _dio.get<Json>('/gallery/artworks/$slug');
        return Artwork.fromJson(r.data!['data'] as Json);
      });

  Future<ArtworkOrder> order(String slug, DeliveryMethod delivery, {String? address, String? note}) => _call(() async {
        final r = await _dio.post<Json>('/gallery/artworks/$slug/orders', data: {
          'delivery_method': delivery.code,
          if (delivery == DeliveryMethod.delivery) 'delivery_address': address?.trim(),
          if (note != null && note.trim().isNotEmpty) 'note': note.trim(),
        });
        return ArtworkOrder.fromJson(r.data!['data'] as Json);
      });

  Future<List<ArtworkOrder>> myOrders() => _call(() async {
        final r = await _dio.get<Json>('/gallery/orders');
        return [for (final o in r.data!['data'] as List) ArtworkOrder.fromJson(o as Json)];
      });

  Future<ArtworkOrder> cancel(String reference) => _call(() async {
        final r = await _dio.post<Json>('/gallery/orders/$reference/cancel');
        return ArtworkOrder.fromJson(r.data!['data'] as Json);
      });
}

final galleryApiProvider = Provider<GalleryApi>((ref) => GalleryApi(ref.watch(apiClientProvider)));

/// Œuvres publiées (disponibles d'abord, tri fait par l'API).
final artworksProvider = FutureProvider.autoDispose<List<Artwork>>((ref) => ref.watch(galleryApiProvider).artworks());

final artworkProvider =
    FutureProvider.autoDispose.family<Artwork, String>((ref, slug) => ref.watch(galleryApiProvider).artwork(slug));

final myArtworkOrdersProvider =
    FutureProvider.autoDispose<List<ArtworkOrder>>((ref) => ref.watch(galleryApiProvider).myOrders());

/// Filtre de la galerie : null = toutes les œuvres, sinon le slug d'un artiste.
final galleryArtistFilterProvider = NotifierProvider<GalleryFilter, String?>(GalleryFilter.new);

class GalleryFilter extends Notifier<String?> {
  @override
  String? build() => null;

  void set(String? artist) => state = artist;
}

/// Seulement les œuvres disponibles à la vente.
final galleryAvailableOnlyProvider = NotifierProvider<GalleryAvailableOnly, bool>(GalleryAvailableOnly.new);

class GalleryAvailableOnly extends Notifier<bool> {
  @override
  bool build() => false;

  void toggle() => state = !state;
}
