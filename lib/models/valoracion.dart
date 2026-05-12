import 'package:cloud_firestore/cloud_firestore.dart';

class Valoracion {
  final String id;
  final int puntuacion;
  final String? comentario;
  final DateTime fecha;
  final String usuarioIdEmisor;
  final String usuarioIdReceptor;
  final String intercambioId;

  Valoracion({
    required this.id,
    required this.puntuacion,
    this.comentario,
    required this.fecha,
    required this.usuarioIdEmisor,
    required this.usuarioIdReceptor,
    required this.intercambioId,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'puntuacion': puntuacion,
      'comentario': comentario,
      'fecha': Timestamp.fromDate(fecha),
      'usuarioIdEmisor': usuarioIdEmisor,
      'usuarioIdReceptor': usuarioIdReceptor,
      'intercambioId': intercambioId,
    };
  }

  factory Valoracion.fromMap(Map<String, dynamic> map) {
    return Valoracion(
      id: map['id'],
      puntuacion: map['puntuacion'],
      comentario: map['comentario'],
      fecha: (map['fecha'] as Timestamp).toDate(),
      usuarioIdEmisor: map['usuarioIdEmisor'],
      usuarioIdReceptor: map['usuarioIdReceptor'],
      intercambioId: map['intercambioId'],
    );
  }
}