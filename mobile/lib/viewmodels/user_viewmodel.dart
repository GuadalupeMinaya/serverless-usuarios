import 'package:flutter/material.dart';
import '../models/user.dart';
import '../repositories/user_repository.dart';
import '../repositories/upload_repository.dart';

class UserViewModel extends ChangeNotifier {
  final UserRepository _userRepository;
  final UploadRepository _uploadRepository;

  UserViewModel(this._userRepository, this._uploadRepository);

  List<User> usuarios = [];
  int totalArchivos = 0;

  bool isLoading = false;
  String? errorMessage;

  String _busqueda = '';

  String get busqueda => _busqueda;

  List<User> get usuariosFiltrados {
    if (_busqueda.trim().isEmpty) {
      return usuarios;
    }

    final texto = _busqueda.toLowerCase().trim();

    return usuarios.where((usuario) {
      final nombre = usuario.nombre.toLowerCase();
      final email = usuario.email.toLowerCase();

      return nombre.contains(texto) || email.contains(texto);
    }).toList();
  }

  void buscar(String texto) {
    _busqueda = texto;
    notifyListeners();
  }

  void limpiarBusqueda() {
    _busqueda = '';
    notifyListeners();
  }

  Future<void> cargarUsuarios() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      usuarios = await _userRepository.listarUsuarios();
    } catch (e) {
      errorMessage = 'No se pudieron cargar los usuarios';
    }

    isLoading = false;
    notifyListeners();
  }

  /// Carga usuarios y archivos de forma concurrente.
  /// Las dos peticiones se ejecutan al mismo tiempo.
  Future<void> cargarDatosIniciales() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final resultados = await Future.wait([
        _userRepository.listarUsuarios(), //privadas
        _uploadRepository.listarArchivos(),
      ]);

      usuarios = resultados[0] as List<User>;
      totalArchivos = (resultados[1]).length;
    } catch (e) {
      errorMessage = 'No se pudieron cargar los datos';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> crearUsuario(
    String nombre,
    String email,
    String password, {
    String? fotoUrl,
  }) async {
    try {
      final nuevo = User(
        nombre: nombre,
        email: email,
        password: password,
        fotoUrl: fotoUrl,
      );

      await _userRepository.crearUsuario(nuevo);
      await cargarDatosIniciales();

      return true;
    } catch (e) {
      errorMessage = 'No se pudo crear el usuario';
      notifyListeners();
      return false;
    }
  }

  Future<bool> actualizarUsuario(
    int id,
    String nombre,
    String email,
    String? password, {
    String? fotoUrl,
  }) async {
    try {
      final editado = User(
        nombre: nombre,
        email: email,
        password: password,
        fotoUrl: fotoUrl,
      );

      await _userRepository.actualizarUsuario(id, editado);
      await cargarDatosIniciales();

      return true;
    } catch (e) {
      errorMessage = 'No se pudo actualizar el usuario';
      notifyListeners();
      return false;
    }
  }

  Future<bool> eliminarUsuario(int id) async {
    try {
      await _userRepository.eliminarUsuario(id);
      await cargarUsuarios();

      return true;
    } catch (e) {
      errorMessage = 'No se pudo eliminar el usuario';
      notifyListeners();
      return false;
    }
  }
}
