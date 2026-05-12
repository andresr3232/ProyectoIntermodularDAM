import 'package:flutter/material.dart';
import '../pages/pantalla_carga.dart';
import '../pages/pantalla_login.dart';
import '../pages/pantalla_registro.dart';
import '../pages/pantalla_registro_info_perfil.dart';
import '../pages/pantalla_principal_busqueda.dart';
import '../pages/pantalla_principal_encargos.dart';
import '../pages/pantalla_principal_mensajes.dart';
import '../pages/pantalla_chat.dart';
import '../pages/pantalla_principal_perfil.dart';
import '../pages/pantalla_promociones.dart';
import '../pages/pantalla_administracion_usuarios.dart';

class Rutas {
  static const String pantallaCarga = '/';
  static const String login = '/login';
  static const String registro = '/registro';
  static const String registroInfoPerfil = '/registroInfoPerfil';
  static const String busqueda = '/busqueda';
  static const String encargos = '/encargos';
  static const String mensajes = '/mensajes';
  static const String chat = '/chat';
  static const String perfil = '/perfil';
  static const String promociones = '/promociones';
  static const String administracionUsuarios = '/administracionUsuarios';
}

Route<dynamic> generarRutas(RouteSettings settings) {
  switch (settings.name) {

    case Rutas.pantallaCarga:
      return MaterialPageRoute(builder: (_) => PantallaCarga());

    case Rutas.login:
      return MaterialPageRoute(builder: (_) => PantallaLogin());

    case Rutas.registro:
      return MaterialPageRoute(builder: (_) => PantallaRegistro());

    case Rutas.registroInfoPerfil:
      return MaterialPageRoute(builder: (_) => PantallaRegistroInfoPerfil());

    case Rutas.busqueda:
      return MaterialPageRoute(builder: (_) => PantallaBusqueda());

    case Rutas.encargos:
      return MaterialPageRoute(builder: (_) => PantallaEncargos());

    case Rutas.mensajes:
      return MaterialPageRoute(builder: (_) => PantallaMensajes());

    case Rutas.chat:
      final chatId = settings.arguments as String;
      return MaterialPageRoute(
        builder: (_) => PantallaChat(chatId: chatId),
    );

    case Rutas.perfil:
      final usuarioId = settings.arguments as String?;
      return MaterialPageRoute(
        builder: (_) => PantallaPerfil(usuarioId: usuarioId),
      );
    
    case Rutas.promociones:
      return MaterialPageRoute(builder: (_) => PantallaPromociones());

    case Rutas.administracionUsuarios:
      return MaterialPageRoute(builder: (_) => PantallaAdministracionUsuarios());

    default:
      return MaterialPageRoute(builder: (_) => PantallaCarga());
  }
}