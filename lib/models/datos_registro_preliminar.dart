/// Clase para pasar datos del registro inicial a la pantalla de información de perfil
class DatosRegistroPreliminar {
  final String nombre;
  final String apellido1;
  final String? apellido2;
  final String nombreUsuario;
  final String email;
  final String password;
  final String ubicacion;

  DatosRegistroPreliminar({
    required this.nombre,
    required this.apellido1,
    this.apellido2,
    required this.nombreUsuario,
    required this.email,
    required this.password,
    required this.ubicacion,
  });
}
