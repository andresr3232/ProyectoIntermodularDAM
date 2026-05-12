import 'package:flutter/material.dart';
import '../widgets/bottom_bar.dart';
import '../services/auth_service.dart';
import '../models/categorias.dart';
import '../models/servicio.dart';
import '../models/promocion.dart';
import '../services/chat_service.dart';
import '../services/servicio_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'pantalla_chat.dart';
import 'pantalla_editar_perfil.dart';

class PantallaPerfil extends StatefulWidget {
  final String? usuarioId;

  const PantallaPerfil({super.key, this.usuarioId});

  @override
  State<PantallaPerfil> createState() => _PantallaPerfilState();
}

class _PantallaPerfilState extends State<PantallaPerfil> {
  int _indexActual = 3; // Perfil
  final AuthService _authService = AuthService();
  final ServicioService _servicioService = ServicioService();
  final ChatService _chatService = ChatService();

  bool get esMiPerfil {
    final current = _authService.currentUser?.uid;
    return widget.usuarioId == null || widget.usuarioId == current;
  }

  Future<Promocion?> _obtenerPromocionActiva(String usuarioId) async {
    final ahora = DateTime.now();

    final snapshot = await FirebaseFirestore.instance
        .collection('Promociones')
        .where('usuarioIdEmisor', isEqualTo: usuarioId)
        .where('fechaFin', isGreaterThan: Timestamp.fromDate(ahora))
        .get();

    if (snapshot.docs.isEmpty) return null;

    snapshot.docs.sort((a, b) {
      final fa = (a.data()['fechaFin'] as Timestamp).toDate();
      final fb = (b.data()['fechaFin'] as Timestamp).toDate();
      return fa.compareTo(fb);
    });

    final data = Map<String, dynamic>.from(snapshot.docs.last.data());
    data['id'] = snapshot.docs.last.id;

    return Promocion.fromMap(data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 233, 233, 233),

      // App bar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            Image.asset('assets/logo.png', height: 50),
            const SizedBox(width: 12),
            const Text('Perfil', style: TextStyle(color: Colors.black)),
          ],
        ),
        actions: [
          if (esMiPerfil)
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.black),
              onPressed: () async {
                final profileData = await _authService.getUserProfile();
                if (!mounted) return;
                if (profileData == null) return;

                if (!mounted) return;

                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PantallaEditarPerfil(userData: profileData),
                  ),
                );

                if (result == true && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Perfil actualizado correctamente'),
                    ),
                  );
                }
              },
            ),
        ],
      ),

      // Cuerpo con StreamBuilder para datos en tiempo real
      body: StreamBuilder<Map<String, dynamic>?>(
        stream: esMiPerfil
            ? _authService.getUserProfileStream()
            : _authService.getUserProfileStreamByUid(widget.usuarioId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final userData = snapshot.data;

          if (userData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('No se pudo cargar el perfil del usuario'),
                  const SizedBox(height: 16),
                  Text('UID: ${_authService.currentUser?.uid ?? "sin uid"}'),
                ],
              ),
            );
          }

          final nombre = userData['nombre'] ?? 'N/A';
          final apellido1 = userData['apellido1'] ?? '';
          final apellido2 = userData['apellido2'] ?? '';
          final nombreUsuario = userData['nombreUsuario'] ?? 'N/A';
          final descripcion = userData['descripcion'] ?? 'Sin descripción';
          final serviciosOfrece = List<String>.from(
            userData['serviciosOfrece'] ?? [],
          );
          final serviciosBusca = List<String>.from(
            userData['serviciosBusca'] ?? [],
          );
          final mediaValoraciones =
              (userData['mediaValoraciones'] as num?)?.toDouble() ?? 0.0;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 16),

                FutureBuilder<Promocion?>(
                  future: _obtenerPromocionActiva(widget.usuarioId ?? _authService.currentUser?.uid ?? ''),
                  builder: (context, snapshotPromocion) {
                    final fuerte = snapshotPromocion.hasData && snapshotPromocion.data != null;
                    return Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: fuerte
                            ? const LinearGradient(
                                colors: [Colors.red, Colors.redAccent],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              )
                            : null,
                        color: fuerte ? null : Colors.transparent,
                      ),
                      child: CircleAvatar(
                        radius: 46,
                        backgroundColor: fuerte
                            ? Colors.white
                            : Theme.of(context).colorScheme.primary.withOpacity(0.15),
                        child: Text(
                          nombre.isNotEmpty ? nombre[0].toUpperCase() : "?",
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: fuerte ? Colors.redAccent.shade700 : Theme.of(context).colorScheme.primary,
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 8),

                // Nombre real
                Text(
                  '$nombre $apellido1${apellido2.isNotEmpty ? ' $apellido2' : ''}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 4),

                // Nombre de usuario
                Text(
                  '@$nombreUsuario',
                  style: const TextStyle(fontSize: 14, color: Colors.black),
                ),

                const SizedBox(height: 12),

                Text(
                  'Media de valoraciones: $mediaValoraciones ⭐',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),

                FutureBuilder<Promocion?>(
                  future: _obtenerPromocionActiva(widget.usuarioId ?? _authService.currentUser?.uid ?? ''),
                  builder: (context, snapshotPromocion) {
                    if (snapshotPromocion.connectionState == ConnectionState.waiting) {
                      return const SizedBox();
                    }

                    if (!snapshotPromocion.hasData || snapshotPromocion.data == null) {
                      return const SizedBox();
                    }

                    final promocion = snapshotPromocion.data!;
                    final ahora = DateTime.now();
                    final diasRestantes = promocion.fechaFin.difference(ahora).inDays;
                    final horasRestantes = promocion.fechaFin.difference(ahora).inHours % 24;

                    return Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.redAccent.shade700),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.local_offer, color: Colors.redAccent),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              'Promoción activa: ${promocion.fechaFin.day.toString().padLeft(2, '0')}/${promocion.fechaFin.month.toString().padLeft(2, '0')}/${promocion.fechaFin.year} • $diasRestantes días $horasRestantes horas restantes',
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                const SizedBox(height: 4),

                if (!esMiPerfil)
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red[400],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 12,
                        horizontal: 16,
                      ),
                    ),
                    icon: const Icon(Icons.chat),
                    label: const Text('Enviar mensaje'),
                    onPressed: () async {
                      final currentUser = _authService.currentUser;
                      if (currentUser == null) return;

                      final chatId = await _chatService.crearChatSiNoExiste(
                        currentUser.uid,
                        widget.usuarioId!,
                      );

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PantallaChat(chatId: chatId),
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 24),

                // Descripción
                _tarjeta(
                  titulo: 'Descripción',
                  child: Text(
                    descripcion,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),

                const SizedBox(height: 16),

                // Servicios que ofrece
                _tarjeta(
                  titulo: 'Servicios que ofrezco',
                  child: serviciosOfrece.isEmpty
                      ? const Text('Sin servicios registrados')
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: serviciosOfrece
                              .map(
                                (s) => _ServicioChip(
                                  texto: s,
                                  onDelete: esMiPerfil
                                      ? () async {
                                          await _servicioService
                                              .eliminarServicioOfrece(s);
                                        }
                                      : null,
                                ),
                              )
                              .toList(),
                        ),
                ),

                const SizedBox(height: 5),

                if (esMiPerfil)
                  _botonAgregar(
                    texto: "Añadir servicio que ofrezco",
                    onTap: () {
                      _mostrarDialogoCrearServicio(esOfrecido: true);
                    },
                  ),

                const SizedBox(height: 16),

                // Servicios que busca
                _tarjeta(
                  titulo: 'Servicios que busco',
                  child: serviciosBusca.isEmpty
                      ? const Text('Sin servicios registrados')
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: serviciosBusca
                              .map(
                                (s) => _ServicioChip(
                                  texto: s,
                                  onDelete: esMiPerfil
                                      ? () async {
                                          await _servicioService
                                              .eliminarServicioBusca(s);
                                        }
                                      : null,
                                ),
                              )
                              .toList(),
                        ),
                ),

                const SizedBox(height: 5),

                if (esMiPerfil)
                  _botonAgregar(
                    texto: "Añadir servicio que busco",
                    onTap: () {
                      _mostrarDialogoCrearServicio(esOfrecido: false);
                    },
                  ),

                const SizedBox(height: 40),

                if (esMiPerfil)
                  _botonAgregar(
                    texto: "Publicar nuevo servicio",
                    onTap: () {
                      if (serviciosOfrece.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Primero debes añadir al menos un servicio en 'Servicios que ofrezco'",
                            ),
                          ),
                        );
                        return;
                      }
                      _mostrarDialogoCrearServicioPublicado(serviciosOfrece);
                    },
                    color: const Color.fromARGB(255, 145, 0, 0),
                  ),

                const SizedBox(height: 10),

                if (esMiPerfil) ...[
                  const SizedBox(height: 10),
                  _tarjeta(
                    titulo: "Mis servicios publicados",
                    child: _buildServiciosPublicados(serviciosOfrece),
                  ),
                ],
              ],
            ),
          );
        },
      ),

      // Bottom bar
      bottomNavigationBar: AppBottomBar(currentIndex: _indexActual),
    );
  }

  void _mostrarDialogoCrearServicio({required bool esOfrecido}) {
    String? categoriaSeleccionada;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            esOfrecido
                ? "Selecciona servicio que ofreces"
                : "Selecciona servicio que buscas",
          ),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return DropdownButtonFormField<String>(
                value: categoriaSeleccionada,
                hint: const Text("Selecciona una categoría"),
                items: Categorias.lista
                    .map(
                      (categoria) => DropdownMenuItem(
                        value: categoria,
                        child: Text(categoria),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  setStateDialog(() {
                    categoriaSeleccionada = value;
                  });
                },
                decoration: const InputDecoration(border: OutlineInputBorder()),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (categoriaSeleccionada == null) return;

                if (esOfrecido) {
                  await _servicioService.agregarServicioOfrece(
                    categoriaSeleccionada!,
                  );
                } else {
                  await _servicioService.agregarServicioBusca(
                    categoriaSeleccionada!,
                  );
                }

                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoCrearServicioPublicado(List<String> serviciosOfrece) {
    final tituloController = TextEditingController();
    final descripcionController = TextEditingController();
    String? categoriaSeleccionada;
    bool activo = true;

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Publicar servicio"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(
                        labelText: "Título",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descripcionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Descripción",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: categoriaSeleccionada,
                      hint: const Text("Selecciona categoría"),
                      items: serviciosOfrece
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          categoriaSeleccionada = value;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    SwitchListTile(
                      title: const Text("Servicio activo"),
                      value: activo,
                      onChanged: (value) {
                        setStateDialog(() {
                          activo = value;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final user = _authService.currentUser;
                if (user == null) return;

                if (tituloController.text.isEmpty ||
                    descripcionController.text.isEmpty ||
                    categoriaSeleccionada == null) {
                  return;
                }

                final id = FirebaseFirestore.instance
                    .collection('Servicios')
                    .doc()
                    .id;

                final nuevoServicio = Servicio(
                  id: id,
                  titulo: tituloController.text.trim(),
                  descripcion: descripcionController.text.trim(),
                  categoria: categoriaSeleccionada!,
                  usuarioId: user.uid,
                  fechaPublicacion: DateTime.now(),
                  activo: activo,
                );

                await _servicioService.crearServicio(nuevoServicio);

                Navigator.pop(context);
              },
              child: const Text("Publicar"),
            ),
          ],
        );
      },
    );
  }

  void _mostrarDialogoEditarServicio(
    Servicio servicio,
    List<String> serviciosOfrece,
  ) {
    final tituloController = TextEditingController(text: servicio.titulo);
    final descripcionController = TextEditingController(
      text: servicio.descripcion,
    );
    String categoriaSeleccionada = servicio.categoria;
    bool activo = servicio.activo;

    if (!serviciosOfrece.contains(categoriaSeleccionada)) {
      categoriaSeleccionada = serviciosOfrece.isNotEmpty
          ? serviciosOfrece.first
          : '';
    }

    if (serviciosOfrece.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "No tienes categorías en 'Servicios que ofrezco'. Añade una antes de editar.",
          ),
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Editar servicio"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(
                        labelText: "Título",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descripcionController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Descripción",
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: categoriaSeleccionada,
                      items: serviciosOfrece
                          .map(
                            (cat) =>
                                DropdownMenuItem(value: cat, child: Text(cat)),
                          )
                          .toList(),
                      onChanged: (value) {
                        setStateDialog(() {
                          categoriaSeleccionada = value!;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text("Servicio activo"),
                      value: activo,
                      onChanged: (value) {
                        setStateDialog(() {
                          activo = value;
                        });
                      },
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancelar"),
            ),
            ElevatedButton(
              onPressed: () async {
                final servicioActualizado = Servicio(
                  id: servicio.id,
                  titulo: tituloController.text.trim(),
                  descripcion: descripcionController.text.trim(),
                  categoria: categoriaSeleccionada,
                  usuarioId: servicio.usuarioId,
                  fechaPublicacion: servicio.fechaPublicacion,
                  activo: activo,
                );

                await _servicioService.actualizarServicio(servicioActualizado);

                Navigator.pop(context);
              },
              child: const Text("Guardar"),
            ),
          ],
        );
      },
    );
  }

  // Tarjeta personalizada
  Widget _tarjeta({required String titulo, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _buildServiciosPublicados(List<String> serviciosOfrece) {
    return FutureBuilder<String>(
      future: _authService.getUsuarioDocId(),
      builder: (context, snapshotDocId) {
        if (snapshotDocId.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        }
        if (snapshotDocId.hasError) {
          return Text("Error: ${snapshotDocId.error}");
        }

        final usuarioDocId = snapshotDocId.data!;
        return StreamBuilder<List<Servicio>>(
          stream: _servicioService.getServiciosUsuarioByDocId(usuarioDocId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final servicios = snapshot.data ?? [];

            if (servicios.isEmpty) {
              return const Text("No tienes servicios publicados");
            }

            return Column(
              children: servicios.map((servicio) {
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  child: ListTile(
                    title: Text('${servicio.titulo} | ${servicio.categoria}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(servicio.descripcion),
                        Row(
                          children: [
                            const Text("Activo"),
                            Switch(
                              value: servicio.activo,
                              onChanged: esMiPerfil
                                  ? (value) async {
                                      await _servicioService
                                          .cambiarEstadoServicio(
                                            servicio.id,
                                            value,
                                          );
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ],
                    ),
                    trailing: esMiPerfil
                        ? PopupMenuButton<String>(
                            onSelected: (value) {
                              if (value == 'editar') {
                                _mostrarDialogoEditarServicio(
                                  servicio,
                                  serviciosOfrece,
                                );
                              } else if (value == 'eliminar') {
                                showDialog(
                                  context: context,
                                  builder: (_) => AlertDialog(
                                    title: const Text("Confirmar eliminación"),
                                    content: const Text(
                                      "¿Seguro que deseas eliminar este servicio?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: const Text("Cancelar"),
                                      ),
                                      ElevatedButton(
                                        onPressed: () async {
                                          await _servicioService
                                              .eliminarServicio(servicio.id);
                                          Navigator.pop(context);
                                        },
                                        child: const Text("Eliminar"),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            },
                            itemBuilder: (context) => [
                              const PopupMenuItem(
                                value: 'editar',
                                child: Text('Editar'),
                              ),
                              const PopupMenuItem(
                                value: 'eliminar',
                                child: Text('Eliminar'),
                              ),
                            ],
                          )
                        : null,
                  ),
                );
              }).toList(),
            );
          },
        );
      },
    );
  }
}

// Botón personalizado para agregar servicios
Widget _botonAgregar({
  required String texto,
  required VoidCallback onTap,
  Color color = const Color.fromARGB(255, 255, 0, 0),
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(12),
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.add, color: color),
          const SizedBox(width: 8),
          Text(
            texto,
            style: TextStyle(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    ),
  );
}

// Chip personalizado para mostrar servicios
class _ServicioChip extends StatelessWidget {
  final String texto;
  final VoidCallback? onDelete;

  const _ServicioChip({required this.texto, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(texto),
      backgroundColor: Colors.red[50],
      labelStyle: const TextStyle(
        color: Colors.red,
        fontWeight: FontWeight.w500,
      ),
      deleteIcon: onDelete != null ? const Icon(Icons.close, size: 18) : null,
      onDeleted: onDelete,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: Colors.red),
      ),
    );
  }
}
