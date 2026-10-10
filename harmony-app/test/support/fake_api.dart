import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// Réponse factice avec un code HTTP explicite (par défaut 200).
class FakeReply {
  const FakeReply(this.status, this.body);

  final int status;
  final Object? body;
}

typedef FakeHandler = Object? Function(RequestOptions request);

/// Adaptateur HTTP de test : sert les routes déclarées (« GET /zones »…) et simule
/// une coupure réseau pour toutes les autres. Garde la trace des requêtes reçues.
class FakeApi implements HttpClientAdapter {
  FakeApi([Map<String, FakeHandler>? routes]) : routes = {...?routes};

  final Map<String, FakeHandler> routes;
  final List<RequestOptions> requests = [];

  RequestOptions? last(String route) {
    for (final r in requests.reversed) {
      if ('${r.method} ${r.path}' == route) return r;
    }
    return null;
  }

  Dio dio() => Dio(BaseOptions(baseUrl: 'https://api.test/api/v1'))..httpClientAdapter = this;

  @override
  Future<ResponseBody> fetch(RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    requests.add(options);
    final handler = routes['${options.method} ${options.path}'];
    if (handler == null) {
      throw DioException.connectionError(requestOptions: options, reason: 'hors connexion (test)');
    }
    final result = handler(options);
    final reply = result is FakeReply ? result : FakeReply(200, result);
    return ResponseBody.fromString(
      jsonEncode(reply.body),
      reply.status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

// ---------------------------------------------------------------------------
// Jeux de données au format de l'API.

Map<String, dynamic> userJson({String name = 'Afi'}) =>
    {'id': 7, 'phone': '+22890000000', 'name': name, 'email': null, 'role': 'client'};

List<Map<String, dynamic>> availabilityJson(RequestOptions r) {
  final from = DateTime.parse(r.queryParameters['from'] as String);
  final to = DateTime.parse(r.queryParameters['to'] as String);
  return [
    for (var d = from; !d.isAfter(to); d = DateTime(d.year, d.month, d.day + 1))
      {
        'date': '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
        'status': 'free',
        'price': 150000,
      },
  ];
}

Map<String, dynamic> quoteJson(DateTime checkIn, DateTime checkOut) => {
      'start_at': DateTime.utc(checkIn.year, checkIn.month, checkIn.day, 14).toIso8601String(),
      'end_at': DateTime.utc(checkOut.year, checkOut.month, checkOut.day, 11).toIso8601String(),
      'nights': 2,
      'lines': [
        {'label': '2 nuits', 'amount': 300000},
        {'label': 'Frais de service', 'amount': 15000},
      ],
      'accommodation': 300000,
      'service_fee': 15000,
      'total': 315000,
      'advance': 94500,
      'balance': 220500,
      'security_deposit': 100000,
    };

Map<String, dynamic> bookingJson({
  required DateTime checkIn,
  required DateTime checkOut,
  String status = 'pending',
  String? instructions,
  bool canReview = false,
  int? reviewRating,
}) =>
    {
      'reference': 'HH-TEST01',
      'status': status,
      'status_label': switch (status) {
        'pending' => 'En attente de paiement',
        'completed' => 'Terminée',
        _ => 'Confirmée',
      },
      'can_review': canReview,
      'review': reviewRating == null ? null : {'rating': reviewRating, 'comment': null},
      'stay_type_label': 'Nuitées',
      'start_at': DateTime.utc(checkIn.year, checkIn.month, checkIn.day, 14).toIso8601String(),
      'end_at': DateTime.utc(checkOut.year, checkOut.month, checkOut.day, 11).toIso8601String(),
      'nights': 2,
      'guests': 2,
      'apartment': {
        'slug': 'villa-lagune',
        'title': 'Villa Lagune',
        'zone': 'Baguida',
        'cover': null,
        'address': null,
        'latitude': null,
        'longitude': null,
      },
      'amounts': {'total': 315000, 'paid': 0, 'balance_due': 315000, 'advance': 94500, 'security_deposit': 100000},
      'price_breakdown': [
        {'label': '2 nuits', 'amount': 300000},
        {'label': 'Frais de service', 'amount': 15000},
      ],
      'cancellation_deadline': null,
      'payments': [
        {
          'id': 1,
          'kind': 'advance',
          'kind_label': 'Acompte',
          'method_label': 'Virement bancaire',
          'status': 'pending',
          'status_label': 'En attente',
          'amount': 94500,
          'checkout_url': null,
          'instructions': instructions,
        },
      ],
    };
