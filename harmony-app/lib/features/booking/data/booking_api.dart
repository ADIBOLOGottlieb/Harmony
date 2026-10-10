import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/format/dates.dart';
import '../../../core/network/api_client.dart';
import '../domain/booking_models.dart';

/// Demande de devis ou de réservation.
class BookingRequest {
  const BookingRequest({
    required this.apartmentId,
    required this.stayType,
    required this.checkIn,
    this.checkOut,
    this.startTime,
    required this.guests,
    this.paymentMethod,
  });

  final String apartmentId;
  final StayType stayType;
  final DateTime checkIn;
  final DateTime? checkOut;

  /// « 15:00 » pour un créneau de 3 heures.
  final String? startTime;
  final int guests;
  final PaymentMethod? paymentMethod;

  Json toJson() => {
        'apartment': apartmentId,
        'stay_type': stayType.code,
        'check_in': isoDay(checkIn),
        if (stayType == StayType.night && checkOut != null) 'check_out': isoDay(checkOut!),
        if (stayType == StayType.threeHours) 'start_time': startTime,
        'guests': guests,
        if (paymentMethod != null) 'payment_method': paymentMethod!.code,
      };
}

class BookingApi {
  BookingApi(this._dio);

  final Dio _dio;

  Future<T> _call<T>(Future<T> Function() request) async {
    try {
      return await request();
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<List<DayAvailability>> availability(String apartmentId, DateTime from, DateTime to) => _call(() async {
        final r = await _dio.get<Json>('/apartments/$apartmentId/availability',
            queryParameters: {'from': isoDay(from), 'to': isoDay(to)});
        return (r.data!['data'] as List).map((d) => DayAvailability.fromJson(d as Json)).toList();
      });

  Future<Quote> quote(BookingRequest request) => _call(() async {
        final r = await _dio.post<Json>('/bookings/quote', data: request.toJson());
        return Quote.fromJson(r.data!['data'] as Json);
      });

  Future<Booking> create(BookingRequest request) => _call(() async {
        final r = await _dio.post<Json>('/bookings', data: request.toJson());
        return Booking.fromJson(r.data!['data'] as Json);
      });

  Future<List<Booking>> mine() => _call(() async {
        final r = await _dio.get<Json>('/bookings');
        return (r.data!['data'] as List).map((b) => Booking.fromJson(b as Json)).toList();
      });

  Future<Booking> get(String reference) => _call(() async {
        final r = await _dio.get<Json>('/bookings/$reference');
        return Booking.fromJson(r.data!['data'] as Json);
      });

  Future<Booking> cancel(String reference) => _call(() async {
        final r = await _dio.post<Json>('/bookings/$reference/cancel');
        return Booking.fromJson(r.data!['data'] as Json);
      });

  Future<Booking> payBalance(String reference, PaymentMethod method) => _call(() async {
        final r = await _dio.post<Json>('/bookings/$reference/pay-balance', data: {'payment_method': method.code});
        return Booking.fromJson(r.data!['data'] as Json);
      });
}

final bookingApiProvider = Provider<BookingApi>((ref) => BookingApi(ref.watch(apiClientProvider)));

/// Disponibilités des 90 prochains jours d'un appartement.
final availabilityProvider = FutureProvider.autoDispose.family<List<DayAvailability>, String>((ref, apartmentId) {
  final today = todayInLome();
  return ref.watch(bookingApiProvider).availability(apartmentId, today, today.add(const Duration(days: 89)));
});

final myBookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) => ref.watch(bookingApiProvider).mine());

final bookingDetailProvider =
    FutureProvider.autoDispose.family<Booking, String>((ref, reference) => ref.watch(bookingApiProvider).get(reference));
