import 'package:flutter/material.dart';
import '../models/chats.dart';
import '../models/mensaje.dart';
import '../services/auth_service.dart';
import '../services/chat_service.dart';

class PantallaChat extends StatefulWidget {
  final String chatId;

  const PantallaChat({super.key, required this.chatId});

  @override
  State<PantallaChat> createState() => _PantallaChatState();
}

class _PantallaChatState extends State<PantallaChat> {
  final ChatService _chatService = ChatService();
  final AuthService _authService = AuthService();

  final TextEditingController _mensajeController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Usuario no autenticado")),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[200],

      appBar: AppBar(
        title: const Text("Chat"),
      ),

      body: Column(
        children: [

          /// CABECERA (nombre del otro usuario)
          FutureBuilder<Chats?>(
            future: _chatService.getChatById(widget.chatId),
            builder: (context, chatSnapshot) {
              final chat = chatSnapshot.data;
              final otherUserId = chat?.participantes
                      .firstWhere((id) => id != user.uid, orElse: () => '')
                  ?? '';

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: Colors.white,
                child: Row(
                  children: [
                    const CircleAvatar(
                      backgroundColor: Colors.red,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FutureBuilder<Map<String, dynamic>?>(
                            future: otherUserId.isNotEmpty
                                ? _authService.getUserProfileByUid(otherUserId)
                                : Future.value(null),
                            builder: (context, userSnapshot) {
                              final nombre = userSnapshot.data?['nombre'] as String?;
                              final displayName = nombre?.isNotEmpty == true
                                  ? nombre
                                  : (otherUserId.isNotEmpty ? otherUserId : 'Usuario');

                              return Text(
                                chatSnapshot.connectionState == ConnectionState.waiting
                                    ? 'Cargando…'
                                    : 'Conversación con $displayName',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 4),
                          Text(
                            chatSnapshot.connectionState == ConnectionState.waiting
                                ? 'Cargando...'
                                : 'Envía un mensaje para comenzar',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          /// LISTA DE MENSAJES
          Expanded(
            child: StreamBuilder<List<Mensaje>>(
              stream: _chatService.getMensajes(widget.chatId),
              builder: (context, snapshot) {

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final mensajes = snapshot.data!;

                if (mensajes.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'No hay mensajes aún. Envía el primero para iniciar la conversación.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  );
                }

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.animateTo(
                      _scrollController.position.maxScrollExtent,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOut,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(12),
                  itemCount: mensajes.length,
                  itemBuilder: (context, index) {

                    final mensaje = mensajes[index];

                    final esMio =
                        mensaje.usuarioIdEmisor == user.uid;

                    return Align(
                      alignment: esMio
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: esMio
                              ? Colors.red[200]
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              mensaje.contenido,
                              style: const TextStyle(fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatTime(mensaje.fechaEnvio),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          /// INPUT MENSAJE
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 6,
            ),
            color: Colors.white,
            child: Row(
              children: [

                Expanded(
                  child: TextField(
                    controller: _mensajeController,
                    decoration: const InputDecoration(
                      hintText: "Escribe un mensaje...",
                      border: InputBorder.none,
                    ),
                  ),
                ),

                IconButton(
                  icon: const Icon(Icons.send, color: Colors.red),
                  onPressed: () async {

                    final texto = _mensajeController.text.trim();

                    if (texto.isEmpty) return;

                    await _chatService.enviarMensaje(
                      chatId: widget.chatId,
                      contenido: texto,
                      usuarioId: user.uid,
                    );

                    _mensajeController.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}