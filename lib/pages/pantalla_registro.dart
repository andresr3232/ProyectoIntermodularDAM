import 'package:flutter/material.dart';
import '../routes/rutas.dart';
import '../models/datos_registro_preliminar.dart';
import '../models/provincias.dart';

class PantallaRegistro extends StatefulWidget {
  const PantallaRegistro({super.key});

  @override
  State<PantallaRegistro> createState() => _PantallaRegistroState();
}

class _PantallaRegistroState extends State<PantallaRegistro> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController usuarioController = TextEditingController();
  final TextEditingController primerApellidoController = TextEditingController();
  final TextEditingController segundoApellidoController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmarPasswordController = TextEditingController();

  String? provinciaSeleccionada;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),

                const SizedBox(height: 10),

                // Logo
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    width: 130,
                    height: 130,
                  ),
                ),

                const SizedBox(height: 30),

                // Nombre
                TextFormField(
                  controller: nombreController,
                  decoration: _inputDecoration('Nombre'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Introduce tu nombre';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Primer apellido
                TextFormField(
                  controller: primerApellidoController,
                  decoration: _inputDecoration('Primer apellido'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Introduce el primer apellido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Segundo apellido (opcional)
                TextFormField(
                  controller: segundoApellidoController,
                  decoration: _inputDecoration('Segundo apellido'),
                ),

                const SizedBox(height: 20),

                // Nombre de usuario
                TextFormField(
                  controller: usuarioController,
                  decoration: _inputDecoration('Nombre de usuario'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Introduce un nombre de usuario';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Ubicación
                DropdownButtonFormField<String>(
                  initialValue: provinciaSeleccionada,
                  decoration: _inputDecoration('Provincia'),
                  items: Provincias.provincias
                      .map(
                        (provincia) => DropdownMenuItem(
                          value: provincia,
                          child: Text(provincia),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      provinciaSeleccionada = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Selecciona una provincia';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Email
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: _inputDecoration('Email'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Introduce el email';
                    }
                    if (!value.contains('@')) {
                      return 'Email no válido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Contraseña
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: _inputDecoration('Contraseña'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Introduce la contraseña';
                    }
                    if (value.length < 6) {
                      return 'Mínimo 6 caracteres';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Confirmar contraseña
                TextFormField(
                  controller: confirmarPasswordController,
                  obscureText: true,
                  decoration: _inputDecoration('Confirmar contraseña'),
                  validator: (value) {
                    if (value != passwordController.text) {
                      return 'Las contraseñas no coinciden';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 15),

                // Texto login
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("¿Tiene una cuenta?", style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, Rutas.login);
                      },
                      child: const Text(
                        "Iniciar sesión",
                        style: TextStyle(color: Color(0xFFFF0000)),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Botón registrarse
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        // Crear objeto con los datos del registro
                        final datosRegistro = DatosRegistroPreliminar(
                          nombre: nombreController.text,
                          apellido1: primerApellidoController.text,
                          apellido2: segundoApellidoController.text.isEmpty 
                              ? null 
                              : segundoApellidoController.text,
                          nombreUsuario: usuarioController.text,
                          email: emailController.text,
                          password: passwordController.text,
                          ubicacion: provinciaSeleccionada!,
                        );
                        
                        // Navegar pasando los datos
                        Navigator.pushNamed(
                          context,
                          Rutas.registroInfoPerfil,
                          arguments: datosRegistro,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0000),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Registrarse",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Widget para decorar
  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Color(0xFF666666)),
      filled: true,
      fillColor: const Color(0xFFFFFFFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF9C9C9C)),
      ),
    );
  }

@override
void dispose() {
  nombreController.dispose();
  usuarioController.dispose();
  primerApellidoController.dispose();
  segundoApellidoController.dispose();
  emailController.dispose();
  passwordController.dispose();
  confirmarPasswordController.dispose();
  super.dispose();
}
}