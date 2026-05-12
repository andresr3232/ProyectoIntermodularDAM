import 'package:cloud_firestore/cloud_firestore.dart';

class Intercambio {
  final String id;
  final String estado;
  final DateTime fechaSolicitud;
  final DateTime? fechaAceptacion;
  final String usuarioIdOfertante;
  final String usuarioIdDemandante;
  final String servicioIdOfertado;
  final String servicioIdDemandado;
  final bool ofertanteConfirmo;
  final bool demandanteConfirmo;
  final bool ofertanteValoro;
  final bool demandanteValoro;

  Intercambio({
    required this.id,
    required this.estado,
    required this.fechaSolicitud,
    this.fechaAceptacion,
    required this.usuarioIdOfertante,
    required this.usuarioIdDemandante,
    required this.servicioIdOfertado,
    required this.servicioIdDemandado,
    this.ofertanteConfirmo = false,
    this.demandanteConfirmo = false,
    this.ofertanteValoro = false,
    this.demandanteValoro = false,
  });

  Map<String, dynamic> toMap() {
  return {
    'id': id,
    'estado': estado,
    'fechaSolicitud': Timestamp.fromDate(fechaSolicitud),
    'fechaAceptacion': fechaAceptacion != null
        ? Timestamp.fromDate(fechaAceptacion!)
        : null,
    'usuarioIdOfertante': usuarioIdOfertante,
    'usuarioIdDemandante': usuarioIdDemandante,
    'servicioIdOfertado': servicioIdOfertado,
    'servicioIdDemandado': servicioIdDemandado,
    'ofertanteConfirmo': ofertanteConfirmo,
    'demandanteConfirmo': demandanteConfirmo,
    'ofertanteValoro': ofertanteValoro,
    'demandanteValoro': demandanteValoro,
  };
}

  factory Intercambio.fromMap(Map<String, dynamic> map) {
  return Intercambio(
    id: map['id'] as String,
    estado: map['estado'] as String,
    fechaSolicitud: (map['fechaSolicitud'] as Timestamp).toDate(),
    fechaAceptacion: map['fechaAceptacion'] != null
        ? (map['fechaAceptacion'] as Timestamp).toDate()
        : null,
    usuarioIdOfertante: map['usuarioIdOfertante'] as String,
    usuarioIdDemandante: map['usuarioIdDemandante'] as String,
    servicioIdOfertado: map['servicioIdOfertado'] as String,
    servicioIdDemandado: map['servicioIdDemandado'] as String,
    ofertanteConfirmo: map['ofertanteConfirmo'] as bool? ?? false,
    demandanteConfirmo: map['demandanteConfirmo'] as bool? ?? false,
    ofertanteValoro: map['ofertanteValoro'] as bool? ?? false,
    demandanteValoro: map['demandanteValoro'] as bool? ?? false,
  );
}
}