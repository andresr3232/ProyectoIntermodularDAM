import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../models/servicio.dart';
import '../services/servicio_service.dart';
import 'pantalla_detalle_servicio.dart';

class PantallaResultadosBusqueda extends StatefulWidget {
  final String categoria;

  const PantallaResultadosBusqueda({super.key, required this.categoria});

  @override
  State<PantallaResultadosBusqueda> createState() => _PantallaResultadosBusquedaState();
}

class _PantallaResultadosBusquedaState extends State<PantallaResultadosBusqueda> {
  final ServicioService _servicioService = ServicioService();
  final Map<String, Map<String, dynamic>> _usuariosCache = {};
  final Map<String, bool> _usuariosConPromocionCache = {};

  Future<Map<String, dynamic>> _getUsuarioCached(String uid) async {
    if (_usuariosCache.containsKey(uid)) {
      return _usuariosCache[uid]!;
    }
    final usuario = await _servicioService.getUsuarioById(uid);
    _usuariosCache[uid] = usuario ?? {};
    return _usuariosCache[uid]!;
  }

  Future<List<Servicio>> _ordenarServiciosPorPromocionActiva(List<Servicio> servicios) async {
    final serviciosConEstadoPromocion = await Future.wait(servicios.map((servicio) async {
      final tienePromocion = _usuariosConPromocionCache[servicio.usuarioId] ??
          await _servicioService.usuarioTienePromocionActiva(servicio.usuarioId);
      _usuariosConPromocionCache[servicio.usuarioId] = tienePromocion;
      return {
        'servicio': servicio,
        'tienePromocion': tienePromocion,
      };
    }));

    serviciosConEstadoPromocion.sort((a, b) {
      final promoA = a['tienePromocion'] as bool;
      final promoB = b['tienePromocion'] as bool;
      if (promoA != promoB) return promoA ? -1 : 1;

      final sA = a['servicio'] as Servicio;
      final sB = b['servicio'] as Servicio;
      return sB.fechaPublicacion.compareTo(sA.fechaPublicacion);
    });

    return serviciosConEstadoPromocion
        .map((e) => e['servicio'] as Servicio)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Servicios - ${widget.categoria}")),
      body: StreamBuilder<List<Servicio>>(
        stream: _servicioService.getServiciosPorCategoria(widget.categoria),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text("No hay servicios disponibles en esta categoría"),
            );
          }

          final servicios = snapshot.data!;

          return FutureBuilder<List<Servicio>>(
            future: _ordenarServiciosPorPromocionActiva(servicios),
            builder: (context, sortedSnapshot) {
              if (sortedSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!sortedSnapshot.hasData || sortedSnapshot.data!.isEmpty) {
                return const Center(
                  child: Text("No hay servicios disponibles en esta categoría"),
                );
              }

              final serviciosOrdenados = sortedSnapshot.data!;

              return ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: serviciosOrdenados.length,
                itemBuilder: (context, index) {
                  final servicio = serviciosOrdenados[index];

                  return FutureBuilder<Map<String, dynamic>>(
                    future: _getUsuarioCached(servicio.usuarioId),
                    builder: (context, snapshotUsuario) {
                      if (!snapshotUsuario.hasData) {
                        return const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        );
                      }

                      final usuario = snapshotUsuario.data!;
                      final nombreUsuario = usuario['nombreUsuario'] ?? 'Usuario';
                      final fotoUrl = usuario['fotoPerfil'];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 3,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(14),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => PantallaDetalleServicio(servicio: servicio),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(14),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Builder(
                                      builder: (context) {
                                        final activoPromocion = _usuariosConPromocionCache[servicio.usuarioId] == true;
                                        return Container(
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: activoPromocion
                                                ? const LinearGradient(
                                                    colors: [Colors.red, Colors.redAccent],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  )
                                                : null,
                                            color: activoPromocion ? null : Colors.transparent,
                                          ),
                                          child: CircleAvatar(
                                            radius: 22,
                                            backgroundColor: activoPromocion
                                                ? Colors.white
                                                : Colors.grey[300],
                                            backgroundImage: fotoUrl != null ? NetworkImage(fotoUrl) : null,
                                            child: fotoUrl == null
                                                ? Text(
                                                    nombreUsuario.isNotEmpty ? nombreUsuario[0].toUpperCase() : "?",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: activoPromocion ? Colors.redAccent.shade700 : Colors.black,
                                                    ),
                                                  )
                                                : null,
                                          ),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "@$nombreUsuario",
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          Text(
                                            "Publicado el: ${servicio.fechaPublicacion.toString().split(' ')[0]}",
                                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (servicio.usuarioId == FirebaseAuth.instance.currentUser?.uid)
                                      const Text(
                                        "Tu servicio",
                                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  servicio.titulo,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}