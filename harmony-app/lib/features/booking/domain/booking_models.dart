import 'package:flutter/material.dart';

typedef Json = Map<String, dynamic>;

/// Types de séjour (codes de l'API).
enum StayType {
  night('night', 'Nuitées'),
  day('day', 'Journée'),
  threeHours('three_hours', '3 heures');

  const StayType(this.code, this.label);
  final String code;
  final String label;
}

/// Moyens de paiement proposés au client.
enum PaymentMethod {
  mobileMoney('mobile_money', 'Mobile Money', 'TMoney ou Flooz', Icons.phone_iphone_rounded),
  card('card', 'Carte bancaire', 'Visa, Mastercard', Icons.credit_card_rounded),
  bankTransfer('bank_transfer', 'Virement bancaire', 'Confirmé par la conciergerie à réception', Icons.account_balance_outlined);

  const PaymentMethod(this.code, this.label, this.hint, this.icon);
  final String code;
  final String label;
  final String hint;
  final IconData icon;
}

enum DayStatus { free, booked, blocked, past }

class DayAvailability {
  const DayAvailability({required this.date, required this.status, required this.price});

  final DateTime date;
  final DayStatus status;
  final int price;

  factory DayAvailability.fromJson(Json j) {
    final parts = (j['date'] as String).split('-').map(int.parse).toList();
    return DayAvailability(
      date: DateTime(parts[0], parts[1], parts[2]),
      status: DayStatus.values.firstWhere((s) => s.name == j['status'], orElse: () => DayStatus.blocked),
      price: j['price'] as int,
    );
  }
}

class PriceLine {
  const PriceLine(this.label, this.amount);

  final String label;
  final int amount;

  factory PriceLine.fromJson(Json j) => PriceLine(j['label'] as String, j['amount'] as int);
}

/// Devis renvoyé par l'API. Montants en FCFA (entiers).
class Quote {
  const Quote({
    required this.startAt,
    required this.endAt,
    required this.nights,
    required this.lines,
    required this.accommodation,
    required this.serviceFee,
    required this.total,
    required this.advance,
    required this.balance,
    required this.securityDeposit,
  });

  final DateTime startAt;
  final DateTime endAt;
  final int nights;
  final List<PriceLine> lines;
  final int accommodation;
  final int serviceFee;
  final int total;
  final int advance;
  final int balance;
  final int securityDeposit;

  factory Quote.fromJson(Json j) => Quote(
        startAt: DateTime.parse(j['start_at'] as String),
        endAt: DateTime.parse(j['end_at'] as String),
        nights: j['nights'] as int,
        lines: (j['lines'] as List).map((l) => PriceLine.fromJson(l as Json)).toList(),
        accommodation: j['accommodation'] as int,
        serviceFee: j['service_fee'] as int,
        total: j['total'] as int,
        advance: j['advance'] as int,
        balance: j['balance'] as int,
        securityDeposit: j['security_deposit'] as int,
      );
}

class BookingPayment {
  const BookingPayment({
    required this.id,
    required this.kind,
    required this.kindLabel,
    required this.methodLabel,
    required this.status,
    required this.statusLabel,
    required this.amount,
    this.checkoutUrl,
    this.instructions,
  });

  final int id;
  final String kind;
  final String kindLabel;
  final String methodLabel;
  final String status;
  final String statusLabel;
  final int amount;
  final String? checkoutUrl;
  final String? instructions;

  bool get isPending => status == 'pending';

  factory BookingPayment.fromJson(Json j) => BookingPayment(
        id: j['id'] as int,
        kind: j['kind'] as String,
        kindLabel: j['kind_label'] as String,
        methodLabel: j['method_label'] as String,
        status: j['status'] as String,
        statusLabel: j['status_label'] as String,
        amount: j['amount'] as int,
        checkoutUrl: j['checkout_url'] as String?,
        instructions: j['instructions'] as String?,
      );
}

/// Réservation telle que vue par le client.
class Booking {
  const Booking({
    required this.reference,
    required this.status,
    required this.statusLabel,
    required this.stayTypeLabel,
    required this.startAt,
    required this.endAt,
    required this.nights,
    required this.guests,
    required this.apartmentSlug,
    required this.apartmentTitle,
    required this.apartmentZone,
    required this.apartmentCover,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.total,
    required this.paid,
    required this.balanceDue,
    required this.advance,
    required this.securityDeposit,
    required this.lines,
    required this.cancellationDeadline,
    required this.payments,
  });

  final String reference;

  /// pending, confirmed, cancelled, completed, refunded.
  final String status;
  final String statusLabel;
  final String stayTypeLabel;
  final DateTime startAt;
  final DateTime endAt;
  final int nights;
  final int guests;
  final String apartmentSlug;
  final String apartmentTitle;
  final String? apartmentZone;
  final String? apartmentCover;

  /// Adresse exacte et position : fournies par l'API seulement une fois la réservation confirmée.
  final String? address;
  final double? latitude;
  final double? longitude;
  final int total;
  final int paid;
  final int balanceDue;
  final int advance;
  final int securityDeposit;
  final List<PriceLine> lines;
  final DateTime? cancellationDeadline;
  final List<BookingPayment> payments;

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancellable => status == 'pending' || status == 'confirmed';

  BookingPayment? get pendingPayment {
    for (final p in payments) {
      if (p.isPending && p.kind != 'refund') return p;
    }
    return null;
  }

  factory Booking.fromJson(Json j) {
    final apartment = j['apartment'] as Json;
    final amounts = j['amounts'] as Json;
    final deadline = j['cancellation_deadline'] as String?;
    return Booking(
      reference: j['reference'] as String,
      status: j['status'] as String,
      statusLabel: j['status_label'] as String,
      stayTypeLabel: j['stay_type_label'] as String,
      startAt: DateTime.parse(j['start_at'] as String),
      endAt: DateTime.parse(j['end_at'] as String),
      nights: j['nights'] as int,
      guests: j['guests'] as int,
      apartmentSlug: apartment['slug'] as String,
      apartmentTitle: apartment['title'] as String,
      apartmentZone: apartment['zone'] as String?,
      apartmentCover: apartment['cover'] as String?,
      address: apartment['address'] as String?,
      latitude: (apartment['latitude'] as num?)?.toDouble(),
      longitude: (apartment['longitude'] as num?)?.toDouble(),
      total: amounts['total'] as int,
      paid: amounts['paid'] as int,
      balanceDue: amounts['balance_due'] as int,
      advance: amounts['advance'] as int,
      securityDeposit: amounts['security_deposit'] as int,
      lines: (j['price_breakdown'] as List? ?? const []).map((l) => PriceLine.fromJson(l as Json)).toList(),
      cancellationDeadline: deadline == null ? null : DateTime.parse(deadline),
      payments: (j['payments'] as List? ?? const []).map((p) => BookingPayment.fromJson(p as Json)).toList(),
    );
  }
}
