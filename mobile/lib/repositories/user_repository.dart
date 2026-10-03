import '../core/api_constants.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class UserRepository {
  final ApiService _apiService;

  UserRepository(this._apiService);

  Future<List<User>> listarUsuarios() async {
    final response = await _apiService.dio.get(ApiConstants.usuarios);
    final List<dynamic> data = response.data;
    return data.map((json) => User.fromJson(json)).toList();
  }

  Future<User> crearUsuario(User usuario) async {
    final response = await _apiService.dio.post(
      ApiConstants.usuarios,
      data: usuario.toJson(),
    );
    return User.fromJson(response.data);
  }

  Future<User> actualizarUsuario(int id, User usuario) async {
    final response = await _apiService.dio.put(
      '${ApiConstants.usuarios}/$id',
      data: usuario.toJson(),
    );
    return User.fromJson(response.data);
  }

  Future<void> eliminarUsuario(int id) async {
    await _apiService.dio.delete('${ApiConstants.usuarios}/$id');
  }
}