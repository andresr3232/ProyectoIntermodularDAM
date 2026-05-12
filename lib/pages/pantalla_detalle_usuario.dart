import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/usuario.dart';
import '../models/servicio.dart';
import '../models/intercambio.dart';
import '../models/valoracion.dart';
import '../pages/pantalla_chat.dart';
import '../pages/pantalla_editar_perfil.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';
import '../services/servicio_service.dart';

class PantallaDetalleUsuario extends StatefulWidget {
  final String usuarioId;

  const PantallaDetalleUsuario({super.key, required this.usuarioId});

  @override
  _PantallaDetalleUsuarioState createState() => _PantallaDetalleUsuarioState();
}

class _PantallaDetalleUsuarioState extends State<PantallaDetalleUsuario> {
  late final DocumentReference<Map<String, dynamic>> _usuarioRef;
  final ServicioService _servicioService = ServicioService();
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    _usuarioRef = FirebaseFirestore.instance.collection('Usuarios').doc(widget.usuarioId);
  }

  Future<List<Intercambio>> _obtenerIntercambiosUsuario(String usuarioId) async {
    final intercambiosOfertanteSnapshot = await FirebaseFirestore.instance
        .collection('Intercambios')
        .where('usuarioIdOfertante', isEqualTo: usuarioId)
        .get();

    final intercambiosDemandanteSnapshot = await FirebaseFirestore.instance
        .collection('Intercambios')
        .where('usuarioIdDemandante', isEqualTo: usuarioId)
        .get();

    final intercambios = <Intercambio>[];
    for (final doc in intercambiosOfertanteSnapshot.docs) {
      intercambios.add(Intercambio.fromMap({...doc.data(), 'id': doc.id}));
    }
    for (final doc in intercambiosDemandanteSnapshot.docs) {
      intercambios.add(Intercambio.fromMap({...doc.data(), 'id': doc.id}));
    }
    return intercambios;
  }

  Future<List<Valoracion>> _obtenerValoracionesUsuario(String usuarioId) async {
    final valoracionesSnapshot = await FirebaseFirestore.instance
        .collection('Valoraciones')
        .where('usuarioIdReceptor', isEqualTo: usuarioId)
        .get();

    return valoracionesSnapshot.docs.map((doc) => Valoracion.fromMap({...doc.data(), 'id': doc.id})).toList();
  }

  Future<void> _toggleEstadoServiciosUsuario(String usuarioId) async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('Servicios')
          .where('usuarioId', isEqualTo: usuarioId)
          .get();

      if (snapshot.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este usuario no tiene servicios creados.')));
        return;
      }

      final tieneActivados = snapshot.docs.any((doc) => (doc.data()['activo'] as bool?) == true);
      final nuevoEstado = !tieneActivados;

      final batch = FirebaseFirestore.instance.batch();
      for (final servicioDoc in snapshot.docs) {
        batch.update(servicioDoc.reference, {'activo': nuevoEstado});
      }
      await batch.commit();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(nuevoEstado ? 'Todos los servicios han sido activados.' : 'Todos los servicios han sido desactivados.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error al cambiar estado de servicios: $e')));
    }
  }

  Future<void> _enviarMensaje(String usuarioId) async {
    final currentUser = _authService.currentUser;
    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Debes iniciar sesión para enviar mensajes.')));
      return;
    }

    if (currentUser.uid == usuarioId) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No puedes enviarte un mensaje a ti mismo.')));
      return;
    }

    final chatId = await _chatService.crearChatSiNoExiste(currentUser.uid, usuarioId);

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaChat(chatId: chatId)));
  }

  void _editarUsuario(Map<String, dynamic> usuarioData, String usuarioId) {
    Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => PantallaEditarPerfil(
          userData: usuarioData,
          usuarioId: usuarioId,
        ),
      ),
    ).then((actualizado) {
      if (actualizado == true && mounted) {
        // Volver a cargar datos tras editar y guardar
        setState(() {});
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalle de usuario'),
        backgroundColor: Colors.redAccent,
      ),
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _usuarioRef.get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Error al cargar usuario.', style: TextStyle(color: Colors.redAccent)),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () => setState(() {}),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Usuario no encontrado.'));
          }

          final data = snapshot.data!.data()!;
          final usuario = Usuario.fromMap({...data, 'id': snapshot.data!.id});
          final nombreCompleto = '${usuario.nombre} ${usuario.apellido1}${usuario.apellido2 != null && usuario.apellido2!.isNotEmpty ? ' ${usuario.apellido2}' : ''}';

          Widget buildChipList(String title, List<String> items, Color color) {
            if (items.isEmpty) {
              return Text('Ninguno', style: TextStyle(color: Colors.grey[600]));
            }
            return Wrap(
              spacing: 6,
              runSpacing: 6,
              children: items.map((item) => Chip(label: Text(item), backgroundColor: color.withOpacity(0.14), labelStyle: TextStyle(color: color))).toList(),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.redAccent,
                        child: Text(
                          usuario.nombreUsuario.isNotEmpty ? usuario.nombreUsuario[0].toUpperCase() : 'U',
                          style: const TextStyle(fontSize: 24, color: Colors.white),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(usuario.nombreUsuario, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text('Rol: ${usuario.rol}', style: const TextStyle(fontSize: 14, color: Colors.black54)),
                          ],
                        ),
                      ),
                      Chip(
                        label: Text(usuario.totalValoraciones > 0 ? '⭐ ${usuario.mediaValoraciones.toStringAsFixed(1)}' : 'Sin valoraciones'),
                        backgroundColor: Colors.yellow[100],
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Información básica', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const Divider(),
                          ListTile(title: const Text('Nombre completo'), subtitle: Text(nombreCompleto)),
                          ListTile(title: const Text('Email'), subtitle: Text(usuario.email.isNotEmpty ? usuario.email : 'No proporcionado')),
                          ListTile(title: const Text('Ubicación'), subtitle: Text(usuario.ubicacion.isNotEmpty ? usuario.ubicacion : 'No especificada')),
                          ListTile(title: const Text('ID'), subtitle: Text(usuario.id)),
                          ListTile(title: const Text('Registro'), subtitle: Text(usuario.fechaRegistro.toLocal().toString().split(' ')[0])),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Servicios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const Divider(),
                          const Text('Ofrece', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          buildChipList('Ofrece', usuario.serviciosOfrece, Colors.green),
                          const SizedBox(height: 12),
                          const Text('Busca', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 6),
                          buildChipList('Busca', usuario.serviciosBusca, Colors.blue),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Descripción', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const Divider(),
                          Text(usuario.descripcion.isNotEmpty ? usuario.descripcion : 'Sin descripción disponible.', style: const TextStyle(fontSize: 14, color: Colors.black87)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Servicios creados', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const Divider(),
                          StreamBuilder<List<Servicio>>(
                            stream: _servicioService.getServiciosUsuarioByDocId(usuario.id),
                            builder: (context, serviciosSnapshot) {
                              if (serviciosSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (serviciosSnapshot.hasError) {
                                return const Text('Error cargando servicios creados.', style: TextStyle(color: Colors.redAccent));
                              }

                              final servicios = serviciosSnapshot.data ?? [];
                              if (servicios.isEmpty) {
                                return const Text('No hay servicios creados por este usuario.');
                              }

                              return Column(
                                children: servicios.map((servicio) {
                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(servicio.titulo, style: const TextStyle(fontWeight: FontWeight.w600)),
                                    subtitle: Text(servicio.descripcion),
                                    trailing: Chip(
                                      label: Text(servicio.activo ? 'Activo' : 'Inactivo'),
                                      backgroundColor: servicio.activo ? Colors.green[100] : Colors.grey[300],
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Intercambios', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const Divider(),
                          FutureBuilder<List<Intercambio>>(
                            future: _obtenerIntercambiosUsuario(usuario.id),
                            builder: (context, intercambiosSnapshot) {
                              if (intercambiosSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (intercambiosSnapshot.hasError) {
                                return const Text('Error cargando intercambios.', style: TextStyle(color: Colors.redAccent));
                              }

                              final intercambios = intercambiosSnapshot.data ?? [];
                              if (intercambios.isEmpty) {
                                return const Text('No hay intercambios realizados por este usuario.');
                              }

                              return Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: intercambios.map((intercambio) {
                                  Color cardColor;
                                  String estadoTexto;
                                  IconData icono;

                                  switch (intercambio.estado) {
                                    case 'aceptado':
                                      cardColor = Colors.green[100]!;
                                      estadoTexto = 'Aceptado';
                                      icono = Icons.check_circle;
                                      break;
                                    case 'rechazado':
                                      cardColor = Colors.red[100]!;
                                      estadoTexto = 'Rechazado';
                                      icono = Icons.cancel;
                                      break;
                                    case 'pendiente':
                                      cardColor = Colors.yellow[100]!;
                                      estadoTexto = 'Pendiente';
                                      icono = Icons.hourglass_empty;
                                      break;
                                    default:
                                      cardColor = Colors.grey[100]!;
                                      estadoTexto = intercambio.estado;
                                      icono = Icons.help;
                                  }

                                  return Card(
                                    color: cardColor,
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Icon(icono, size: 16, color: cardColor == Colors.green[100] ? Colors.green[700] : cardColor == Colors.red[100] ? Colors.red[700] : Colors.orange[700]),
                                              const SizedBox(width: 4),
                                              Text(estadoTexto, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: cardColor == Colors.green[100] ? Colors.green[700] : cardColor == Colors.red[100] ? Colors.red[700] : Colors.orange[700])),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Text('Fecha: ${intercambio.fechaSolicitud.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 10)),
                                          if (intercambio.fechaAceptacion != null)
                                            Text('Aceptado: ${intercambio.fechaAceptacion!.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 10)),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Valoraciones recibidas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                          const Divider(),
                          FutureBuilder<List<Valoracion>>(
                            future: _obtenerValoracionesUsuario(usuario.id),
                            builder: (context, valoracionesSnapshot) {
                              if (valoracionesSnapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              if (valoracionesSnapshot.hasError) {
                                return const Text('Error cargando valoraciones.', style: TextStyle(color: Colors.redAccent));
                              }

                              final valoraciones = valoracionesSnapshot.data ?? [];
                              if (valoraciones.isEmpty) {
                                return const Text('No hay valoraciones recibidas por este usuario.');
                              }

                              return Column(
                                children: valoraciones.map((valoracion) {
                                  return Card(
                                    elevation: 1,
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    child: Padding(
                                      padding: const EdgeInsets.all(12.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              ...List.generate(5, (index) => Icon(
                                                index < valoracion.puntuacion ? Icons.star : Icons.star_border,
                                                color: Colors.amber,
                                                size: 16,
                                              )),
                                              const SizedBox(width: 8),
                                              Text('${valoracion.puntuacion}/5', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          if (valoracion.comentario != null && valoracion.comentario!.isNotEmpty)
                                            Text('"${valoracion.comentario}"', style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic)),
                                          const SizedBox(height: 4),
                                          Text('Fecha: ${valoracion.fecha.toLocal().toString().split(' ')[0]}', style: const TextStyle(fontSize: 12)),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _toggleEstadoServiciosUsuario(usuario.id),
                        icon: const Icon(Icons.block),
                        label: const Text('Bloquear/Activar servicios'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _enviarMensaje(usuario.id),
                        icon: const Icon(Icons.message),
                        label: const Text('Enviar mensaje'),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _editarUsuario(data, usuario.id),
                        icon: const Icon(Icons.edit),
                        label: const Text('Editar'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
