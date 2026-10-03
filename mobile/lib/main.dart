import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'repositories/auth_repository.dart';
import 'repositories/user_repository.dart';
import 'repositories/upload_repository.dart';
import 'viewmodels/auth_viewmodel.dart';
import 'viewmodels/user_viewmodel.dart';
import 'viewmodels/upload_viewmodel.dart';
import 'views/login_view.dart';

void main() {
  final apiService = ApiService();
  final authRepository = AuthRepository(apiService);
  final userRepository = UserRepository(apiService);
  final uploadRepository = UploadRepository(apiService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthViewModel(authRepository)),
        ChangeNotifierProvider(create: (_) => UserViewModel(userRepository, uploadRepository)),
        ChangeNotifierProvider(create: (_) => UploadViewModel(uploadRepository)),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Usuarios App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LoginView(),
      debugShowCheckedModeBanner: false,
    );
  }
}