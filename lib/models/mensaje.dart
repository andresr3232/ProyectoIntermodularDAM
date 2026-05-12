import 'package:cloud_firestore/cloud_firestore.dart';

class Mensaje {
  final String id;
  final String contenido;
  final DateTime fechaEnvio;
  final String usuarioIdEmisor;

  Mensaje({
    required this.id,
    required this.contenido,
    required this.fechaEnvio,
    required this.usuarioIdEmisor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'contenido': contenido,
      'fechaEnvio': Timestamp.fromDate(fechaEnvio),
      'usuarioIdEmisor': usuarioIdEmisor,
    };
  }

  factory Mensaje.fromMap(Map<String, dynamic> map) {
    return Mensaje(
      id: map['id'] as String,
      contenido: map['contenido'] as String,
      fechaEnvio: (map['fechaEnvio'] as Timestamp).toDate(),
      usuarioIdEmisor: map['usuarioIdEmisor'] as String,
    );
  }
}