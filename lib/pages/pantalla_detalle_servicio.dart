import 'package:flutter/material.dart';
import '../models/servicio.dart';
import '../pages/pantalla_chat.dart';
import '../services/chat_service.dart';
import '../services/servicio_service.dart';
import '../services/auth_service.dart';

class PantallaDetalleServicio extends StatelessWidget {
  final Servicio servicio;

  const PantallaDetalleServicio({super.key, required this.servicio});

  @override
  Widget build(BuildContext context) {
    final servicioService = ServicioService();
    final authService = AuthService();
    final chatService = ChatService();

    return Scaffold(
      appBar: AppBar(title: Text(servicio.titulo)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              servicio.titulo,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(servicio.descripcion),
            const SizedBox(height: 20),

            Row(
              children: [
                const Icon(Icons.category, size: 18),
                const SizedBox(width: 6),
                Text(servicio.categoria),
              ],
            ),

            const Spacer(),

            // BOTÓN CONTACTAR
            SizedBox(
  width: double.infinity,
  child: FutureBuilder<Map<String, dynamic>?>(
    future: servicioService.getUsuarioById(servicio.usuarioId),
    builder: (context, snapshotUsuario) {
      final usuarioNombre = (snapshotUsuario.hasData && snapshotUsuario.data != null)
          ? (snapshotUsuario.data!['nombreUsuario'] ?? snapshotUsuario.data!['nombre'] ?? 'Usuario')
          : 'Usuario';

      return ElevatedButton.icon(
        icon: const Icon(Icons.chat),
        label: Text('Contactar con $usuarioNombre'),
        onPressed: () async {
          final user = authService.currentUser;
          if (user == null) return;
          if (user.uid == servicio.usuarioId) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("No puedes contactarte contigo mismo")),
            );
            return;
          }

          final chatId = await chatService.crearChatSiNoExiste(user.uid, servicio.usuarioId);
          Navigator.push(context, MaterialPageRoute(builder: (_) => PantallaChat(chatId: chatId)));
        },
      );
    },
  ),
),

            const SizedBox(height: 10),

            // BOTÓN SOLICITAR
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.assignment),
                label: const Text("Solicitar servicio"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[200],
                ),
                onPressed: () async {
                  final user = authService.currentUser;
                  if (user == null) return;

                  if (user.uid == servicio.usuarioId) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No puedes solicitar tu propio servicio"),
                      ),
                    );
                    return;
                  }

                  // Obtener servicios activos del usuario actual
                  final misServicios = await servicioService
                      .getServiciosUsuarioByDocId(user.uid)
                      .first;

                  final serviciosActivos = misServicios
                      .where((s) => s.activo)
                      .toList();

                  if (serviciosActivos.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Debes tener al menos un servicio activo para intercambiar",
                        ),
                      ),
                    );
                    return;
                  }

                  Servicio? servicioSeleccionado;

                  await showDialog(
                    context: context,
                    builder: (_) {
                      return AlertDialog(
                        title: const Text(
                          "Selecciona tu servicio para intercambiar",
                        ),
                        content: DropdownButtonFormField<Servicio>(
                          items: serviciosActivos
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s.titulo),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            servicioSeleccionado = value;
                          },
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Cancelar"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              if (servicioSeleccionado == null) return;

                              try {
                                await servicioService.crearIntercambio(
                                  usuarioIdOfertante: user.uid,
                                  usuarioIdDemandante: servicio.usuarioId,
                                  servicioIdOfertado: servicioSeleccionado!.id,
                                  servicioIdDemandado: servicio.id,
                                );

                                // Crear chat entre ambos usuarios si aún no existe
                                await chatService.crearChatSiNoExiste(
                                  user.uid,
                                  servicio.usuarioId,
                                );

                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Solicitud enviada correctamente"),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Error al enviar solicitud"),
                                  ),
                                );
                              }

                              Navigator.pop(context);

                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Solicitud de intercambio enviada",
                                  ),
                                ),
                              );

                              Navigator.pop(context);
                            },
                            child: const Text("Enviar"),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
