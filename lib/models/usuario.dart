import 'package:cloud_firestore/cloud_firestore.dart';

class Usuario {
  final String id;
  final String nombreUsuario;
  final String nombre;
  final String apellido1;
  final String? apellido2;
  final String email;
  final String ubicacion;
  final DateTime fechaRegistro;
  final String rol;
  final String descripcion;
  final String? fotoPerfil; // URL de Firebase Storage (mejora a futuro)
  final double mediaValoraciones;
  final int totalValoraciones;
  final List<String> serviciosOfrece;
  final List<String> serviciosBusca;

  Usuario({
    required this.id,
    required this.nombreUsuario,
    required this.nombre,
    required this.apellido1,
    this.apellido2,
    required this.email,
    required this.ubicacion,
    required this.fechaRegistro,
    required this.rol,
    required this.descripcion,
    this.fotoPerfil,
    this.mediaValoraciones = 0.0,
    this.totalValoraciones = 0,
    this.serviciosOfrece = const [],
    this.serviciosBusca = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombreUsuario': nombreUsuario,
      'nombre': nombre,
      'apellido1': apellido1,
      'apellido2': apellido2,
      'email': email,
      'ubicacion': ubicacion,
      'fechaRegistro': Timestamp.fromDate(fechaRegistro),
      'rol': rol,
      'descripcion': descripcion,
      'fotoPerfil': fotoPerfil,
      'mediaValoraciones': mediaValoraciones,
      'totalValoraciones': totalValoraciones,
      'serviciosOfrece': serviciosOfrece,
      'serviciosBusca': serviciosBusca,
    };
  }

  factory Usuario.fromMap(Map<String, dynamic> map) {
    String safeString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }

    DateTime safeFecha(dynamic value) {
      if (value == null) return DateTime.now();
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return DateTime.now();
    }

    return Usuario(
      id: safeString(map['id']),
      nombreUsuario: safeString(map['nombreUsuario']),
      nombre: safeString(map['nombre']),
      apellido1: safeString(map['apellido1']),
      apellido2: map['apellido2']?.toString(),
      email: safeString(map['email']),
      ubicacion: safeString(map['ubicacion']),
      fechaRegistro: safeFecha(map['fechaRegistro']),
      rol: safeString(map['rol']).isNotEmpty ? safeString(map['rol']) : 'usuario',
      descripcion: safeString(map['descripcion']),
      fotoPerfil: map['fotoPerfil']?.toString(),
      mediaValoraciones: (map['mediaValoraciones'] as num?)?.toDouble() ?? 0.0,
      totalValoraciones: (map['totalValoraciones'] as num?)?.toInt() ?? 0,
      serviciosOfrece: List<String>.from(map['serviciosOfrece'] as List? ?? []),
      serviciosBusca: List<String>.from(map['serviciosBusca'] as List? ?? []),
    );
  }
}

