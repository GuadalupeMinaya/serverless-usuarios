import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_constants.dart';
import '../services/api_service.dart';

class AuthRepository {
  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  AuthRepository(this._apiService);

  /// Llama a /auth/login, guarda el token si el login es correcto,
  /// y devuelve true/false según el resultado.
  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.dio.post(
        ApiConstants.login,
        data: {
          'email': email,
          'password': password,
        },
      );

      final token = response.data['token'];
      await _storage.write(key: 'jwt_token', value: token);

      return true;
    } on DioException catch (_) {
      return false;
    }
  }

  /// Registra un nuevo usuario usando /auth/register.
  /// Si el registro es correcto, guarda también el token JWT.
  Future<bool> register(
      String nombre,
      String email,
      String password,
      ) async {
    try {
      final response = await _apiService.dio.post(
        ApiConstants.register,
        data: {
          'nombre': nombre,
          'email': email,
          'password': password,
        },
      );

      final token = response.data['token'];
      await _storage.write(key: 'jwt_token', value: token);

      return true;
    } on DioException catch (_) {
      return false;
    }
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
  }

  Future<bool> tieneSesion() async {
    final token = await _storage.read(key: 'jwt_token');
    return token != null;
  }
}