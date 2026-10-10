import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../catalog/domain/apartment.dart';
import '../data/booking_api.dart';
import '../domain/booking_models.dart';

/// Réservation en cours de composition (dates, voyageurs, moyen de paiement).
@immutable
class BookingDraft {
  const BookingDraft({
    required this.apartmentId,
    this.stayType = StayType.night,
    this.checkIn,
    this.checkOut,
    this.startTime,
    this.guests = 1,
    this.paymentMethod = PaymentMethod.mobileMoney,
  });

  final String apartmentId;
  final StayType stayType;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String? startTime;
  final int guests;
  final PaymentMethod paymentMethod;

  bool get isComplete => switch (stayType) {
        StayType.night => checkIn != null && checkOut != null,
        StayType.day => checkIn != null,
        StayType.threeHours => checkIn != null && startTime != null,
      };

  BookingDraft copyWith({
    StayType? stayType,
    DateTime? Function()? checkIn,
    DateTime? Function()? checkOut,
    String? Function()? startTime,
    int? guests,
    PaymentMethod? paymentMethod,
  }) {
    return BookingDraft(
      apartmentId: apartmentId,
      stayType: stayType ?? this.stayType,
      checkIn: checkIn != null ? checkIn() : this.checkIn,
      checkOut: checkOut != null ? checkOut() : this.checkOut,
      startTime: startTime != null ? startTime() : this.startTime,
      guests: guests ?? this.guests,
      paymentMethod: paymentMethod ?? this.paymentMethod,
    );
  }

  BookingRequest toRequest({bool withPayment = false}) => BookingRequest(
        apartmentId: apartmentId,
        stayType: stayType,
        checkIn: checkIn!,
        checkOut: checkOut,
        startTime: startTime,
        guests: guests,
        paymentMethod: withPayment ? paymentMethod : null,
      );
}

final bookingDraftProvider = NotifierProvider<BookingDraftController, BookingDraft?>(BookingDraftController.new);

class BookingDraftController extends Notifier<BookingDraft?> {
  @override
  BookingDraft? build() => null;

  void start(Apartment apartment, {int guests = 1}) =>
      state = BookingDraft(apartmentId: apartment.id, guests: guests.clamp(1, apartment.capacity));

  void update(BookingDraft Function(BookingDraft draft) change) {
    final current = state;
    if (current != null) state = change(current);
  }
}

/// Devis du brouillon courant (recalculé à chaque changement).
final quoteProvider = FutureProvider.autoDispose<Quote>((ref) {
  final draft = ref.watch(bookingDraftProvider);
  if (draft == null || !draft.isComplete) throw StateError('Brouillon incomplet');
  return ref.watch(bookingApiProvider).quote(draft.toRequest());
});
