import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'routes/rutas.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: const FirebaseOptions(
      apiKey: 'AIzaSyBSDn_KnRlMD18ovBvai1z3wrb8tpfeeqU',
      appId: '1:218533471313:web:526bf6522a7b6100680470',
      messagingSenderId: '218533471313',
      projectId: 'proyecto-intermodular-b9aa0',
      storageBucket: 'proyecto-intermodular-b9aa0.firebasestorage.app',
    ),
  );
  runApp(TradeSkillsApp());
}

class TradeSkillsApp extends StatelessWidget {
  const TradeSkillsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: Rutas.pantallaCarga,
      onGenerateRoute: generarRutas,
    );
  }
}