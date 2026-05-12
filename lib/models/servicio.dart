import 'package:cloud_firestore/cloud_firestore.dart';

class Servicio {
  final String id;
  final String titulo;
  final String descripcion;
  final String categoria;
  final String usuarioId;
  final DateTime fechaPublicacion;
  final bool activo;

  Servicio({
    required this.id,
    required this.titulo,
    required this.descripcion,
    required this.categoria,
    required this.usuarioId,
    required this.fechaPublicacion,
    required this.activo,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'descripcion': descripcion,
      'categoria': categoria,
      'usuarioId': usuarioId,
      'fechaPublicacion': Timestamp.fromDate(fechaPublicacion),
      'activo': activo,
    };
  }

  factory Servicio.fromMap(Map<String, dynamic> map) {
  return Servicio(
    id: map['id'] as String,
    titulo: map['titulo'] as String,
    descripcion: map['descripcion'] as String,
    categoria: map['categoria'] as String,
    usuarioId: map['usuarioId'] as String,
    fechaPublicacion: map['fechaPublicacion'] is Timestamp
        ? (map['fechaPublicacion'] as Timestamp).toDate()
        : DateTime.parse(map['fechaPublicacion'] as String),
    activo: map['activo'] as bool,
  );
}
}