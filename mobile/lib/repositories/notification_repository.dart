import '../core/api_constants.dart';
import '../services/api_service.dart';

class NotificationRepository {
  final ApiService _apiService;

  NotificationRepository(this._apiService);

  Future<void> enviar({
    required String email,
    required String asunto,
    required String mensaje,
  }) async {
    await _apiService.dio.post(
      ApiConstants.notificationsSend,
      data: {'email': email, 'subject': asunto, 'message': mensaje},
    );
  }
}
