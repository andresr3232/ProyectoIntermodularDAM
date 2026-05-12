import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../routes/rutas.dart';

class PantallaCarga extends StatefulWidget {
  @override
  _PantallaCargaState createState() => _PantallaCargaState();
}

class _PantallaCargaState extends State<PantallaCarga> {
  bool mostrarBotones = false;

  @override
  void initState() {
    super.initState();

    // Espera 3 segundos antes de mostrar los botones
    Future.delayed(Duration(seconds: 3), () async {
  final user = FirebaseAuth.instance.currentUser;
  if (user != null) {
    Navigator.pushReplacementNamed(context, Rutas.busqueda);
  } else {
    setState(() => mostrarBotones = true);
  }
});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // Logo
            Image.asset(
              'assets/logo.png',
              width: 250,
            ),

            SizedBox(height: 40),

            // Barra de carga
            if (!mostrarBotones)
              SizedBox(
                width: 180,
                child: LinearProgressIndicator(
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ),

            SizedBox(height: 40),

            // Mostrar botones
            if (mostrarBotones) ...[

              // Iniciar sesión
              SizedBox(
                width: 220,
                height: 45,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, Rutas.login);
                  },
                  child: Text(
                    "Iniciar sesión",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ),

              SizedBox(height: 12),

              // Registrarse
              SizedBox(
                width: 220,
                height: 45,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.red, width: 2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, Rutas.registro);
                  },
                  child: Text(
                    "Registrarse",
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}