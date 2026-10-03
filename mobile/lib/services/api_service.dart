import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/api_constants.dart';

class ApiService {
  final Dio dio;
  final FlutterSecureStorage storage = const FlutterSecureStorage();

  ApiService()
      : dio = Dio(
    BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      sendTimeout: const Duration(seconds: 10),
    ),
  ) {
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Login y registro NO necesitan JWT.
          final esRutaDeAutenticacion =
              options.path == ApiConstants.login ||
                  options.path == ApiConstants.register;

          if (!esRutaDeAutenticacion) {
            final token = await storage.read(key: 'jwt_token');

            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          return handler.next(options);
        },
      ),
    );
  }
}