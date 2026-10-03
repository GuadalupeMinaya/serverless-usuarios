import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../models/user.dart';
import '../viewmodels/upload_viewmodel.dart';
import '../viewmodels/user_viewmodel.dart';

class UserFormView extends StatefulWidget {
  final User? usuario;

  const UserFormView({
    super.key,
    required this.usuario,
  });

  @override
  State<UserFormView> createState() => _UserFormViewState();
}

class _UserFormViewState extends State<UserFormView> {
  late final TextEditingController _nombreController;
  late final TextEditingController _emailController;
  late final TextEditingController _passwordController;

  File? _fotoSeleccionada;

  bool _guardando = false;
  bool _obscurePassword = true;

  bool get esEdicion => widget.usuario != null;

  @override
  void initState() {
    super.initState();

    _nombreController = TextEditingController(
      text: widget.usuario?.nombre ?? '',
    );

    _emailController = TextEditingController(
      text: widget.usuario?.email ?? '',
    );

    _passwordController = TextEditingController();
  }

  Future<void> _elegirFoto() async {
    final picker = ImagePicker();

    final imagen = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (imagen != null) {
      setState(() {
        _fotoSeleccionada = File(imagen.path);
      });
    }
  }

  Future<void> _guardar() async {
    final nombre = _nombreController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (nombre.isEmpty || email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa los campos obligatorios.',
          ),
        ),
      );
      return;
    }

    if (!esEdicion && password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La contraseña es obligatoria.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _guardando = true;
    });

    final userViewModel =
    context.read<UserViewModel>();

    String? fotoUrl;

    if (_fotoSeleccionada != null) {
      final uploadViewModel =
      context.read<UploadViewModel>();

      final subioOk = await uploadViewModel.subir(
        _fotoSeleccionada!.path,
      );

      if (!subioOk) {
        if (mounted) {
          setState(() {
            _guardando = false;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'No se pudo subir la imagen.',
              ),
            ),
          );
        }

        return;
      }

      fotoUrl = uploadViewModel.urlSubida;
    }

    bool exito;

    if (esEdicion) {
      exito = await userViewModel.actualizarUsuario(
        widget.usuario!.id!,
        nombre,
        email,
        password.isEmpty ? null : password,
        fotoUrl: fotoUrl,
      );
    } else {
      exito = await userViewModel.crearUsuario(
        nombre,
        email,
        password,
        fotoUrl: fotoUrl,
      );
    }

    if (!mounted) return;

    setState(() {
      _guardando = false;
    });

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            esEdicion
                ? 'Usuario actualizado correctamente'
                : 'Usuario creado correctamente',
          ),
        ),
      );

      Navigator.of(context).pop();
    }
  }

  Widget _buildPreview() {
    if (_fotoSeleccionada != null) {
      return CircleAvatar(
        radius: 50,
        backgroundImage:
        FileImage(_fotoSeleccionada!),
      );
    }

    return CircleAvatar(
      radius: 50,
      backgroundColor: Colors.blue.shade50,
      child: Icon(
        esEdicion
            ? Icons.person_outline
            : Icons.person_add_alt_1,
        size: 50,
        color: Colors.blue.shade700,
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uploadViewModel =
    context.watch<UploadViewModel>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          esEdicion
              ? 'Editar usuario'
              : 'Nuevo usuario',
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints:
              const BoxConstraints(maxWidth: 450),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  _buildPreview(),

                  const SizedBox(height: 10),

                  TextButton.icon(
                    onPressed:
                    _guardando ? null : _elegirFoto,
                    icon: const Icon(
                      Icons.image_outlined,
                    ),
                    label: const Text(
                      'Seleccionar imagen',
                    ),
                  ),

                  const SizedBox(height: 24),

                  TextField(
                    controller: _nombreController,
                    decoration: InputDecoration(
                      labelText: 'Nombre',
                      prefixIcon:
                      const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: _emailController,
                    keyboardType:
                    TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText:
                      'Correo electrónico',
                      prefixIcon:
                      const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller:
                    _passwordController,
                    obscureText:
                    _obscurePassword,
                    decoration: InputDecoration(
                      labelText: esEdicion
                          ? 'Nueva contraseña (opcional)'
                          : 'Contraseña',
                      prefixIcon:
                      const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: () {
                          setState(() {
                            _obscurePassword =
                            !_obscurePassword;
                          });
                        },
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(12),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  if (_guardando) ...[
                    const LinearProgressIndicator(),
                    const SizedBox(height: 10),
                    Text(
                      uploadViewModel.isUploading
                          ? 'Subiendo imagen...'
                          : 'Guardando...',
                    ),
                    const SizedBox(height: 16),
                  ],

                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed:
                      _guardando ? null : _guardar,
                      icon:
                      const Icon(Icons.save_outlined),
                      label: Text(
                        esEdicion
                            ? 'Guardar cambios'
                            : 'Crear usuario',
                      ),
                      style:
                      ElevatedButton.styleFrom(
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}