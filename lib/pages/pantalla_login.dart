import 'package:flutter/material.dart';
import '../routes/rutas.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';

class PantallaLogin extends StatefulWidget {
  const PantallaLogin({super.key});

  @override
  State<PantallaLogin> createState() => _PantallaLoginState();
}

class _PantallaLoginState extends State<PantallaLogin> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.black),
                  onPressed: () => Navigator.pop(context),
                ),

                const SizedBox(height: 20),

                // Logo
                Center(
                  child: Image.asset(
                    'assets/logo.png',
                    width: 160,
                  ),
                ),

                const SizedBox(height: 40),

                // Campo para correo electrónico
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Correo electrónico',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Introduce tu correo electrónico';
                    }
                    if (!value.contains('@')) {
                      return 'Correo electrónico no válido';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 20),

                // Campo para contraseña
                TextFormField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'Contraseña',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Introduce la contraseña';
                    }
                    if (value.length < 6) {
                      return 'La contraseña debe tener al menos 6 caracteres';
                    }
                    return null;
                  },
                ),

                Align(
  alignment: Alignment.centerRight,
  child: GestureDetector(
    onTap: _isLoading ? null : _handleResetPassword,
    child: const Text(
      "¿Olvidaste tu contraseña?",
      style: TextStyle(
        color: Color(0xFFFF0000),
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),
    ),
  ),
),

                const SizedBox(height: 10),

                // Mensaje de error
                if (_errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade100,
                        border: Border.all(color: Colors.red),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: Colors.red,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ),

                const SizedBox(height: 10),

                // Botón iniciar sesión
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF0000),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isLoading ? null : _handleLogin,
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Iniciar sesión',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                ),

                const SizedBox(height: 15),

                // Enlace a registro
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "¿No tienes cuenta? ",
                        style: TextStyle(fontSize: 14),
                      ),
                      GestureDetector(
                        onTap: _isLoading
                            ? null
                            : () => Navigator.pushNamed(context, Rutas.registro),
                        child: Text(
                          "Registrarse",
                          style: TextStyle(
                            color: const Color(0xFFFF0000),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    final email = emailController.text.trim();
    final password = passwordController.text;

    // Login en Firebase Auth
    final credential = await _authService.login(
      email: email,
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-null',
        message: 'No se pudo iniciar sesión.',
      );
    }

    // Verificar que exista documento en Firestore
    final doc = await FirebaseFirestore.instance
        .collection('Usuarios')
        .doc(user.uid)
        .get();

    if (!doc.exists) {
      await FirebaseAuth.instance.signOut();
      throw FirebaseAuthException(
        code: 'profile-not-found',
      );
    }

    if (mounted) {
      Navigator.pushReplacementNamed(context, Rutas.busqueda);
    }

  } on FirebaseAuthException catch (e) {
    String mensaje;

    switch (e.code) {
      case 'invalid-credential':
        mensaje = 'Correo o contraseña incorrectos.';
        break;
      case 'user-not-found':
        mensaje = 'No existe un usuario con ese correo.';
        break;
      case 'wrong-password':
        mensaje = 'Contraseña incorrecta.';
        break;
      case 'invalid-email':
        mensaje = 'El correo no es válido.';
        break;
      case 'user-disabled':
        mensaje = 'Este usuario ha sido deshabilitado.';
        break;
      case 'email-not-verified':
        mensaje = 'Debes verificar tu correo antes de iniciar sesión. Revisa la dirección de correo para el enlace de verificación.';
         break;
      case 'profile-not-found':
        mensaje = 'Tu perfil no está completo. Contacta con soporte.';
        break;
      default:
        mensaje = 'Error al iniciar sesión. Inténtalo más tarde.';
    }

    if (mounted) {
      setState(() {
        _errorMessage = mensaje;
      });
    }

  } catch (_) {
    if (mounted) {
      setState(() {
        _errorMessage =
            'Ocurrió un error inesperado. Comprueba tu conexión.';
      });
    }
  } finally {
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }
}

Future<void> _handleResetPassword() async {
  final email = emailController.text.trim();

  if (email.isEmpty || !email.contains('@')) {
    setState(() {
      _errorMessage = 'Introduce un correo válido para recuperar la contraseña.';
    });
    return;
  }

  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

    setState(() {
      _errorMessage = 'Se ha enviado un correo para restablecer la contraseña.';
    });
  } catch (e) {
    setState(() {
      _errorMessage = 'Error al enviar el correo de recuperación.';
    });
  }
}

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}