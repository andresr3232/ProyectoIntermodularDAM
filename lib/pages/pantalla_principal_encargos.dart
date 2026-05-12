import 'package:flutter/material.dart';
import '../widgets/bottom_bar.dart';
import '../services/auth_service.dart';
import '../services/servicio_service.dart';
import '../models/intercambio.dart';

class PantallaEncargos extends StatefulWidget {
  const PantallaEncargos({super.key});

  @override
  State<PantallaEncargos> createState() => _PantallaEncargosState();
}

class _PantallaEncargosState extends State<PantallaEncargos> {
  int _indexActual = 1; // Encargos
  bool _verEncargosARealizar = true;
  final AuthService authService = AuthService();
  final ServicioService servicioService = ServicioService();

  @override
  Widget build(BuildContext context) {
    final user = authService.currentUser;
    if (user == null) {
      return Scaffold(body: Center(child: Text("Usuario no autenticado")));
    }

    return Scaffold(
      backgroundColor: Colors.grey[300],

      // App bar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            Image.asset('assets/logo.png', height: 45),
            const SizedBox(width: 12),
            const Text('Encargos', style: TextStyle(color: Colors.black)),
          ],
        ),
      ),

      // Cuerpo
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Filtro
            Row(
              children: [
                Expanded(
                  child: _botonFiltro(
                    texto: 'A realizar',
                    seleccionado: _verEncargosARealizar,
                    onTap: () {
                      setState(() {
                        _verEncargosARealizar = true;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _botonFiltro(
                    texto: 'A recibir',
                    seleccionado: !_verEncargosARealizar,
                    onTap: () {
                      setState(() {
                        _verEncargosARealizar = false;
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Lista de encargos
            Expanded(
              child: StreamBuilder<List<Intercambio>>(
                stream: _verEncargosARealizar
                    ? servicioService.getIntercambiosComoOfertante(user.uid)
                    : servicioService.getIntercambiosComoDemandante(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No tienes encargos"));
                  }

                  final intercambios = snapshot.data!;
                  return ListView.builder(
                    itemCount: intercambios.length,
                    itemBuilder: (context, index) {
                      final intercambio = intercambios[index];

                      return FutureBuilder(
                        future: Future.wait([
                          servicioService.getServicioById(
                            intercambio.servicioIdOfertado,
                          ),
                          servicioService.getServicioById(
                            intercambio.servicioIdDemandado,
                          ),
                        ]),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Card(
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Text("Cargando servicios..."),
                              ),
                            );
                          }

                          final servicioOfertado = snapshot.data![0];
                          final servicioDemandado = snapshot.data![1];
                          final bool soyOfertante =
                              intercambio.usuarioIdOfertante == user.uid;
                          final servicioOfrezco = soyOfertante
                              ? servicioOfertado
                              : servicioDemandado;
                          final servicioRecibo = soyOfertante
                              ? servicioDemandado
                              : servicioOfertado;
                          final otroUsuarioId =
                              intercambio.usuarioIdDemandante == user.uid
                              ? intercambio.usuarioIdOfertante
                              : intercambio.usuarioIdDemandante;
                          final bool yaConfirmado = soyOfertante
                              ? intercambio.ofertanteConfirmo
                              : intercambio.demandanteConfirmo;
                          final bool yaValoro = soyOfertante
                              ? intercambio.ofertanteValoro
                              : intercambio.demandanteValoro;

                          return Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Ofreces: ${servicioOfrezco?.titulo ?? "Servicio"}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    "Recibes: ${servicioRecibo?.titulo ?? "Servicio"}",
                                  ),
                                  const SizedBox(height: 4),
                                  StreamBuilder<Map<String, dynamic>?>(
                                    stream: authService
                                        .getUserProfileStreamByUid(
                                          otroUsuarioId,
                                        ),
                                    builder: (context, userSnapshot) {
                                      if (!userSnapshot.hasData) {
                                        return const Text(
                                          "Usuario que espera: cargando...",
                                        );
                                      }

                                      final usuario = userSnapshot.data!;
                                      final nombre =
                                          usuario["nombre"] ?? "Usuario";

                                      return Text(
                                        "Usuario que espera: $nombre",
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),

                                  Text("Estado: ${intercambio.estado}"),

                                  if (!soyOfertante &&
                                      intercambio.estado == "pendiente") ...[
                                    const SizedBox(height: 12),

                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                            ),
                                            onPressed: () async {
                                              await servicioService
                                                  .actualizarEstadoIntercambio(
                                                    intercambio.id,
                                                    "aceptado",
                                                  );
                                            },
                                            child: const Text("Aceptar"),
                                          ),
                                        ),

                                        const SizedBox(width: 10),

                                        Expanded(
                                          child: ElevatedButton(
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red,
                                            ),
                                            onPressed: () async {
                                              await servicioService
                                                  .actualizarEstadoIntercambio(
                                                    intercambio.id,
                                                    "rechazado",
                                                  );
                                            },
                                            child: const Text("Rechazar"),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],

                                  if (intercambio.estado == "aceptado") ...[
                                    const SizedBox(height: 12),

                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.blue,
                                      ),
                                      onPressed: yaConfirmado
                                          ? null
                                          : () async {
                                              final confirmado = await showDialog(
                                                context: context,
                                                builder: (context) => AlertDialog(
                                                  title: const Text(
                                                    "Confirmar servicio",
                                                  ),
                                                  content: const Text(
                                                    "¿Confirmas que has recibido el servicio?",
                                                  ),
                                                  actions: [
                                                    TextButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            false,
                                                          ),
                                                      child: const Text(
                                                        "Cancelar",
                                                      ),
                                                    ),
                                                    ElevatedButton(
                                                      onPressed: () =>
                                                          Navigator.pop(
                                                            context,
                                                            true,
                                                          ),
                                                      child: const Text(
                                                        "Confirmar",
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              );

                                              if (confirmado == true) {
                                                await servicioService
                                                    .confirmarFinalizacion(
                                                      intercambio.id,
                                                    );
                                              }
                                            },
                                      child: Text(
                                        yaConfirmado
                                            ? "Servicio ya recibido confirmado"
                                            : "He recibido el servicio",
                                      ),
                                    ),
                                  ],
                                  if (intercambio.estado == "finalizado") ...[
                                    const SizedBox(height: 12),

                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: yaValoro
                                            ? Colors.grey
                                            : Colors.orange,
                                      ),
                                      onPressed: yaValoro
                                          ? null
                                          : () {
                                              _mostrarDialogoValoracion(
                                                otroUsuarioId,
                                                intercambio.id,
                                              );
                                            },
                                      child: Text(
                                        yaValoro
                                            ? "Usuario ya valorado"
                                            : "Valorar usuario",
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),

      // Bottom bar
      bottomNavigationBar: AppBottomBar(currentIndex: _indexActual),
    );
  }

  // Widget para los botones de filtro
  Widget _botonFiltro({
    required String texto,
    required bool seleccionado,
    required VoidCallback onTap,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: seleccionado ? Colors.red : Colors.white,
        foregroundColor: seleccionado ? Colors.white : Colors.black,
        elevation: seleccionado ? 2 : 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      child: Text(texto),
    );
  }

  void _mostrarDialogoValoracion(
    String usuarioReceptorId,
    String intercambioId,
  ) {
    int puntuacion = 5;
    final comentarioController = TextEditingController();

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text("Valorar usuario"),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text("Puntuación"),

                  Slider(
                    value: puntuacion.toDouble(),
                    min: 1,
                    max: 5,
                    divisions: 4,
                    label: puntuacion.toString(),
                    onChanged: (value) {
                      setStateDialog(() {
                        puntuacion = value.toInt();
                      });
                    },
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: comentarioController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Comentario",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
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
                await servicioService.crearValoracion(
                  usuarioReceptorId: usuarioReceptorId,
                  puntuacion: puntuacion,
                  comentario: comentarioController.text.trim(),
                  intercambioId: intercambioId,
                );

                Navigator.pop(context);
              },
              child: const Text("Enviar"),
            ),
          ],
        );
      },
    );
  }
}
