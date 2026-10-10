import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';

class AppUser {
  const AppUser({required this.id, required this.phone, this.name, this.email, required this.role});

  final int id;
  final String phone;
  final String? name;
  final String? email;
  final String role;

  String get displayName => (name == null || name!.trim().isEmpty) ? phone : name!;

  factory AppUser.fromJson(Map<String, dynamic> j) => AppUser(
        id: j['id'] as int,
        phone: j['phone'] as String,
        name: j['name'] as String?,
        email: j['email'] as String?,
        role: j['role'] as String,
      );

  Map<String, dynamic> toJson() => {'id': id, 'phone': phone, 'name': name, 'email': email, 'role': role};
}

/// Connexion par téléphone et code à usage unique.
class AuthApi {
  AuthApi(this._dio);

  final Dio _dio;

  /// Demande un code. Renvoie le code en clair uniquement en mode démonstration
  /// (API configurée sans prestataire SMS).
  Future<String?> requestOtp(String phone) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/auth/otp', data: {'phone': phone});
      return response.data?['debug_code'] as String?;
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<({String token, AppUser user})> verify(String phone, String code, {String? name}) async {
    try {
      final response = await _dio.post<Map<String, dynamic>>('/auth/verify', data: {
        'phone': phone,
        'code': code,
        if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
      });
      final data = response.data!;
      return (token: data['token'] as String, user: AppUser.fromJson(data['user'] as Map<String, dynamic>));
    } catch (e) {
      throw ApiError.from(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post<void>('/auth/logout');
    } catch (_) {
      // Déconnexion locale quoi qu'il arrive.
    }
  }
}

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(apiClientProvider)));

/// Normalise un numéro saisi : espaces retirés, indicatif du Togo ajouté pour 8 chiffres.
String normalizePhone(String input) {
  final digits = input.replaceAll(RegExp(r'[\s.\-()]'), '');
  if (RegExp(r'^\d{8}$').hasMatch(digits)) return '+228$digits';
  if (digits.startsWith('00')) return '+${digits.substring(2)}';
  return digits;
}
