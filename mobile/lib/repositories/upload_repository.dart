import 'package:dio/dio.dart';
import '../core/api_constants.dart';
import '../services/api_service.dart';
import 'dart:io';

class UploadRepository {
  final ApiService _apiService;

  UploadRepository(this._apiService);

  Future<List<dynamic>> listarArchivos() async {
    final response = await _apiService.dio.get(ApiConstants.upload);
    return response.data;
  }

  Future<Map<String, dynamic>> subirArchivo(
      String rutaArchivo,
      void Function(double progreso) onProgress,
      ) async {
    final nombre = rutaArchivo.split(Platform.pathSeparator).last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(rutaArchivo, filename: nombre),
    });

    final response = await _apiService.dio.post(
      ApiConstants.upload,
      data: formData,
      onSendProgress: (enviado, total) {
        if (total > 0) {
          onProgress(enviado / total);
        }
      },
    );

    return response.data;
  }
}