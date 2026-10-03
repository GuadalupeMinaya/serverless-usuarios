import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../viewmodels/upload_viewmodel.dart';

class UploadView extends StatefulWidget {
  const UploadView({super.key});

  @override
  State<UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<UploadView> {
  File? _archivoSeleccionado;

  @override
  void initState() {
    super.initState();
    // Al entrar a la pantalla, borramos el resultado de la subida anterior
    Future.microtask(() {
      final vm = context.read<UploadViewModel>();
      vm.urlSubida = null;
      vm.errorMessage = null;
    });
  }
  
  Future<void> _elegirImagen() async {
    final picker = ImagePicker();
    final imagen = await picker.pickImage(source: ImageSource.gallery);
    if (imagen != null) {
      setState(() {
        _archivoSeleccionado = File(imagen.path);
      });
    }
  }

  Future<void> _subir() async {
    if (_archivoSeleccionado == null) return;
    final uploadViewModel = context.read<UploadViewModel>();
    await uploadViewModel.subir(_archivoSeleccionado!.path);
  }

  @override
  Widget build(BuildContext context) {
    final uploadViewModel = context.watch<UploadViewModel>();

    return Scaffold(
      appBar: AppBar(title: const Text('Subir archivo')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // --- Preview de la imagen elegida ---
            if (_archivoSeleccionado != null)
              Image.file(_archivoSeleccionado!, height: 200)
            else
              Container(
                height: 200,
                color: Colors.grey[300],
                child: const Center(child: Text('Sin imagen seleccionada')),
              ),
            const SizedBox(height: 16),

            ElevatedButton(
              onPressed: _elegirImagen,
              child: const Text('Elegir imagen'),
            ),
            const SizedBox(height: 16),

            // --- Barra de progreso, solo visible mientras sube ---
            if (uploadViewModel.isUploading) ...[
              LinearProgressIndicator(value: uploadViewModel.progreso),
              const SizedBox(height: 8),
              Text('${(uploadViewModel.progreso * 100).toStringAsFixed(0)}%'),
              const SizedBox(height: 16),
            ],

            if (uploadViewModel.errorMessage != null)
              Text(
                uploadViewModel.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),

            if (uploadViewModel.urlSubida != null)
              const Text(
                '¡Archivo subido con éxito!',
                style: TextStyle(color: Colors.green),
              ),

            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _archivoSeleccionado == null || uploadViewModel.isUploading
                  ? null
                  : _subir,
              child: const Text('Subir'),
            ),
          ],
        ),
      ),
    );
  }
}