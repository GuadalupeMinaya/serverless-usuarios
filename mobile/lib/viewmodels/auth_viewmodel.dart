import 'package:flutter/material.dart';
import '../repositories/auth_repository.dart';

class AuthViewModel extends ChangeNotifier {
  final AuthRepository _authRepository;

  AuthViewModel(this._authRepository);

  bool isLoading = false;
  String? errorMessage;

  Future<bool> login(String email, String password) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final exito = await _authRepository.login(email, password);

    isLoading = false;

    if (!exito) {
      errorMessage = 'Correo o contraseña incorrectos';
    }

    notifyListeners();

    return exito;
  }

  Future<bool> register(
      String nombre,
      String email,
      String password,
      ) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final exito = await _authRepository.register(
      nombre,
      email,
      password,
    );

    isLoading = false;

    if (!exito) {
      errorMessage = 'No se pudo registrar el usuario';
    }

    notifyListeners();

    return exito;
  }

  Future<void> logout() async {
    await _authRepository.logout();
    errorMessage = null;
    notifyListeners();
  }

  void limpiarError() {
    errorMessage = null;
    notifyListeners();
  }
}