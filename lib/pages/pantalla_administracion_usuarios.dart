import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../services/auth_service.dart';
import '../widgets/bottom_bar.dart';
import 'pantalla_detalle_usuario.dart';

class PantallaAdministracionUsuarios extends StatefulWidget {
  const PantallaAdministracionUsuarios({super.key});

  @override
  _PantallaAdministracionUsuariosState createState() =>
      _PantallaAdministracionUsuariosState();
}

class _PantallaAdministracionUsuariosState
    extends State<PantallaAdministracionUsuarios> {
  final AuthService _authService = AuthService();
  final TextEditingController _busquedaController = TextEditingController();
  Timer? _debounceTimer;

  late Future<bool> _isAdminFuture;
  late Stream<QuerySnapshot<Map<String, dynamic>>> _usuariosStream;

  String _filtro = '';
  String _filtroAplicado = '';

  @override
  void initState() {
    super.initState();
    _isAdminFuture = _authService.isAdmin();
    _usuariosStream = FirebaseFirestore.instance.collection('Usuarios').snapshots();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _busquedaController.dispose();
    super.dispose();
  }

  String _toLowerSafe(String? value) => value?.toLowerCase() ?? '';

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isAdminFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError || !(snapshot.data ?? false)) {
          return Scaffold(
            appBar: AppBar(
              title: const Text('Administración de usuarios'),
              backgroundColor: Colors.redAccent,
            ),
            body: const Center(
              child: Text(
                'Acceso denegado. Solo administradores pueden ver esta página.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            ),
            bottomNavigationBar: const AppBottomBar(currentIndex: 5),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Administración de usuarios'),
            backgroundColor: Colors.redAccent,
            elevation: 2,
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _busquedaController,
                  onChanged: (value) {
                    _filtro = value.trim();
                    _debounceTimer?.cancel();
                    _debounceTimer = Timer(const Duration(seconds: 1), () {
                      if (!mounted) return;
                      setState(() {
                        _filtroAplicado = _filtro;
                      });
                    });
                  },
                  onSubmitted: (value) {
                    _debounceTimer?.cancel();
                    setState(() {
                      _filtro = value.trim();
                      _filtroAplicado = value.trim();
                    });
                  },
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Buscar usuarios',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    suffixIcon: _filtro.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _busquedaController.clear();
                              _debounceTimer?.cancel();
                              setState(() {
                                _filtro = '';
                                _filtroAplicado = '';
                              });
                            },
                          )
                        : null,
                  ),
                ),
              ),
              Expanded(
                child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                  stream: _usuariosStream,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Center(
                        child: Text('No hay usuarios registrados.'),
                      );
                    }

                    final usuarios = snapshot.data!.docs
                        .map((doc) => Usuario.fromMap({...doc.data(), 'id': doc.id}))
                        .toList();

                    final query = _toLowerSafe(_filtroAplicado);

                    final usuariosFiltrados = usuarios.where((usuario) {
                      if (query.isEmpty) return true;
                      return _toLowerSafe(usuario.nombreUsuario).contains(query) ||
                          _toLowerSafe(usuario.nombre).contains(query) ||
                          _toLowerSafe(usuario.apellido1).contains(query) ||
                          _toLowerSafe(usuario.apellido2).contains(query);
                    }).toList();

                    if (query.isNotEmpty && usuariosFiltrados.isEmpty) {
                      return const Center(
                        child: Text(
                          'No se encontraron usuarios con ese criterio.',
                        ),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: usuariosFiltrados.length,
                      itemBuilder: (context, index) {
                        final usuario = usuariosFiltrados[index];
                        return Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          elevation: 2,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            leading: CircleAvatar(
                              backgroundColor: Colors.redAccent[100],
                              child: Text(
                                usuario.nombreUsuario.isNotEmpty
                                    ? usuario.nombreUsuario[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text('${usuario.nombre} ${usuario.apellido1}'),
                            subtitle: Row(
                              children: [
                                Text(usuario.nombreUsuario),
                                const SizedBox(width: 8),
                                Chip(
                                  label: Text(usuario.rol),
                                  backgroundColor: Colors.redAccent[100],
                                  labelStyle: const TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PantallaDetalleUsuario(usuarioId: usuario.id),
                                ),
                              );
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
          bottomNavigationBar: const AppBottomBar(currentIndex: 5),
        );
      },
    );
  }
}