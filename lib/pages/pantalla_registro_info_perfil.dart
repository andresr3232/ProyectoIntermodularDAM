import 'package:flutter/material.dart';
import '../routes/rutas.dart';
import '../models/categorias.dart';
import '../models/usuario.dart';
import '../models/datos_registro_preliminar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class PantallaRegistroInfoPerfil extends StatefulWidget {
  final DatosRegistroPreliminar datosRegistro;

  const PantallaRegistroInfoPerfil({
    Key? key,
    required this.datosRegistro,
  }) : super(key: key);

  @override
  State<PantallaRegistroInfoPerfil> createState() =>
      _PantallaRegistroInfoPerfilState();
}

class _PantallaRegistroInfoPerfilState
    extends State<PantallaRegistroInfoPerfil> {
  final _formKey = GlobalKey<FormState>();

  late DatosRegistroPreliminar datosRegistro;
  final TextEditingController descripcionController = TextEditingController();

  List<String> serviciosOfrece = [];
  List<String> serviciosBusca = [];

  bool _cargando = false; // Para mostrar loading mientras se guarda
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    datosRegistro = widget.datosRegistro;
  }

  // Diálogo para seleccionar múltiples servicios
  void _mostrarDialogoServicios(
    String tipo, // "ofrece" o "busca"
    List<String> serviciosActuales,
  ) {
    final List<String> serviciosTemp = List.from(serviciosActuales);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(tipo == 'ofrece'
                  ? 'Servicios que ofreces'
                  : 'Servicios que buscas'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: Categorias.lista
                      .map((servicio) {
                        final isChecked = serviciosTemp.contains(servicio);
                        return CheckboxListTile(
                          title: Text(servicio),
                          value: isChecked,
                          onChanged: (bool? value) {
                            setStateDialog(() {
                              if (value == true) {
                                serviciosTemp.add(servicio);
                              } else {
                                serviciosTemp.remove(servicio);
                              }
                            });
                          },
                        );
                      })
                      .toList(),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (tipo == 'ofrece') {
                        serviciosOfrece = serviciosTemp;
                      } else {
                        serviciosBusca = serviciosTemp;
                      }
                    });
                    Navigator.pop(context);
                  },
                  child: const Text('Confirmar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

// Crea y guarda el usuario completo en Firebase
Future<void> _crearYGuardarUsuario() async {
  if (!_formKey.currentState!.validate()) return;

  if (serviciosOfrece.isEmpty || serviciosBusca.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debes seleccionar servicios que ofreces y que buscas'),
      ),
    );
    return;
  }

  setState(() => _cargando = true);

  try {
    final credential = await _authService.register(
      email: datosRegistro.email,
      password: datosRegistro.password,
    );

    final uid = credential.user?.uid;
    if (uid == null) throw 'No se pudo obtener el uid del usuario.';

    final nuevoUsuario = Usuario(
      id: uid,
      nombreUsuario: datosRegistro.nombreUsuario,
      nombre: datosRegistro.nombre,
      apellido1: datosRegistro.apellido1,
      apellido2: datosRegistro.apellido2,
      email: datosRegistro.email,
      ubicacion: datosRegistro.ubicacion,
      fechaRegistro: DateTime.now(),
      rol: 'usuario',
      descripcion: descripcionController.text.trim(),
      fotoPerfil: null,
      mediaValoraciones: 0.0,
      serviciosOfrece: serviciosOfrece,
      serviciosBusca: serviciosBusca,
    );

    // Usamos toMap() y sobreescribimos solo lo que necesita ajuste
    final userMap = nuevoUsuario.toMap();
    userMap['fechaRegistro'] = FieldValue.serverTimestamp();

    await _firestore.collection('Usuarios').doc(uid).set(userMap);

    try {
      await credential.user?.sendEmailVerification();
    } catch (_) {}

    if (mounted) {
      Navigator.pushReplacementNamed(context, Rutas.busqueda);
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar usuario: $e')),
      );
    }
  } finally {
    if (mounted) {
      setState(() => _cargando = false);
    }
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 10),

              // Logo
              Image.asset('assets/logo.png', height: 100),

              const SizedBox(height: 20),

              // Título
              const Text(
                'Información para su perfil',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 30),

              // Descripción (Obligatorio escribir 10 caracteres o más)
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Descripción',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),

              const SizedBox(height: 8),

              TextFormField(
                controller: descripcionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Cuéntanos brevemente qué haces o qué ofreces',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Introduce una descripción';
                  }
                  if (value.length < 10) {
                    return 'La descripción es demasiado corta';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              // Servicios que ofrece
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Servicios que ofreces',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                ),
                onPressed: () => _mostrarDialogoServicios('ofrece', serviciosOfrece),
                icon: const Icon(Icons.add),
                label: Text(serviciosOfrece.isEmpty
                    ? 'Seleccionar servicios'
                    : '${serviciosOfrece.length} seleccionado(s)'),
              ),
              if (serviciosOfrece.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    children: serviciosOfrece
                        .map(
                          (s) => Chip(
                            label: Text(s),
                            onDeleted: () {
                              setState(() {
                                serviciosOfrece.remove(s);
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),

              const SizedBox(height: 24),

              // Servicios que busca
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Servicios que buscas',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              const SizedBox(height: 8),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey[300],
                  foregroundColor: Colors.black,
                ),
                onPressed: () => _mostrarDialogoServicios('busca', serviciosBusca),
                icon: const Icon(Icons.add),
                label: Text(serviciosBusca.isEmpty
                    ? 'Seleccionar servicios'
                    : '${serviciosBusca.length} seleccionado(s)'),
              ),
              if (serviciosBusca.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 8,
                    children: serviciosBusca
                        .map(
                          (s) => Chip(
                            label: Text(s),
                            onDeleted: () {
                              setState(() {
                                serviciosBusca.remove(s);
                              });
                            },
                          ),
                        )
                        .toList(),
                  ),
                ),

              const SizedBox(height: 24),

              // Nota: no se usa foto de perfil en este flujo

              const SizedBox(height: 30),

              // Continuar
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _cargando ? null : _crearYGuardarUsuario,
                  child: _cargando
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Continuar',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                ),
              ),

              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
