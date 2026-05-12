import 'package:flutter/material.dart';
import '../widgets/bottom_bar.dart';
import '../services/chat_service.dart';
import '../services/auth_service.dart';
import '../models/chats.dart';
import 'pantalla_chat.dart';

class PantallaMensajes extends StatefulWidget {
  const PantallaMensajes({super.key});

  @override
  State<PantallaMensajes> createState() => _PantallaMensajesState();
}

class _PantallaMensajesState extends State<PantallaMensajes> {
  int _indexActual = 2;

  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Usuario no autenticado")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],

      // App bar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            Image.asset('assets/logo.png', height: 40),
            const SizedBox(width: 12),
            const Text(
              'Mensajes',
              style: TextStyle(color: Colors.black),
            ),
          ],
        ),
      ),

      // Cuerpo
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Buscador
            TextField(
              decoration: InputDecoration(
                hintText: 'Buscar conversaciones',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Lista de conversaciones
            Expanded(
              child: StreamBuilder<List<Chats>>(
                stream: _chatService.getChatsUsuario(user.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Error cargando conversaciones:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Text("No tienes conversaciones"),
                    );
                  }

                  final chats = snapshot.data!;

                  return ListView.builder(
                    itemCount: chats.length,
                    itemBuilder: (context, index) {
                      final chat = chats[index];

                      final otroUsuarioId = chat.participantes
                          .firstWhere((id) => id != user.uid);

                      final hora = TimeOfDay.fromDateTime(
                        chat.ultimaActualizacion,
                      ).format(context);

                      return FutureBuilder<Map<String, dynamic>?>(
                        future: _authService.getUserProfileByUid(otroUsuarioId),
                        builder: (context, userSnapshot) {
                          final nombre =
                              userSnapshot.data?['nombre'] ?? 'Usuario';

                          return _itemConversacion(
                            nombre: nombre,
                            mensaje: "Abrir conversación",
                            hora: hora,
                            noLeido: false,
                            chatId: chat.id,
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
      bottomNavigationBar: AppBottomBar(
        currentIndex: _indexActual,
      ),
    );
  }

  Widget _itemConversacion({
    required String nombre,
    required String mensaje,
    required String hora,
    required bool noLeido,
    required String chatId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          elevation: 1,
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PantallaChat(chatId: chatId),
            ),
          );
        },
        child: Row(
          children: [
            const CircleAvatar(
              radius: 26,
              backgroundColor: Colors.red,
              child: Icon(Icons.person, color: Colors.white),
            ),

            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    mensaje,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  hora,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 6),
                if (noLeido)
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}