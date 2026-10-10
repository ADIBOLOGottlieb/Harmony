import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/storage.dart';

/// Client HTTP de l'API HARMONY HOME. Ajoute le jeton de session s'il existe.
/// Délai de réponse large : l'hébergement gratuit peut mettre près d'une minute à se réveiller.
final apiClientProvider = Provider<Dio>((ref) {
  final dio = Dio(BaseOptions(
    baseUrl: AppConfig.apiBaseUrl,
    connectTimeout: const Duration(seconds: 20),
    receiveTimeout: const Duration(seconds: 75),
    headers: {'Accept': 'application/json'},
  ));
  dio.interceptors.add(InterceptorsWrapper(
    onRequest: (options, handler) async {
      final token = await ref.read(tokenStoreProvider).read();
      if (token != null) options.headers['Authorization'] = 'Bearer $token';
      handler.next(options);
    },
  ));
  return dio;
});

/// Erreur présentable à l'utilisateur, en français.
class ApiError implements Exception {
  const ApiError(this.message, {this.code, this.status, this.offline = false});

  final String message;

  /// Code métier stable renvoyé par l'API (ex. `dates_unavailable`).
  final String? code;
  final int? status;
  final bool offline;

  factory ApiError.from(Object error) {
    if (error is ApiError) return error;
    if (error is DioException) {
      final data = error.response?.data;
      String? message;
      String? code;
      if (data is Map) {
        message = data['message'] as String?;
        code = data['code'] as String?;
        final errors = data['errors'];
        if (errors is Map && errors.isNotEmpty) {
          final first = errors.values.first;
          if (first is List && first.isNotEmpty) message = first.first.toString();
        }
      }
      final status = error.response?.statusCode;
      if (status == 401) {
        return const ApiError('Votre session a expiré. Reconnectez-vous.', status: 401);
      }
      if (status == 429) {
        return const ApiError('Trop de tentatives. Patientez une minute avant de réessayer.', status: 429);
      }
      final offline = error.response == null;
      return ApiError(
        message ??
            (offline
                ? 'Connexion impossible. Vérifiez votre accès à Internet puis réessayez.'
                : 'Une erreur est survenue. Réessayez dans un instant.'),
        code: code,
        status: status,
        offline: offline,
      );
    }
    return const ApiError('Une erreur est survenue. Réessayez dans un instant.');
  }

  @override
  String toString() => message;
}
