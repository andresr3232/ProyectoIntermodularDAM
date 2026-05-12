import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/categorias.dart';
import '../widgets/bottom_bar.dart';
import 'pantalla_principal_perfil.dart';
import 'pantalla_resultados_busqueda.dart';

class PantallaBusqueda extends StatefulWidget {
  const PantallaBusqueda({super.key});

  @override
  State<PantallaBusqueda> createState() => _PantallaBusquedaState();
}

class _PantallaBusquedaState extends State<PantallaBusqueda> {
  int _indexActual = 0; // Búsqueda
  int _tipoBusqueda = 0;

  final TextEditingController _searchController = TextEditingController();
  List<String> _categoriasFiltradas = [];
  List<Map<String, dynamic>> _usuariosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _categoriasFiltradas = Categorias.lista;
  }

  void _filtrarCategorias(String texto) {
    setState(() {
      if (texto.isEmpty) {
        _categoriasFiltradas = Categorias.lista;
      } else {
        _categoriasFiltradas = Categorias.lista
            .where(
              (categoria) =>
                  categoria.toLowerCase().contains(texto.toLowerCase()),
            )
            .toList();
      }
    });
  }

  Future<void> _buscarUsuarios(String texto) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('Usuarios')
        .get();

    final usuarios = snapshot.docs
        .map((doc) {
          final data = doc.data();

          return {...data, 'uid': doc.id};
        })
        .where((user) {
          final nombreUsuario = (user['nombreUsuario'] ?? '').toString();
          return nombreUsuario.toLowerCase().contains(texto.toLowerCase());
        })
        .toList();

    setState(() {
      _usuariosFiltrados = usuarios;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[400],

      // App bar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            const SizedBox(width: 12),
            Image.asset('assets/logo.png', height: 50),
            const SizedBox(width: 12),
            const Text('Búsqueda', style: TextStyle(color: Colors.black)),
          ],
        ),
      ),

      // Cuerpo
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Buscador
            ToggleButtons(
  isSelected: [_tipoBusqueda == 0, _tipoBusqueda == 1],
  onPressed: (index) {
    setState(() {
      _tipoBusqueda = index;
    });
  },
  borderRadius: BorderRadius.circular(12),
  selectedColor: Colors.white,
  fillColor: Colors.red,
  color: Colors.black54,
  constraints: const BoxConstraints(minHeight: 40, minWidth: 100),
  children: const [
    Text("Servicios"),
    Text("Usuarios"),
  ],
),
const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (texto) {
                if (_tipoBusqueda == 0) {
                  _filtrarCategorias(texto);
                } else {
                  _buscarUsuarios(texto);
                }
              },
              decoration: InputDecoration(
                hintText: _tipoBusqueda == 0
                    ? 'Buscar servicios o habilidades'
                    : 'Buscar usuarios',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),

            const SizedBox(height: 20),

            Text(
              _tipoBusqueda == 0 ? "Categorías" : "Usuarios",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: _tipoBusqueda == 0 ? _listaCategorias() : _listaUsuarios(),
            ),
          ],
        ),
      ),

      // Bottom bar
      bottomNavigationBar: AppBottomBar(currentIndex: _indexActual),
    );
  }

  // Widget para cada categoría
  Widget _categoriaVertical(String nombre) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PantallaResultadosBusqueda(categoria: nombre),
            ),
          );
        },
        child: Row(
          children: [
            const Icon(Icons.work_outline, color: Colors.red),
            const SizedBox(width: 12),
            Text(nombre),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _listaCategorias() {
    if (_categoriasFiltradas.isEmpty) {
      return const Center(
        child: Text(
          'No se encontraron categorías',
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return ListView.builder(
      itemCount: _categoriasFiltradas.length,
      itemBuilder: (context, index) {
        return _categoriaVertical(_categoriasFiltradas[index]);
      },
    );
  }

  Widget _listaUsuarios() {
    if (_usuariosFiltrados.isEmpty) {
      return const Center(child: Text("No se encontraron usuarios"));
    }

    return ListView.builder(
      itemCount: _usuariosFiltrados.length,
      itemBuilder: (context, index) {
        final user = _usuariosFiltrados[index];

        final nombre = user['nombre'] ?? '';
        final nombreUsuario = user['nombreUsuario'] ?? 'usuario';
        final uid = user['uid'];

        return ListTile(
          leading: CircleAvatar(
            child: Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : "?"),
          ),
          title: Text('@$nombreUsuario'),
          subtitle: Text(nombre),
          onTap: () {
            if (uid == null) return;

            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => PantallaPerfil(usuarioId: uid)),
            );
          },
        );
      },
    );
  }
}
