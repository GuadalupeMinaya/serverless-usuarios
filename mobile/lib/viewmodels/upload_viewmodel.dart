import 'package:flutter/material.dart';
import '../repositories/upload_repository.dart';

class UploadViewModel extends ChangeNotifier {
  final UploadRepository _uploadRepository;

  UploadViewModel(this._uploadRepository);

  bool isUploading = false;
  double progreso = 0.0;
  String? errorMessage;
  String? urlSubida; // la url del último archivo subido con éxito

  Future<bool> subir(String rutaArchivo) async {
    isUploading = true;
    progreso = 0.0;
    errorMessage = null;
    urlSubida = null;
    notifyListeners();

    try {
      final resultado = await _uploadRepository.subirArchivo(
        rutaArchivo,
            (p) {
          progreso = p;
          notifyListeners(); // esto es lo que mueve la barra en vivo
        },
      );
      urlSubida = resultado['url'];
      isUploading = false;
      notifyListeners();
      return true;
    } catch (e) {
      errorMessage = 'No se pudo subir el archivo';
      isUploading = false;
      notifyListeners();
      return false;
    }
  }
}