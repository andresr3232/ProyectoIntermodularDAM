import 'package:cloud_firestore/cloud_firestore.dart';

class Promocion {
  final String id;
  final double cantidadPagado;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String usuarioIdEmisor;

  Promocion({
    required this.id,
    required this.cantidadPagado,
    required this.fechaInicio,
    required this.fechaFin,
    required this.usuarioIdEmisor,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cantidadPagado': cantidadPagado,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'usuarioIdEmisor': usuarioIdEmisor,
    };
  }

  factory Promocion.fromMap(Map<String, dynamic> map) {
    return Promocion(
      id: map['id'] as String,
      cantidadPagado: map['cantidadPagado'] as double,
      fechaInicio: (map['fechaInicio'] as Timestamp).toDate(),
      fechaFin: (map['fechaFin'] as Timestamp).toDate(),
      usuarioIdEmisor: map['usuarioIdEmisor'] as String,
    );
  }
}