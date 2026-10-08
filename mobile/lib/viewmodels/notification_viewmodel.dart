import 'package:flutter/material.dart';
import '../repositories/notification_repository.dart';

class NotificationViewModel extends ChangeNotifier {
  final NotificationRepository _repository;

  NotificationViewModel(this._repository);

  bool isSending = false;

  Future<bool> enviar({
    required String email,
    required String asunto,
    required String mensaje,
  }) async {
    isSending = true;
    notifyListeners();

    try {
      await _repository.enviar(email: email, asunto: asunto, mensaje: mensaje);
      return true;
    } catch (_) {
      return false;
    } finally {
      isSending = false;
      notifyListeners();
    }
  }
}
