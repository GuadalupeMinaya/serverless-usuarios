import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../viewmodels/notification_viewmodel.dart';

class NotificationView extends StatefulWidget {
  const NotificationView({super.key});

  @override
  State<NotificationView> createState() => _NotificationViewState();
}

class _NotificationViewState extends State<NotificationView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _asuntoController = TextEditingController();
  final _mensajeController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _asuntoController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    if (!_formKey.currentState!.validate()) return;

    final ok = await context.read<NotificationViewModel>().enviar(
      email: _emailController.text.trim(),
      asunto: _asuntoController.text.trim(),
      mensaje: _mensajeController.text.trim(),
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Mensaje enviado correctamente.' : 'Error al enviar mensaje.',
        ),
        backgroundColor: ok ? Colors.green : Colors.red,
      ),
    );

    if (ok) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSending = context.watch<NotificationViewModel>().isSending;

    return Scaffold(
      appBar: AppBar(title: const Text('Enviar correo')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Correo destino',
                  prefixIcon: Icon(Icons.mail_outline),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  final texto = value?.trim() ?? '';
                  if (texto.isEmpty) return 'Ingresa el correo destino';
                  final valido = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!valido.hasMatch(texto)) return 'Correo no válido';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _asuntoController,
                textInputAction: TextInputAction.next,
                maxLength: 200,
                decoration: const InputDecoration(
                  labelText: 'Asunto',
                  prefixIcon: Icon(Icons.subject),
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Ingresa el asunto'
                    : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _mensajeController,
                maxLines: 6,
                maxLength: 5000,
                decoration: const InputDecoration(
                  labelText: 'Mensaje',
                  alignLabelWithHint: true,
                  border: OutlineInputBorder(),
                ),
                validator: (value) => (value == null || value.trim().isEmpty)
                    ? 'Ingresa el mensaje'
                    : null,
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: isSending ? null : _enviar,
                  icon: isSending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.send),
                  label: Text(isSending ? 'Enviando...' : 'Enviar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
