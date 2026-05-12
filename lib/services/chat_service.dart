import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/chats.dart';
import '../models/mensaje.dart';

class ChatService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Obtener chats del usuario
  Stream<List<Chats>> getChatsUsuario(String uid) {
    return _db
        .collection('Chats')
        .where('participantes', arrayContains: uid)
        .orderBy('ultimaActualizacion', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return Chats.fromMap(data);
            }).toList());
  }

  /// Obtener mensajes de un chat
  Stream<List<Mensaje>> getMensajes(String chatId) {
    return _db
        .collection('Chats')
        .doc(chatId)
        .collection('Mensajes')
        .orderBy('fechaEnvio')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return Mensaje.fromMap(data);
            }).toList());
  }

  /// Enviar mensaje
  Future<void> enviarMensaje({
    required String chatId,
    required String contenido,
    required String usuarioId,
  }) async {
    final mensajeRef = _db
        .collection('Chats')
        .doc(chatId)
        .collection('Mensajes')
        .doc();

    final mensaje = Mensaje(
      id: mensajeRef.id,
      contenido: contenido,
      usuarioIdEmisor: usuarioId,
      fechaEnvio: DateTime.now(),
    );

    await mensajeRef.set(mensaje.toMap());

    await _db.collection('Chats').doc(chatId).update({
      'ultimaActualizacion': Timestamp.now(),
    });
  }

  /// Crear chat si no existe entre dos usuarios
  Future<String> crearChatSiNoExiste(
    String usuarioA,
    String usuarioB,
  ) async {
    final query = await _db
        .collection('Chats')
        .where('participantes', arrayContains: usuarioA)
        .get();

    for (var doc in query.docs) {
      final participantes = List<String>.from(doc['participantes']);
      if (participantes.contains(usuarioB)) {
        return doc.id;
      }
    }

    final chatRef = _db.collection('Chats').doc();

    await chatRef.set({
      'participantes': [usuarioA, usuarioB],
      'ultimaActualizacion': Timestamp.now(),
    });

    return chatRef.id;
  }

  /// Obtener un chat por su id
  Future<Chats?> getChatById(String chatId) async {
    final doc = await _db.collection('Chats').doc(chatId).get();
    if (!doc.exists) return null;

    final data = doc.data();
    if (data == null) return null;

    data['id'] = doc.id;
    return Chats.fromMap(data);
  }
}