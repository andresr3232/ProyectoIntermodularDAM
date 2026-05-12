import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/provincias.dart';
import '../services/auth_service.dart';

class PantallaEditarPerfil extends StatefulWidget {
  final Map<String, dynamic> userData;
  final String? usuarioId;

  const PantallaEditarPerfil({super.key, required this.userData, this.usuarioId});

  @override
  State<PantallaEditarPerfil> createState() => _PantallaEditarPerfilState();
}

class _PantallaEditarPerfilState extends State<PantallaEditarPerfil> {
  final _formKey = GlobalKey<FormState>();
  final AuthService _authService = AuthService();

  late TextEditingController _nombreController;
  late TextEditingController _apellido1Controller;
  late TextEditingController _apellido2Controller;
  late TextEditingController _nombreUsuarioController;
  late TextEditingController _descripcionController;
  late TextEditingController _passwordController;
  late TextEditingController _confirmarPasswordController;
  String? _provinciaSeleccionada;

  bool _cargando = false;

  @override
  void initState() {
    super.initState();
    _nombreController = TextEditingController(text: widget.userData['nombre'] ?? '');
    _apellido1Controller = TextEditingController(text: widget.userData['apellido1'] ?? '');
    _apellido2Controller = TextEditingController(text: widget.userData['apellido2'] ?? '');
    _nombreUsuarioController = TextEditingController(text: widget.userData['nombreUsuario'] ?? '');
    _descripcionController = TextEditingController(text: widget.userData['descripcion'] ?? '');
    _passwordController = TextEditingController();
    _confirmarPasswordController = TextEditingController();
    _provinciaSeleccionada = widget.userData['ubicacion'];
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellido1Controller.dispose();
    _apellido2Controller.dispose();
    _nombreUsuarioController.dispose();
    _descripcionController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _cargando = true);

    try {
      final user = _authService.currentUser;
      if (user == null) return;

      final targetUid = widget.usuarioId ?? user.uid;

      // Actualizar datos en Firestore
      await FirebaseFirestore.instance
          .collection('Usuarios')
          .doc(targetUid)
          .update({
        'nombre': _nombreController.text.trim(),
        'apellido1': _apellido1Controller.text.trim(),
        'apellido2': _apellido2Controller.text.trim().isEmpty
            ? null
            : _apellido2Controller.text.trim(),
        'nombreUsuario': _nombreUsuarioController.text.trim(),
        'descripcion': _descripcionController.text.trim(),
        'ubicacion': _provinciaSeleccionada,
      });

      // Actualizar contraseña si se ha introducido y se edita el propio perfil
      if ((widget.usuarioId == null || widget.usuarioId == user.uid) && _passwordController.text.isNotEmpty) {
        await user.updatePassword(_passwordController.text);
      } else if (widget.usuarioId != null && widget.usuarioId != user.uid && _passwordController.text.isNotEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No puedes cambiar la contraseña de otro usuario.')));
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Perfil actualizado correctamente.')),
        );
        Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al actualizar contraseña: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar cambios: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Editar perfil', style: TextStyle(color: Colors.black)),
        actions: [
          _cargando
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              : TextButton(
                  onPressed: _guardarCambios,
                  child: const Text(
                    'Guardar',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _seccion('Información personal'),
              const SizedBox(height: 12),

              TextFormField(
                controller: _nombreController,
                decoration: _inputDecoration('Nombre'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Introduce tu nombre' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _apellido1Controller,
                decoration: _inputDecoration('Primer apellido'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Introduce el primer apellido' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _apellido2Controller,
                decoration: _inputDecoration('Segundo apellido (opcional)'),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nombreUsuarioController,
                decoration: _inputDecoration('Nombre de usuario'),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Introduce un nombre de usuario' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<String>(
                value: _provinciaSeleccionada,
                decoration: _inputDecoration('Provincia'),
                items: Provincias.provincias
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (value) => setState(() => _provinciaSeleccionada = value),
                validator: (value) =>
                    value == null ? 'Selecciona una provincia' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descripcionController,
                maxLines: 4,
                decoration: _inputDecoration('Descripción'),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Introduce una descripción';
                  if (value.length < 10) return 'La descripción es demasiado corta';
                  return null;
                },
              ),

              const SizedBox(height: 32),
              _seccion('Cambiar contraseña'),
              const SizedBox(height: 4),
              const Text(
                'Deja estos campos vacíos si no quieres cambiarla',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _passwordController,
                obscureText: true,
                decoration: _inputDecoration('Nueva contraseña'),
                validator: (value) {
                  if (value != null && value.isNotEmpty && value.length < 6) {
                    return 'Mínimo 6 caracteres';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmarPasswordController,
                obscureText: true,
                decoration: _inputDecoration('Confirmar nueva contraseña'),
                validator: (value) {
                  if (_passwordController.text.isNotEmpty &&
                      value != _passwordController.text) {
                    return 'Las contraseñas no coinciden';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _seccion(String titulo) {
    return Text(
      titulo,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    );
  }
}